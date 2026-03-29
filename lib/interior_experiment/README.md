# 🧪 Interior Experiment Pipeline

## Overview
This is a **clean, isolated, test-only pipeline** for Interior Design using pure JSON.

**⚠️ IMPORTANT**: This does NOT affect any existing app logic. It's completely isolated for testing.

---

## What This Does

✅ Uses **ONLY JSON** (no Dart style definitions)  
✅ Shows **style_name** in UI  
✅ Sends **prompt** to image generation  
✅ Injects prompt like this:

```
"use uploaded image and transform into " 
+ <json.prompt> 
+ " using the selected color palette: <user colors>"
```

✅ Works **only for Interior**  
✅ Lives in a **new folder** (`lib/interior_experiment/`)  
✅ Safe for testing  
✅ Zero side-effects on existing app  

---

## Folder Structure

```
lib/
 └── interior_experiment/
     ├── data/
     │   └── interior_styles_repository.dart    # Loads JSON
     ├── model/
     │   └── interior_style_model.dart          # JSON → Dart model
     ├── service/
     │   └── interior_experiment_pipeline.dart  # Prompt builder (CORE LOGIC)
     └── interior_experiment_screen.dart        # Test UI

assets/
 └── json/
     └── interior_styles.json        # Pure JSON data
```

---

## How to Use

### 1. Replace the JSON Data

Edit `assets/json/interior_styles.json` with your actual interior styles JSON.

The JSON format should be:
```json
[
  {
    "type": "interior",
    "template_id": "INT001",
    "style_name": "Modern Minimalist",
    "prompt": "a modern minimalist interior with clean lines...",
    "example_image": "https://example.com/image.jpg"
  }
]
```

### 2. Test the Pipeline

Navigate to the test screen:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const InteriorExperimentScreen(),
  ),
);
```

### 3. Use in Production (When Ready)

```dart
// Load styles
final styles = await InteriorStylesRepository.loadStyles();

// Select a style
final selectedStyle = styles.first;

// Build final prompt
final finalPrompt = InteriorExperimentPipeline.buildPrompt(
  uploadedImageNote: 'use uploaded image',
  stylePrompt: selectedStyle.prompt,
  selectedColors: ['Warm White', 'Oak Wood', 'Soft Beige'],
);

// Send finalPrompt to your image generation service
```

---

## Core Logic (Prompt Building)

The main prompt mutation happens in:
`lib/interior_experiment/service/interior_experiment_pipeline.dart`

```dart
static String buildPrompt({
  required String uploadedImageNote,
  required String stylePrompt,
  required List<String> selectedColors,
}) {
  final colorText = selectedColors.isEmpty
      ? ''
      : ' using the selected color palette: ${selectedColors.join(', ')}';

  return 'use uploaded image and transform into '
      '$stylePrompt'
      '$colorText';
}
```

---

## UI Display Rules

- **style_name** → Shown as UI title/label
- **prompt** → Used for generation (not shown to user)
- **example_image** → Preview only
- **Colors** → User selects from predefined palette (optional)

---

## What This Does NOT Touch

❌ Existing Interior services  
❌ Kitchen fixed-prompt logic  
❌ FloorPlan  
❌ Video  
❌ My Creations  
❌ Premium logic  
❌ Any existing screens  

This is **test-only**, isolated, and fully reversible.

---

## Testing Checklist

- [ ] Replace JSON data with your actual styles
- [ ] Run `flutter pub get`
- [ ] Navigate to `InteriorExperimentScreen`
- [ ] Select a style
- [ ] Select colors (optional)
- [ ] Verify the final prompt looks correct
- [ ] Integrate with your image generation service when ready

---

## Next Steps

1. **Replace the sample JSON** in `assets/json/interior_styles.json` with your real data
2. **Test the screen** to verify prompt generation
3. **When satisfied**, integrate the pipeline into your main interior flow
4. **Delete this folder** if you decide not to use it (zero impact on existing code)

---

**Questions?** This pipeline is completely isolated and safe to experiment with!
