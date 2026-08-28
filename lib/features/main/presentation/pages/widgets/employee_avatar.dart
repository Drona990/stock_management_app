import 'package:flutter/material.dart';

class EmployeeAvatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;
  final double radius;
  final Color backgroundColor;

  const EmployeeAvatar({
    super.key,
    required this.photoUrl,
    required this.initials,
    this.radius = 16,
    this.backgroundColor = const Color(0xFF0066B3),
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: ClipOval(
          child: Image.network(
            photoUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: radius,
                  height: radius,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: backgroundColor,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          ),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.75,
        ),
      ),
    );
  }
}