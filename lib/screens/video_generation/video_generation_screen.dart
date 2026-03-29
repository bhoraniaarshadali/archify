import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../navigation/app_navigator.dart';
import '../../services/helper/temp_file_upload_service.dart';
import '../../services/ApiFreeUse/video_generation_service.dart';
import 'video_generation_loading_screen.dart';
import '../../widgets/primary_generate_button.dart';
import '../../ads/app_state.dart';

class VideoGenerationScreen extends StatefulWidget {
  final String? initialImageUrl;
  final String? initialCategory;

  const VideoGenerationScreen({
    super.key,
    this.initialImageUrl,
    this.initialCategory,
  });

  @override
  State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
}

class _VideoGenerationScreenState extends State<VideoGenerationScreen> {
  String? _selectedCategory;
  int _selectedDuration = 5;
  File? _selectedFile;
  String? _imageUrl;
  bool _isGenerating = false;

  final List<String> _categories = ['Interior', 'Exterior', '3D Model'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _imageUrl = widget.initialImageUrl;

    // Default to 10s if 3D Model is initial category
    if (_selectedCategory == '3D Model') {
      _selectedDuration = 10;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
        _imageUrl = null;
      });
    }
  }

  Future<void> _handleGenerate() async {
    if (_isGenerating) return;

    // 1. Premium Check
    if (!AppState.isPremiumUser) {
      _showPremiumRequiredDialog();
      return;
    }

    // 2. Validation
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedFile == null && _imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or upload an image')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      String? finalImageUrl = _imageUrl;

      // 3. Upload Image if it's a local file
      if (finalImageUrl == null && _selectedFile != null) {
        debugPrint('📤 Uploading local image to Cloudinary...');
        finalImageUrl = await TempFileUploadService.uploadImage(_selectedFile!);
      }

      if (finalImageUrl == null) {
        throw Exception('Failed to upload image. Please check your connection.');
      }

      // 4. Submit Video Request
      //debugPrint('🎬 Submitting video request for: $finalImageUrl');
      final requestId = await VideoGenerationService.submitVideoRequest(
        imageUrl: finalImageUrl,
        category: _selectedCategory!,
        duration: _selectedDuration,
      );

      if (requestId != null && mounted) {
        // 5. Navigate to Loading Screen
        AppNavigator.pushReplacement(
          context,
          VideoGenerationLoadingScreen(
            requestId: requestId,
            category: _selectedCategory!,
            duration: _selectedDuration,
            originalImageUrl: finalImageUrl,
          ),
        );
      } else if (mounted) {
        throw Exception('Failed to submit video request.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showPremiumRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Premium Feature'),
        content: const Text('Video generation is available for premium users only. Upgrade now to create cinematic animations of your designs!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to subscription screen if available
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Generation',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: _isGenerating ? null : (selected) {
                    setState(() {
                      _selectedCategory = selected ? cat : null;
                      if (_selectedCategory == '3D Model') {
                        _selectedDuration = 10;
                      }
                    });
                  },
                  selectedColor: Colors.indigo.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.indigo : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            if (_selectedCategory != '3D Model') ...[
              const Text(
                '2. Select Duration',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _DurationChip(
                    label: '5 Seconds',
                    isSelected: _selectedDuration == 5,
                    onTap: () => setState(() => _selectedDuration = 5),
                  ),
                  const SizedBox(width: 12),
                  _DurationChip(
                    label: '10 Seconds',
                    isSelected: _selectedDuration == 10,
                    onTap: () => setState(() => _selectedDuration = 10),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            Text(
              _selectedCategory != '3D Model' ? '3. Input Image' : '2. Input Image',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isGenerating ? null : _pickImage,
              child: Container(
                height: 240,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: _selectedFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_selectedFile!, fit: BoxFit.cover),
                      )
                    : (_imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(_imageUrl!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Tap to upload image', style: TextStyle(color: Colors.grey[600])),
                            ],
                          )),
              ),
            ),
            const SizedBox(height: 40),

            PrimaryGenerateButton(
              title: 'Generate Video',
              isGenerating: _isGenerating,
              onTap: _isGenerating ? null : _handleGenerate,
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'AI will create a $_selectedDuration-second cinematic animation',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../../navigation/app_navigator.dart';
// import '../../services/helper/temp_file_upload_service.dart';
// import '../../services/ApiFreeUse/video_generation_service.dart';
// import '../../services/daily_credit_manager.dart';
// import '../../widgets/daily_credit_badge.dart';
// import 'video_generation_loading_screen.dart';
// import '../../widgets/primary_generate_button.dart';
// import '../../ads/app_state.dart';
//
// class VideoGenerationScreen extends StatefulWidget {
//   final String? initialImageUrl;
//   final String? initialCategory;
//
//   const VideoGenerationScreen({
//     super.key,
//     this.initialImageUrl,
//     this.initialCategory,
//   });
//
//   @override
//   State<VideoGenerationScreen> createState() => _VideoGenerationScreenState();
// }
//
// class _VideoGenerationScreenState extends State<VideoGenerationScreen>
//     with TickerProviderStateMixin {
//   String? _selectedCategory;
//   int _selectedDuration = 5;
//   File? _selectedFile;
//   String? _imageUrl;
//   bool _isGenerating = false;
//
//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;
//
//   final List<CategoryOption> _categories = [
//     CategoryOption(
//       name: 'Interior',
//       icon: Icons.meeting_room_rounded,
//       description: 'Bring interior spaces to life',
//       gradient: const LinearGradient(
//         colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//     ),
//     CategoryOption(
//       name: 'Exterior',
//       icon: Icons.landscape_rounded,
//       description: 'Animate outdoor scenes',
//       gradient: const LinearGradient(
//         colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//     ),
//     CategoryOption(
//       name: '3D Model',
//       icon: Icons.view_in_ar_rounded,
//       description: 'Rotate and showcase 3D objects',
//       gradient: const LinearGradient(
//         colors: [Color(0xFFEC4899), Color(0xFFF59E0B)],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//     ),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _selectedCategory = widget.initialCategory;
//     _imageUrl = widget.initialImageUrl;
//
//     if (_selectedCategory == '3D Model') {
//       _selectedDuration = 10;
//     }
//
//     _fadeController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeOut,
//     );
//     _fadeController.forward();
//   }
//
//   @override
//   void dispose() {
//     _fadeController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         _selectedFile = File(pickedFile.path);
//         _imageUrl = null;
//       });
//     }
//   }
//
//   Future<void> _handleGenerate() async {
//     // 🪙 Credit System Check (Universal for non-premium)
//     if (mounted) {
//       final hasCredit = await DailyCreditManager.checkAndConsume(context);
//       if (!hasCredit) return;
//     }
//
//     if (_selectedCategory == null) {
//       _showSnackBar('Please select a category', isError: true);
//       return;
//     }
//
//     if (_selectedFile == null && _imageUrl == null) {
//       _showSnackBar('Please select or upload an image', isError: true);
//       return;
//     }
//
//     setState(() => _isGenerating = true);
//
//     try {
//       String? finalImageUrl = _imageUrl;
//
//       if (finalImageUrl == null && _selectedFile != null) {
//         debugPrint('📤 Uploading local image to Cloudinary...');
//         finalImageUrl = await TempFileUploadService.uploadImage(_selectedFile!);
//       }
//
//       if (finalImageUrl == null) {
//         throw Exception('Failed to upload image. Please check your connection.');
//       }
//
//       final requestId = await VideoGenerationService.submitVideoRequest(
//         imageUrl: finalImageUrl,
//         category: _selectedCategory!,
//         duration: _selectedDuration,
//       );
//
//       if (requestId != null && mounted) {
//         AppNavigator.pushReplacement(
//           context,
//           VideoGenerationLoadingScreen(
//             requestId: requestId,
//             category: _selectedCategory!,
//             duration: _selectedDuration,
//             originalImageUrl: finalImageUrl,
//           ),
//         );
//       } else if (mounted) {
//         throw Exception('Failed to submit video request.');
//       }
//     } catch (e) {
//       if (mounted) {
//         _showSnackBar('Error: $e', isError: true);
//       }
//     } finally {
//       if (mounted) setState(() => _isGenerating = false);
//     }
//   }
//
//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.check_circle_outline,
//               color: Colors.white,
//               size: 20,
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   void _showPremiumRequiredDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
//         child: Container(
//           padding: const EdgeInsets.all(32),
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(28),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.workspace_premium_rounded,
//                   color: Color(0xFFFBBF24),
//                   size: 48,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               const Text(
//                 'Premium Feature',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Video generation is available for premium users only. Unlock cinematic animations of your designs!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.8),
//                   fontSize: 15,
//                   height: 1.5,
//                 ),
//               ),
//               const SizedBox(height: 32),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       style: TextButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'Later',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 2,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                         // TODO: Navigate to subscription screen
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFFBBF24),
//                         foregroundColor: const Color(0xFF1E1B4B),
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         'Upgrade Now',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0F0F0F),
//       body: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: Column(
//             children: [
//               _buildHeader(),
//               Expanded(
//                 child: SingleChildScrollView(
//                   padding: const EdgeInsets.all(24),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildStepHeader('01', 'Choose Your Style'),
//                       const SizedBox(height: 20),
//                       _buildCategoryGrid(),
//                       const SizedBox(height: 40),
//                       if (_selectedCategory != '3D Model') ...[
//                         _buildStepHeader('02', 'Duration'),
//                         const SizedBox(height: 20),
//                         _buildDurationSelector(),
//                         const SizedBox(height: 40),
//                       ],
//                       _buildStepHeader(
//                         _selectedCategory != '3D Model' ? '03' : '02',
//                         'Upload Your Image',
//                       ),
//                       const SizedBox(height: 20),
//                       _buildImageUploader(),
//                       const SizedBox(height: 40),
//                       _buildGenerateButton(),
//                       const SizedBox(height: 16),
//                       _buildFooterText(),
//                     ],
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         border: Border(
//           bottom: BorderSide(
//             color: Colors.white.withOpacity(0.1),
//             width: 1,
//           ),
//         ),
//       ),
//       child: Row(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Video Generation',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: -0.5,
//                 ),
//               ),
//               Text(
//                 'Transform stills into motion',
//                 style: TextStyle(
//                   color: Colors.white.withOpacity(0.5),
//                   fontSize: 13,
//                 ),
//               ),
//             ],
//           ),
//           const Spacer(),
//           const DailyCreditBadge(themeColor: Colors.white),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStepHeader(String number, String title) {
//     return Row(
//       children: [
//         Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(
//             gradient: const LinearGradient(
//               colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
//             ),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Center(
//             child: Text(
//               number,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         const SizedBox(width: 12),
//         Text(
//           title,
//           style: const TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             letterSpacing: -0.3,
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildCategoryGrid() {
//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 1,
//         childAspectRatio: 3.5,
//         mainAxisSpacing: 12,
//       ),
//       itemCount: _categories.length,
//       itemBuilder: (context, index) {
//         final category = _categories[index];
//         final isSelected = _selectedCategory == category.name;
//
//         return GestureDetector(
//           onTap: _isGenerating
//               ? null
//               : () {
//             setState(() {
//               _selectedCategory = category.name;
//               if (category.name == '3D Model') {
//                 _selectedDuration = 10;
//               }
//             });
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             decoration: BoxDecoration(
//               gradient: isSelected ? category.gradient : null,
//               color: isSelected ? null : Colors.white.withOpacity(0.05),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: isSelected
//                     ? Colors.transparent
//                     : Colors.white.withOpacity(0.1),
//                 width: 1.5,
//               ),
//             ),
//             padding: const EdgeInsets.all(20),
//             child: Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: isSelected
//                         ? Colors.white.withOpacity(0.2)
//                         : Colors.white.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(
//                     category.icon,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         category.name,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         category.description,
//                         style: TextStyle(
//                           color: Colors.white.withOpacity(0.7),
//                           fontSize: 13,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (isSelected)
//                   const Icon(
//                     Icons.check_circle_rounded,
//                     color: Colors.white,
//                     size: 24,
//                   ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDurationSelector() {
//     return Row(
//       children: [
//         Expanded(
//           child: _buildDurationCard(5, '5s', 'Quick preview'),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _buildDurationCard(10, '10s', 'Full cinematic'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDurationCard(int duration, String label, String subtitle) {
//     final isSelected = _selectedDuration == duration;
//
//     return GestureDetector(
//       onTap: () => setState(() => _selectedDuration = duration),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? const Color(0xFF6366F1).withOpacity(0.15)
//               : Colors.white.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(
//             color: isSelected
//                 ? const Color(0xFF6366F1)
//                 : Colors.white.withOpacity(0.1),
//             width: 2,
//           ),
//         ),
//         child: Column(
//           children: [
//             Text(
//               label,
//               style: TextStyle(
//                 color: isSelected ? const Color(0xFF6366F1) : Colors.white,
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 letterSpacing: -1,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               subtitle,
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.6),
//                 fontSize: 13,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildImageUploader() {
//     return GestureDetector(
//       onTap: _isGenerating ? null : _pickImage,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         height: 280,
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.03),
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: (_selectedFile != null || _imageUrl != null)
//                 ? const Color(0xFF6366F1).withOpacity(0.5)
//                 : Colors.white.withOpacity(0.1),
//             width: 2,
//             strokeAlign: BorderSide.strokeAlignInside,
//           ),
//         ),
//         child: _selectedFile != null
//             ? Stack(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(18),
//               child: Image.file(
//                 _selectedFile!,
//                 fit: BoxFit.cover,
//                 width: double.infinity,
//                 height: double.infinity,
//               ),
//             ),
//             Positioned(
//               top: 12,
//               right: 12,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.6),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white, size: 20),
//                   onPressed: () => setState(() {
//                     _selectedFile = null;
//                     _imageUrl = widget.initialImageUrl;
//                   }),
//                 ),
//               ),
//             ),
//           ],
//         )
//             : (_imageUrl != null
//             ? Stack(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(18),
//               child: Image.network(
//                 _imageUrl!,
//                 fit: BoxFit.cover,
//                 width: double.infinity,
//                 height: double.infinity,
//               ),
//             ),
//             Positioned(
//               top: 12,
//               right: 12,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.6),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white, size: 20),
//                   onPressed: () => setState(() => _imageUrl = null),
//                 ),
//               ),
//             ),
//           ],
//         )
//             : Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF6366F1).withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.add_photo_alternate_rounded,
//                 size: 48,
//                 color: Color(0xFF6366F1),
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Tap to upload image',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'JPG, PNG • Max 10MB',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.5),
//                 fontSize: 13,
//               ),
//             ),
//           ],
//         )),
//       ),
//     );
//   }
//
//   Widget _buildGenerateButton() {
//     final canGenerate = _selectedCategory != null &&
//         (_selectedFile != null || _imageUrl != null) &&
//         !_isGenerating;
//
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       width: double.infinity,
//       height: 60,
//       decoration: BoxDecoration(
//         gradient: canGenerate
//             ? const LinearGradient(
//           colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
//         )
//             : null,
//         color: canGenerate ? null : Colors.white.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: canGenerate
//             ? [
//           BoxShadow(
//             color: const Color(0xFF6366F1).withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 8),
//           ),
//         ]
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: canGenerate ? _handleGenerate : null,
//           borderRadius: BorderRadius.circular(16),
//           child: Center(
//             child: _isGenerating
//                 ? const SizedBox(
//               width: 24,
//               height: 24,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2.5,
//                 color: Colors.white,
//               ),
//             )
//                 : Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.play_circle_filled_rounded,
//                   color: Colors.white,
//                   size: 24,
//                 ),
//                 const SizedBox(width: 12),
//                 Text(
//                   'Generate Video',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: -0.3,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFooterText() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.info_outline_rounded,
//               size: 16,
//               color: Colors.white.withOpacity(0.5),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               'AI will create a $_selectedDuration-second cinematic animation',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.white.withOpacity(0.5),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class CategoryOption {
//   final String name;
//   final IconData icon;
//   final String description;
//   final LinearGradient gradient;
//
//   CategoryOption({
//     required this.name,
//     required this.icon,
//     required this.description,
//     required this.gradient,
//   });
// }