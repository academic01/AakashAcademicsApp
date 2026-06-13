import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient school = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C7CF0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient boards = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient govtJobs = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cuet = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient jeeNeet = LinearGradient(
    colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient getGradientForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'school':
      case 'vi-x':
      case 'vi':
      case 'vii':
      case 'viii':
      case 'ix':
      case 'x':
        return school;
      case 'boards':
      case 'xi-xii':
      case 'xi':
      case 'xii':
        return boards;
      case 'govt':
      case 'govt jobs':
      case 'ssc':
      case 'railway':
        return govtJobs;
      case 'cuet':
      case 'cuet 2026':
        return cuet;
      default:
        return jeeNeet;
    }
  }

  static String getEmojiForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'school':
      case 'vi-x':
      case 'vi':
      case 'vii':
      case 'viii':
      case 'ix':
      case 'x':
        return '📐';
      case 'boards':
      case 'xi-xii':
      case 'xi':
      case 'xii':
        return '🔬';
      case 'govt':
      case 'govt jobs':
      case 'ssc':
      case 'railway':
        return '🏆';
      case 'cuet':
      case 'cuet 2026':
        return '🎓';
      default:
        return '📚';
    }
  }
}
