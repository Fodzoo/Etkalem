
require('dotenv').config();

const express = require('express');
const cors = require('cors');
const path = require('path');

const { initializeApp, cert } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');
const { getDatabase } = require('firebase-admin/database');
const { getMessaging } = require('firebase-admin/messaging');

const app = express();

app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
const serviceAccount = require(
  path.join(__dirname, 'serviceAccountKey.json')
);

const firebaseApp = initializeApp({
  credential: cert(serviceAccount),
  databaseURL:
    'https://etkalem-app-default-rtdb.europe-west1.firebasedatabase.app/',
});

// Firebase services
const auth = getAuth(firebaseApp);
const firestore = getFirestore(firebaseApp);
const realtimeDatabase = getDatabase(firebaseApp);
const messaging = getMessaging(firebaseApp);

// Health check
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Etkalem Backend is running!',
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
  });
});

// Firebase connection check
app.get('/firebase-check', async (req, res) => {
  try {
    await firestore.collection('Users').limit(1).get();

    await realtimeDatabase
      .ref('activeChats')
      .limitToFirst(1)
      .once('value');

    res.status(200).json({
      success: true,
      firestore: 'Connected',
      realtimeDatabase: 'Connected',
      messaging: 'Initialized',
    });
  } catch (error) {
    console.error('Firebase Connection Error:', error);

    res.status(500).json({
      success: false,
      message: 'Firebase connection failed',
    });
  }
});

// Firebase Authentication middleware
async function verifyFirebaseToken(req, res, next) {
  try {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authentication token is required',
      });
    }

    const idToken = authorization.split('Bearer ')[1];

    const decodedToken = await auth.verifyIdToken(idToken);

    req.user = decodedToken;

    next();
  } catch (error) {
    console.error('Authentication Error:', error.message);

    return res.status(401).json({
      success: false,
      message: 'Invalid authentication token',
    });
  }
}

// Send notification
app.post('/send-notification', verifyFirebaseToken, async (req, res) => {
  try {
    const { chatRoomID, messageID } = req.body;

    if (!chatRoomID || !messageID) {
      return res.status(400).json({
        success: false,
        message: 'chatRoomID and messageID are required',
      });
    }

    // Get the actual message from Firestore
    const messageRef = firestore
      .collection('chat_rooms')
      .doc(chatRoomID)
      .collection('messages')
      .doc(messageID);

    const messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists) {
      return res.status(404).json({
        success: false,
        message: 'Message not found',
      });
    }

    const messageData = messageSnapshot.data();

    const senderID = messageData.senderID;
    const receiverID = messageData.receiverID;

    // Verify sender identity
    if (senderID !== req.user.uid) {
      return res.status(403).json({
        success: false,
        message: 'You are not allowed to send this notification',
      });
    }

    if (!receiverID || receiverID === senderID) {
      return res.status(400).json({
        success: false,
        message: 'Invalid receiver',
      });
    }

    // Verify chat room ID
    const sortedIDs = [senderID, receiverID].sort();
    const expectedChatRoomID = sortedIDs.join('_');

    if (chatRoomID !== expectedChatRoomID) {
      return res.status(403).json({
        success: false,
        message: 'Invalid chat room',
      });
    }

    // Get recipient FCM token
    const receiverSnapshot = await firestore
      .collection('Users')
      .doc(receiverID)
      .get();

    if (!receiverSnapshot.exists) {
      return res.status(404).json({
        success: false,
        message: 'Recipient not found',
      });
    }

    const receiverData = receiverSnapshot.data();
    const receiverToken = receiverData.fcmToken;

    if (!receiverToken) {
      return res.status(200).json({
        success: true,
        notificationSent: false,
        reason: 'Recipient has no FCM token',
      });
    }

    // Check if recipient is viewing this chat
    const activeChatSnapshot = await realtimeDatabase
      .ref(`activeChats/${receiverID}`)
      .once('value');

    const activeChatID = activeChatSnapshot.val();

    if (activeChatID === chatRoomID) {
      return res.status(200).json({
        success: true,
        notificationSent: false,
        reason: 'Recipient is viewing this chat',
      });
    }

    // Get sender display name
    const senderSnapshot = await firestore
      .collection('PublicUsers')
      .where('uid', '==', senderID)
      .limit(1)
      .get();

    let senderName = 'New message';

    if (!senderSnapshot.empty) {
      senderName =
        senderSnapshot.docs[0].data().displayName || senderName;
    }

    // Prepare notification preview
    const messageText = String(messageData.message || '');

    const notificationBody =
      messageText.length > 120
        ? `${messageText.substring(0, 117)}...`
        : messageText;

    // Send FCM notification
    const response = await messaging.send({
      token: receiverToken,

      notification: {
        title: senderName,
        body: notificationBody,
      },

      data: {
        type: 'chat',
        chatRoomID: chatRoomID,
        messageID: messageID,
        senderID: senderID,
        receiverID: receiverID,
      },

      android: {
        priority: 'high',
        notification: {
          channelId: 'chat_messages',
          sound: 'default',
        },
      },

      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    });

    console.log('Notification sent:', response);

    return res.status(200).json({
      success: true,
      notificationSent: true,
    });
  } catch (error) {
    console.error('Notification Error:', error);

    return res.status(500).json({
      success: false,
      message: 'Failed to send notification',
    });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Etkalem Backend running on port ${PORT}`);
});
