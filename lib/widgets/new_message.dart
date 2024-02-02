// widgets/new_message.dart

import 'package:flutter/material.dart';
import 'package:authentication_01/widgets/user_image_upload.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewMessage extends StatefulWidget {
  @override
  _NewMessageState createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  final _controller = TextEditingController();
  final ImageService _userImageUpload = ImageService();
  String? _selectedImageUrl;

  Future<void> _sendMessage() async {
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userData.exists) {
      // Check if both the text and the image are empty
      if (_controller.text.trim().isEmpty && _selectedImageUrl == null) {
        // Show a warning to the user and return
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter a message or select an image')),
        );
        return;
      }

      FirebaseFirestore.instance.collection('chat').add({
        'text': _controller.text,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
        'username': userData.data()?['username'] ?? 'Anonymous',
        'userImage': userData.data()?['image_url'] ?? 'default_image_url',
        'image_url': _selectedImageUrl, // Add this line
      });

      _controller.clear();
      setState(() {
        _selectedImageUrl = null;
      });
    } else {
      // Handle the case where the user data does not exist
      print('User data does not exist');
    }
  }

  Future<void> _pickImage() async {
    String? imageUrl = await _userImageUpload.pickAndUploadImage();
    if (imageUrl != null) {
      setState(() {
        _selectedImageUrl = imageUrl;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.image),
            onPressed: _pickImage,
          ),
          if (_selectedImageUrl != null)
            Image.network(_selectedImageUrl!, width: 50, height: 50),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Send a message...'),
              onChanged: (value) {
                // Update your message text here
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
