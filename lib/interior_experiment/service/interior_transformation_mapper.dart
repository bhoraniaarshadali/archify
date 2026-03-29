class InteriorTransformationMapper {
  static String fromProgress(int progress) {
    // Exact mapping for 0, 50, 100 as requested
    if (progress <= 0) {
      return
      '''
      PRESERVE TABLE SHAPE: If round, keep round. If rectangular, keep rectangular. 
      PRESERVE CHAIR COUNT: Do not add or remove chairs. Keep exact arrangement.
      PRESERVE SCALE: Do not make the table larger or smaller.
      a interior enhancement with maximum preservation.
      Preserve walls style but apply color platter, furniture very light transform, layout, materials, lighting same as old, no furniture move.''';

      // 'a very light interior enhancement with maximum preservation. '
          // 'Preserve walls, furniture, layout, materials, lighting, and decor almost exactly as the uploaded image. '
          // 'Only minimal refinement in cleanliness, color balance, and subtle realism. ';
    }

    if (progress >= 100) {
      return
          'a strong interior style transformation while strictly preserving the existing layout and furniture placement. '
          'Upgrade furniture styles, materials, finishes, textures, and design language to a premium level. '
          'No furniture should move, but all surfaces, finishes, and styling should be fully modernized. ';
    }

    // Default / 50% behavior
    return
      //'Preserve the original layout and furniture placement while clearly, wall design, same but style update furniture, materials, lighting, and overall design quality.';
     'Apply the selected style to existing furniture or built-in fixtures relevant to this room type only.'
     'Preserve the original layout and furniture placement. Keep the wall design, lighting setup, and room structure exactly the same. Upgrade only the furniture style and materials to a more luxurious, high-end finish. Do NOT change walls, flooring, ceiling, lighting, or room structure. ';
        // 'a balanced interior transformation.'
  }
}



