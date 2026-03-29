import 'package:flutter/material.dart';
import '../../ads/app_state.dart';
import '../../services/helper/text_to_image_count_service.dart';
import '../../widgets/primary_generate_button.dart';
import 'text_to_image_processing_screen.dart';

class TextToImageScreen extends StatefulWidget {
  final String designType;
  final String? initialPrompt;

  const TextToImageScreen({
    super.key,
    required this.designType,
    this.initialPrompt,
  });

  @override
  State<TextToImageScreen> createState() => _TextToImageScreenState();
}

class _TextToImageScreenState extends State<TextToImageScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _aspectRatio = '1:1';

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      _promptController.text = widget.initialPrompt!;
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _shufflePrompt() {
    const samplePrompts = [
      "Modern luxury living room with elegant furniture, neutral tones, large windows.",
      "Stylish contemporary bedroom interior with cozy textures, warm lighting.",
      "High-end modular kitchen design with sleek cabinets, marble countertops.",
      "Scandinavian style home interior featuring light wood furniture, minimalist aesthetic.",
      "Modern house exterior with clean architectural lines, landscaped garden.",
      "Contemporary villa with pool, outdoor seating area, tropical plants."
    ];
    setState(() {
      _promptController.text = (List.of(samplePrompts)..shuffle()).first;
    });
  }

  String _generateFinalPrompt(String userPrompt) {
    final isInterior = widget.designType == 'Interior';

    final env = isInterior
        ? "interior design photography, magazine editorial style, architectural digest quality"
        : "architectural exterior photography, professional real estate style, luxury property showcase";

    final material = isInterior
        ? "premium materials, polished marble surfaces, brushed metal accents"
        : "high-end facade materials, textured stone cladding, architectural glass panels";

    const quality = "8k ultra high definition, photorealistic rendering, ray tracing, sharp focus";
    const negative = "--no blurry, low resolution, cartoon, illustration, distorted, artifacts";

    return "$userPrompt, $env, $material, $quality $negative";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          '${widget.designType} Design',
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          _buildCoinIndicator(),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Describe your design', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildPromptInput(),
            _buildShuffleButton(),
            const SizedBox(height: 24),
            const Text('Aspect Ratio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAspectRatioButton('1:1'),
                const SizedBox(width: 12),
                _buildAspectRatioButton('16:9'),
                const SizedBox(width: 12),
                _buildAspectRatioButton('9:16'),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Example prompts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ..._getExamplePrompts(),
            const SizedBox(height: 40),
            _buildGenerateSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        children: [
          Icon(Icons.star, color: Colors.yellow, size: 16),
          SizedBox(width: 4),
          Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPromptInput() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[50]
      ),
      child: TextField(
        controller: _promptController,
        maxLines: null,
        expands: true,
        decoration: InputDecoration(
          hintText: 'Enter your dream ${widget.designType} description...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildShuffleButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _shufflePrompt,
        icon: const Icon(Icons.shuffle, size: 18),
        label: const Text('Shuffle Prompt'),
        style: TextButton.styleFrom(foregroundColor: Colors.purple),
      ),
    );
  }

  Widget _buildAspectRatioButton(String ratio) {
    final isSelected = _aspectRatio == ratio;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _aspectRatio = ratio),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple[100] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.purple : Colors.transparent, width: 2),
          ),
          child: Center(
            child: Text(ratio, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.purple[800] : Colors.grey[600])),
          ),
        ),
      ),
    );
  }

  List<Widget> _getExamplePrompts() {
    final prompts = widget.designType == 'Interior'
        ? ['Modern minimalist bedroom, white walls, wooden floor', 'Cozy living room with fireplace, warm lighting']
        : ['Modern house exterior with glass windows, stone facade', 'Contemporary villa with pool, tropical plants'];

    return prompts.map((p) => Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: _buildExamplePromptItem(p),
    )).toList();
  }

  Widget _buildExamplePromptItem(String prompt) {
    return GestureDetector(
      onTap: () => setState(() => _promptController.text = prompt),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text(prompt, style: const TextStyle(fontSize: 12, color: Colors.black87))),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateSection() {
    return FutureBuilder<int>(
      future: TextToImageUsageService.getRemainingGenerations(),
      builder: (context, snapshot) {
        final remaining = snapshot.data ?? 0;
        final isPremium = AppState.isPremiumUser;
        final isLimitReached = !isPremium && remaining <= 0;

        return Column(
          children: [
            if (!isPremium && snapshot.hasData)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  isLimitReached ? 'Daily limit reached' : '$remaining generations remaining today',
                  style: TextStyle(color: isLimitReached ? Colors.red : Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ),
            PrimaryGenerateButton(
              title: 'Generate Design',
              isGenerating: false,
              onTap: _promptController.text.isEmpty || isLimitReached ? null : _handleGeneration,
            ),
          ],
        );
      },
    );
  }

  void _handleGeneration() async {
    final canGenerate = await TextToImageUsageService.canGenerate();
    if (!canGenerate && !AppState.isPremiumUser) {
      _showLimitDialog();
      return;
    }

    final finalPrompt = _generateFinalPrompt(_promptController.text.trim());
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TextToImageProcessingScreen(
          prompt: finalPrompt,
          aspectRatio: _aspectRatio,
          designType: widget.designType,
        ),
      ),
    );
  }

  void _showLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limit Reached'),
        content: const Text('Upgrade to Premium for unlimited access!'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
      ),
    );
  }
}