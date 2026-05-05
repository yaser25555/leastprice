import 'package:flutter/material.dart';



class AppBrandMark extends StatelessWidget {
  const AppBrandMark({
    super.key,
    this.size = 58,
    this.padding = 8,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 20,
  });

  final double size;
  final double padding;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Image.asset(
        'assets/icons/logo_lp_navy_orange.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
