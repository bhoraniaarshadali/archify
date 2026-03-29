// import 'interior_transformation_mapper.dart';
//
// class InteriorExperimentPipeline {
//   static String buildPrompt({
//     required String styleName,
//     required String stylePrompt,
//     required List<String> selectedColors,
//     required int progress, // 0–100
//   }) {
//     final transformation =
//         InteriorTransformationMapper.fromProgress(progress);
//
//     final colorText = selectedColors.isEmpty
//         ? ''
//         : 'override and ignore all previously defined, suggested, or default color palettes. Use only the selected color palette (${selectedColors.join(', ')}) and apply it including to walls and totally change the furniture and celling.';
//
//     return 'use uploaded image and transform into'
//         '$styleName'
//         '$transformation'
//         '$stylePrompt'
//         '$colorText';
//   }
// }


import 'interior_transformation_mapper.dart';

class InteriorExperimentPipeline {
  static String buildPrompt({
    required String styleName,
    required String stylePrompt,
    required List<String> selectedColors,
    required int progress, // 0–100
    String? roomType,
  }) {
    final transformation =
    InteriorTransformationMapper.fromProgress(progress);

    final colorText = selectedColors.isEmpty
        ? ''
        : ' override and ignore all previously defined, suggested, or default color palettes. Use only the selected color palette (${selectedColors.join(', ')}) and apply it including to walls and totally change the furniture and celling.';

    if (roomType != null && roomType.isNotEmpty) {
      return 'use uploaded image and transform this $roomType into $transformation $stylePrompt $colorText';
    }

    return 'use uploaded image and transform into $transformation $stylePrompt $colorText';
  }
}
