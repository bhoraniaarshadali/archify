// class InteriorTransformationMapper {
//   static String fromProgress(int progress) {
//     if (progress <= 0) {
//       return ' (keep the room core structure exact and only do very minor decoration changes) ';
//     } else if (progress <= 50) {
//       return ' (keep the room core structure and layout but transform style significantly) ';
//     } else {
//       return ' (totally transform the room including furniture, layout, and structure while maintaining the space context) ';
//     }
//   }
// }

class InteriorTransformationMapper {
  static String fromProgress(int progress) {
    final clampedProgress = progress.clamp(0, 100);

    if (clampedProgress <= 20) {
      return 'with minimal transformation — keep all furniture, layout, and structure exactly as-is. Only apply subtle color adjustments, surface refinements, and light decor updates to match the style.';
    } else if (clampedProgress <= 60) {
      return 'with moderate transformation — preserve the room layout and major furniture positions, but upgrade all surface materials, finishes, lighting fixtures, and decorative elements to fully match the style.';
    } else {
      return 'with full transformation — completely redesign the room including furniture style, surface materials, lighting, decor, and color scheme. Keep only the spatial dimensions and window/door positions unchanged.';
    }
  }
}