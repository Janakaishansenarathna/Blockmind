// utils/helpers/loading_helper.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants/app_colors.dart';

class LoadingHelper {
  static bool _isLoading = false;

  static void show(String message) {
    if (_isLoading) return;

    _isLoading = true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: AppColors.accentBlue,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.buttonPrimary),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (_isLoading) {
      _isLoading = false;
      Get.back();
    }
  }
}
