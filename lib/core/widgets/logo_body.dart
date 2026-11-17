import 'package:etkalem/core/resources/asstes.dart';
import 'package:flutter/material.dart';

class LogoBody extends StatelessWidget {
  const LogoBody({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        AssetImages.logoPng,
        fit: BoxFit.contain,
      ),
    );
  }
}