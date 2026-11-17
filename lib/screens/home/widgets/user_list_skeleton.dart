import 'package:flutter/material.dart';

class UserListSkeleton extends StatefulWidget {
  const UserListSkeleton({super.key});

  @override
  State<UserListSkeleton> createState() => _UserListSkeletonState();
}

class _UserListSkeletonState extends State<UserListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final skeletonColor = isDark
        ? const Color(0xFF374151)
        : const Color(0xFFE5E7EB);

    final shimmerColor = isDark
        ? const Color(0xFF4B5563)
        : const Color(0xFFF9FAFB);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 + 3 * _controller.value, 0),
              end: Alignment(1 + 3 * _controller.value, 0),
              colors: [skeletonColor, shimmerColor, skeletonColor],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              children: [
                _buildCircle(skeletonColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLine(skeletonColor, 135, 14),
                      const SizedBox(height: 10),
                      _buildLine(skeletonColor, 90, 11),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircle(Color color) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildLine(Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
