import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class FramesEditingScreen extends StatefulWidget {
  final String frameImageUrl;
  final String imagePath;
  final String categoryId;

  const FramesEditingScreen({
    required this.frameImageUrl,
    required this.imagePath,
    required this.categoryId,
    super.key,
  });

  @override
  State<FramesEditingScreen> createState() => _FramesEditingScreenState();
}

class _FramesEditingScreenState extends State<FramesEditingScreen> {
  static const Size _outputCanvasSize = Size(1080, 1720);

  final GlobalKey _captureKey = GlobalKey();
  late String _selectedImagePath;
  late String _selectedFramePath;
  final List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedTextOverlay;
  _EditorTool _selectedTool = _EditorTool.none;
  bool _isFrameLoading = true;
  double _imageScale = 1.0;
  double _imageRotation = 0.0;
  Offset _imageOffset = Offset.zero;
  Offset _initialFocalPoint = Offset.zero;
  Offset _initialOffset = Offset.zero;
  double _initialScale = 1.0;
  double _initialRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.imagePath;
    _selectedFramePath = widget.frameImageUrl;
    _precacheSelectedFrame(_selectedFramePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: _EditorAppBar(onExport: _showExportDialog),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                  child: _buildFrameContent(),
                ),
              ),
            ),
          ),
          _buildStaticBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildFrameContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasAspectRatio =
            _outputCanvasSize.width / _outputCanvasSize.height;
        final maxWidth = min(constraints.maxWidth, 430.0);
        final maxHeight = max(0.0, constraints.maxHeight);

        var canvasWidth = maxWidth;
        var canvasHeight = canvasWidth / canvasAspectRatio;

        if (canvasHeight > maxHeight) {
          canvasHeight = maxHeight;
          canvasWidth = canvasHeight * canvasAspectRatio;
        }

        return Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: canvasWidth,
            height: canvasHeight,
            decoration: BoxDecoration(
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.pakistanGreen.withValues(alpha: 0.12),
                  blurRadius: 38,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: RepaintBoundary(
              key: _captureKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onScaleStart: _onImageScaleStart,
                    onScaleUpdate: _onImageScaleUpdate,
                    child: Transform.translate(
                      offset: _imageOffset,
                      child: Transform.rotate(
                        angle: _imageRotation,
                        child: Transform.scale(
                          scale: _imageScale,
                          child: Image.file(
                            File(_selectedImagePath),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isFrameLoading
                          ? const Center(
                              key: ValueKey('frame-loader'),
                              child: CircularProgressIndicator(),
                            )
                          : SizedBox.expand(
                            child: _buildFrameImage(
                                _selectedFramePath,
                                fit: BoxFit.fill,
                              ),
                          ),
                    ),
                  ),
                  ..._textOverlays.map((overlay) => _buildTextOverlay(overlay)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onImageScaleStart(ScaleStartDetails details) {
    _initialFocalPoint = details.focalPoint;
    _initialOffset = _imageOffset;
    _initialScale = _imageScale;
    _initialRotation = _imageRotation;
  }

  void _onImageScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _imageScale = (_initialScale * details.scale).clamp(0.35, 8.0);
      _imageRotation = _initialRotation + details.rotation;
      _imageOffset = _initialOffset + (details.focalPoint - _initialFocalPoint);
      _selectedTextOverlay = null;
    });
  }

  Widget _buildStaticBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 92,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildToolbarButton(
                AppAssets.editPicture,
                'Change Photo',
                tool: _EditorTool.editPhoto,
                onPressed: _pickNewImage,
              ),
              _buildToolbarButton(
                AppAssets.frameIcon,
                'Frame',
                tool: _EditorTool.frame,
                onPressed: () => _openFramesBottomSheet(widget.categoryId),
              ),
              _buildToolbarButton(
                AppAssets.addTextIcon,
                'Add Text',
                tool: _EditorTool.text,
                onPressed: _addNewText,
              ),
              _buildToolbarButton(
                AppAssets.shareIcon,
                'Export',
                tool: _EditorTool.export,
                onPressed: _showExportDialog,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton(
    String assetPath,
    String label, {
    required _EditorTool tool,
    required VoidCallback onPressed,
  }) {
    final isSelected = _selectedTool == tool;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _selectedTool = tool);
        onPressed();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? AppColors.pakistanGreen
                    : AppColors.pakistanGreen.withValues(alpha: 0.08),
                border: Border.all(
                  color: isSelected
                      ? AppColors.pakistanGreen
                      : AppColors.pakistanGreen.withValues(alpha: 0.14),
                ),
              ),
              child: Center(
                child: Image.asset(
                  assetPath,
                  height: 24,
                  width: 24,
                  color: isSelected ? Colors.white : AppColors.pakistanGreen,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.pakistanGreen
                    : const Color(0xFF8A948E),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFramesBottomSheet(String categoryId) async {
    final framesProvider = Provider.of<IndependenceFrameProvider>(
      context,
      listen: false,
    );

    if (framesProvider.getFrames(categoryId).isEmpty) {
      await framesProvider.fetchFrames(categoryId);
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      builder: (BuildContext context) {
        final frames = framesProvider.getFrames(categoryId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: const Center(
                child: Text(
                  'Select Frame',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: frames.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: frames.length,
                      itemBuilder: (BuildContext context, int index) {
                        final frame = frames[index];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFramePath = frame.frameUrl;
                            });
                            _precacheSelectedFrame(frame.frameUrl);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 20,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.pakistanGreen.withValues(
                                    alpha: 0.18,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.pakistanGreen.withValues(
                                      alpha: 0.18,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildFrameImage(
                                  frame.frameUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickNewImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;

    setState(() {
      _selectedImagePath = image.path;
    });
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Export Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.pakistanGreen,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildExportOption(
                      iconPath: AppAssets.downloadIcon,
                      label: 'Download',
                      onTap: () async {
                        _saveImage();
                      },
                    ),
                    _buildExportOption(
                      iconPath: AppAssets.shareIcon,
                      label: 'Share',
                      onTap: () async {
                        _shareImage();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportOption({
    required String iconPath,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                height: 30,
                width: 30,
                color: AppColors.pakistanGreen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 14, color: AppColors.pakistanGreen),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage() async {
    try {
      final Uint8List? imageData = await _capturePng();
      if (imageData != null) {
        if (await _requestPermissions()) {
          final result = await ImageGallerySaverPlus.saveImage(
            imageData,
            quality: 100,
            name: "edited_image_${DateTime.now().millisecondsSinceEpoch}",
          );

          if (result['filePath'] != null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image saved to gallery.')),
            );
          }
          final directory = await getExternalStorageDirectory();
          final path = '${directory?.path}/wedding_frames';
          await Directory(path).create(recursive: true);

          final filePath =
              '$path/wedding_frame_${DateTime.now().millisecondsSinceEpoch}.png';
          final file = File(filePath);
          await file.writeAsBytes(imageData);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save image.')));
    }
  }

  Future<void> _shareImage() async {
    try {
      final Uint8List? imageData = await _capturePng();
      if (imageData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/edited_image.png').create();
        await file.writeAsBytes(imageData);
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Check out this amazing frame!',
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error sharing image.')));
    }
  }

  Future<Uint8List?> _capturePng() async {
    try {
      RenderRepaintBoundary boundary =
          _captureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  Future<bool> _requestPermissions() async {
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) {
      return true;
    }

    final storage = await Permission.storage.request();
    return storage.isGranted;
  }

  void _addNewText() {
    setState(() {
      _textOverlays.add(
        TextOverlay(
          text: '',
          position: const Offset(100, 100),
          color: Colors.black,
          fontSize: 40,
          fontWeight: FontWeight.normal,
        ),
      );
    });
    _showEditTextDialog(_textOverlays.last);
  }

  void _deleteTextOverlay(TextOverlay overlay) {
    setState(() {
      _textOverlays.remove(overlay);
      if (_selectedTextOverlay == overlay) {
        _selectedTextOverlay = null;
      }
    });
  }

  final List<String> fontFamilies = [
    'Brista D',
    'Dandelion Harvest',
    'Hildany',
    'KLEPHON',
    'Talking',
    'Gridova Italic DEMO VERSION',
    'BellissaSignature',
    'CHOCOLATE D',
  ];

  void _showEditTextDialog(TextOverlay overlay) {
    final TextEditingController controller = TextEditingController(
      text: overlay.text,
    );
    double fontSize = overlay.fontSize;
    Color selectedColor = overlay.color;
    String selectedFont =
        overlay.fontFamily ?? fontFamilies.first; // Default font family

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(context).size.height *
                        0.8, // Limit dialog height
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text Input Field
                      TextField(
                        cursorColor: Colors.black,
                        controller: controller,
                        style: TextStyle(fontFamily: selectedFont),
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),

                          hintText: 'Write Text Here...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Font Picker
                      const Text(
                        'Pick a Font:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: fontFamilies.map((font) {
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedFont = font;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: selectedFont == font
                                      ? AppColors.pakistanGreen
                                      : Colors.grey.shade200,
                                ),
                                child: Text(
                                  'Aa',
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 18,
                                    color: selectedFont == font
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Font Size Control
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Text Size:',
                            style: TextStyle(fontSize: 14),
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    if (fontSize > 10) fontSize--;
                                  });
                                },
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                              ),
                              Text(
                                fontSize.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    if (fontSize < 100) fontSize++;
                                  });
                                },
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Color Picker
                      const Text('Color:', style: TextStyle(fontSize: 14)),
                      SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal, // Allow horizontal scrolling
                        child: Row(
                          children: [
                            _colorOption(Color(0xFFFF0000), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF0000),
                              ); // Red
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFF4000), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF4000),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFF8000), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF8000),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFFBF00), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFFBF00),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFFFF00), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFFFF00),
                              ); // Yellow
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFBFFF00), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFBFFF00),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF80FF00), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF80FF00),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF40FF00), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF40FF00),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF00FF00), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF00FF00),
                              ); // Green
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF00FF40), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF00FF40),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF00FF80), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF00FF80),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF00FFBF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF00FFBF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF00FFFF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF00FFFF),
                              ); // Cyan
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF00BFFF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF00BFFF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF0080FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF0080FF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF0040FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF0040FF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF0000FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF0000FF),
                              ); // Blue
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF4000FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF4000FF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFF8000FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFF8000FF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFBF00FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFBF00FF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFF00FF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF00FF),
                              ); // Magenta
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFF00BF), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF00BF),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFF0080), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF0080),
                              );
                            }),
                            const SizedBox(width: 8),
                            _colorOption(Color(0xFFFF0040), selectedColor, () {
                              setDialogState(
                                () => selectedColor = Color(0xFFFF0040),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions: Done and Cancel
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),

                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.pakistanGreen,
                            ),
                            onPressed: () {
                              setState(() {
                                overlay.text = controller.text;
                                overlay.fontSize = fontSize;
                                overlay.color = selectedColor;
                                overlay.fontFamily =
                                    selectedFont; // Save selected font family
                              });
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Done',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _colorOption(Color color, Color selectedColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: selectedColor == color
                ? Colors.blueAccent
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildTextOverlay(TextOverlay overlay) {
    return Positioned(
      left: overlay.position.dx,
      top: overlay.position.dy,
      child: GestureDetector(
        onTap: () {
          setState(() {
            // Toggle selection state
            _selectedTextOverlay = _selectedTextOverlay == overlay
                ? null
                : overlay;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            overlay.position += details.delta;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Text Content with Border
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedTextOverlay == overlay
                      ? Colors.black
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: RotationTransition(
                  turns: AlwaysStoppedAnimation(overlay.rotation / (2 * pi)),
                  child: Text(
                    overlay.text,
                    style: TextStyle(
                      color: overlay.color,
                      fontSize: overlay.fontSize,
                      fontWeight: overlay.fontWeight,
                      fontStyle: overlay.fontStyle,
                      fontFamily: overlay.fontFamily,
                    ),
                  ),
                ),
              ),
            ),

            // Control Buttons (shown only when selected)
            if (_selectedTextOverlay == overlay) ...[
              // Delete Button (Top-Left)
              Positioned(
                top: -15,
                left: -15,
                child: _cornerButton(Icons.delete, Colors.red, () {
                  _deleteTextOverlay(overlay);
                }),
              ),

              // Edit Button (Top-Right)
              Positioned(
                top: -15,
                right: -15,
                child: _cornerButton(Icons.edit, Colors.green, () {
                  _showEditTextDialog(overlay);
                }),
              ),

              // Rotation Button Gesture
              Positioned(
                bottom: -15,
                left: -15,
                child: GestureDetector(
                  onPanStart: (details) {
                    // Get the center of the overlay
                    final renderBox = context.findRenderObject() as RenderBox;
                    final Offset center = renderBox.globalToLocal(
                      overlay.position +
                          Offset(
                            renderBox.size.width / 2,
                            renderBox.size.height / 2,
                          ),
                    );

                    // Calculate the start angle relative to the center
                    overlay.rotationStartAngle = atan2(
                      details.globalPosition.dy - center.dy,
                      details.globalPosition.dx - center.dx,
                    );
                  },

                  onPanUpdate: (details) {
                    setState(() {
                      // Get the center of the overlay
                      final renderBox = context.findRenderObject() as RenderBox;
                      final Offset center = renderBox.globalToLocal(
                        overlay.position +
                            Offset(
                              renderBox.size.width / 2,
                              renderBox.size.height / 2,
                            ),
                      );

                      // Calculate the current angle relative to the center
                      final currentAngle = atan2(
                        details.globalPosition.dy - center.dy,
                        details.globalPosition.dx - center.dx,
                      );

                      // Update the overlay's rotation by the angle difference
                      overlay.rotation +=
                          currentAngle - overlay.rotationStartAngle;

                      // Update the start angle for continuous rotation
                      overlay.rotationStartAngle = currentAngle;
                    });
                  },

                  child: _cornerButton(Icons.rotate_right, Colors.blue, () {}),
                ),
              ),

              // Resize Button (Bottom-Right)
              Positioned(
                bottom: -15,
                right: -15,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Change font size based on horizontal or vertical delta
                      double change =
                          details.delta.dx.abs() > details.delta.dy.abs()
                          ? details.delta.dx
                          : details.delta.dy;
                      overlay.fontSize +=
                          change * 0.5; // Adjust the multiplier for speed
                      if (overlay.fontSize < 10) {
                        overlay.fontSize = 10; // Minimum size
                      }
                      if (overlay.fontSize > 100) {
                        overlay.fontSize = 100; // Maximum size
                      }
                    });
                  },
                  child: _cornerButton(Icons.open_with, Colors.orange, () {}),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cornerButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildFrameImage(String path, {required BoxFit fit}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: fit);
    }
    return Image.asset(path, fit: fit);
  }

  Future<void> _precacheSelectedFrame(String path) async {
    setState(() => _isFrameLoading = true);
    try {
      await precacheImage(AssetImage(path), context);

      if (!mounted || _selectedFramePath != path) return;
      setState(() {
        _isFrameLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFrameLoading = false;
      });
    }
  }
}

class IndependenceFrame {
  final String frameUrl;

  const IndependenceFrame(this.frameUrl);
}

class IndependenceFrameProvider extends ChangeNotifier {
  final Map<String, List<IndependenceFrame>> _frames = {};

  List<IndependenceFrame> getFrames(String categoryId) =>
      _frames[categoryId] ?? const [];

  Future<void> fetchFrames(String categoryId) async {
    _frames[categoryId] = AppAssets.frames
        .map((framePath) => IndependenceFrame(framePath))
        .toList(growable: false);
    notifyListeners();
  }
}

enum _EditorTool { none, editPhoto, frame, text, export }

class _EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onExport;

  const _EditorAppBar({required this.onExport});

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: Row(
          children: [
            _GlassCircleButton(
              tooltip: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Edit Frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Pinch, drag & rotate your photo',
                    style: TextStyle(
                      color: Color(0xDFFFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 28),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _GlassCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: AppColors.deepGreen.withValues(alpha: 0.38),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox(
                height: 42,
                width: 42,
                child: Icon(icon, color: Colors.white, size: 21),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TextOverlay {
  String text;
  Offset position;
  Color color;
  double fontSize;
  FontWeight fontWeight;
  FontStyle fontStyle;
  double rotation;
  double rotationStartAngle;
  String? fontFamily; // New property

  TextOverlay({
    required this.text,
    required this.position,
    this.color = Colors.black,
    this.fontSize = 25,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
    this.rotation = 0.0,
    this.rotationStartAngle = 0.0,
    this.fontFamily,
  });
}
