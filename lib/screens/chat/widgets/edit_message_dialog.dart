import 'package:flutter/material.dart';

class EditMessageDialog extends StatefulWidget {
  final String oldMessage;
  final Future<void> Function(String) onSave;

  const EditMessageDialog({
    super.key,
    required this.oldMessage,
    required this.onSave,
  });

  @override
  State<EditMessageDialog> createState() => _EditMessageDialogState();
}

class _EditMessageDialogState extends State<EditMessageDialog> {
  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.oldMessage);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Message'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(hintText: 'Enter your message'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final newMessage = controller.text.trim();

            if (newMessage.isEmpty || newMessage == widget.oldMessage) {
              Navigator.pop(context);
              return;
            }

            Navigator.pop(context);
            await widget.onSave(newMessage);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
