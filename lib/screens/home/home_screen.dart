import 'package:etkalem/core/widgets/my_drawer.dart';
import 'package:etkalem/core/widgets/user_tile.dart';
import 'package:etkalem/screens/chat/chat_screen.dart';
import 'package:etkalem/screens/home/widgets/user_list_skeleton.dart';
import 'package:etkalem/services/auth/auth_service.dart';
import 'package:etkalem/services/chat/chat_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(
          "Etkalem",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        elevation: 0,
      ),
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 25),

            Text(
              "Discover people",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Find someone and start a conversation.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 24),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: TextField(
                controller: _searchController,
                cursorColor: colors.primary,
                style: TextStyle(color: colors.onSurface),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search by name...",
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = "";
                            });
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              "People",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 14),

            Expanded(child: _buildUserList()),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _chatService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading users",
              style: TextStyle(color: colors.error),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const UserListSkeleton();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final currentUserId = _authService.getCurrentUser()?.uid;
        final users = snapshot.data!.where((userData) {
          final userId = userData["uid"];
          final name = (userData["displayName"] ?? "").toString().toLowerCase();

          return userId != currentUserId && name.contains(searchQuery);
        }).toList();

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  searchQuery.isEmpty
                      ? Icons.people_outline_rounded
                      : Icons.search_off_rounded,
                  size: 55,
                  color: colors.onSurfaceVariant,
                ),

                const SizedBox(height: 15),

                Text(
                  searchQuery.isEmpty ? "No users found" : "No matching users",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  searchQuery.isEmpty
                      ? "New users will appear here."
                      : "Try searching with another name.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index];
            final userName = userData["displayName"] ?? "Unknown User";
            final userId = userData["uid"];

            return UserTile(
              text: userName,
              receiverID: userId,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatScreen(receiverName: userName, receiverID: userId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}