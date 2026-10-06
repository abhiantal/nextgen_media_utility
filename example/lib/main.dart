import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NextGenMediaExampleApp());
}

class NextGenMediaExampleApp extends StatelessWidget {
  const NextGenMediaExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NextGen Media Utility Demo',
      debugShowCheckedModeBanner: false,
      theme: MediaTheme.lightTheme(),
      darkTheme: MediaTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const MediaDemoHomeScreen(),
    );
  }
}

class MediaDemoHomeScreen extends StatefulWidget {
  const MediaDemoHomeScreen({super.key});

  @override
  State<MediaDemoHomeScreen> createState() => _MediaDemoHomeScreenState();
}

class _MediaDemoHomeScreenState extends State<MediaDemoHomeScreen> {
  final List<MediaAssetModel> _selectedMedia = [];

  void _openCamera() async {
    final result = await Navigator.push<CameraCaptureResult?>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );

    if (!mounted) return;
    if (result != null && result.files.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Captured ${result.files.length} media items!')),
      );
    }
  }

  void _openGallery() async {
    final result = await Navigator.push<List<MediaAssetModel>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const GalleryPickerScreen(allowMultiple: true),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _selectedMedia.addAll(result);
      });
    }
  }

  void _openAudioRecorder() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: EnhancedAudioRecorder(
          onCompleted: (file) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Audio recorded: ${file.name}')),
            );
          },
          onCanceled: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _openCompressionSheet() async {
    final picked = await Navigator.push<List<MediaAssetModel>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const GalleryPickerScreen(allowMultiple: false),
      ),
    );

    if (!mounted || picked == null || picked.isEmpty) return;

    final compressed = await MediaCompressionSheet.show(
      context,
      file: picked.first.file,
      isVideo: picked.first.type == MediaType.video,
    );

    if (compressed != null) {
      final oldSize = (await picked.first.file.length()) / 1024;
      final newSize = (await compressed.length()) / 1024;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compressed: ${oldSize.toStringAsFixed(0)} KB → ${newSize.toStringAsFixed(0)} KB!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NextGen Media Utility'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'All-in-One Flutter Media Suite',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Capture, pick, edit, record audio, and view media effortlessly.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Launch Custom Camera'),
              onPressed: _openCamera,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Open Gallery Picker'),
              onPressed: _openGallery,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic),
              label: const Text('Open Audio Recorder'),
              onPressed: _openAudioRecorder,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.compress_rounded),
              label: const Text('Custom Media Compressor'),
              onPressed: _openCompressionSheet,
            ),
            const SizedBox(height: 24),
            if (_selectedMedia.isNotEmpty) ...[
              const Text(
                'Selected Media:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    final item = _selectedMedia[index];
                    return ListTile(
                      leading: const Icon(Icons.image),
                      title: Text(item.file.path.split('/').last),
                      subtitle: Text('Type: ${item.type.name}'),
                    );
                  },
                ),
              ),
            ] else ...[
              const Spacer(),
              const Center(
                child: FuturisticLoadingIndicator(radius: 24),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('Ready for media operations', style: TextStyle(color: Colors.grey)),
              ),
              const Spacer(),
            ],
          ],
        ),
      ),
    );
  }
}
