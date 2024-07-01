import 'package:flutter/material.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}
