import 'package:flutter/material.dart';

class PrimaryGenerateButton extends StatelessWidget {
  final String title;
  final bool isGenerating;
  final VoidCallback? onTap;

  const PrimaryGenerateButton({
    super.key,
    required this.title,
    required this.isGenerating,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isGenerating ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 0),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: isGenerating
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF135bec), Color(0xFF50A1FF)],
                ),
          color: isGenerating ? Colors.blueGrey.shade200 : null,
          boxShadow: isGenerating
              ? []
              : [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: Center(
          child: isGenerating
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
