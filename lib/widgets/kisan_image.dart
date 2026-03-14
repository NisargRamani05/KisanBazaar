import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:kisanbazaar/theme/app_colors.dart';

class KisanImage extends StatelessWidget {
  final String imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const KisanImage({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (imageSource.isEmpty) {
      return placeholder ?? _buildPlaceholder();
    }

    if (imageSource.startsWith('http')) {
      return Image.network(
        imageSource,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => placeholder ?? _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: AppColors.primaryLight,
            ),
          );
        },
      );
    } else {
      try {
        // Assume it's base64
        return Image.memory(
          base64Decode(imageSource),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder ?? _buildPlaceholder(),
        );
      } catch (e) {
        return placeholder ?? _buildPlaceholder();
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.background,
      child: const Center(
        child: Icon(
          Icons.eco_outlined,
          size: 40,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }
}
