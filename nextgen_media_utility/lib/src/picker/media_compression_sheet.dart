// ============================================================
// FILE: lib/src/picker/media_compression_sheet.dart
// Interactive Media Compression Customization Sheet
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:video_compress/video_compress.dart';
import '../core/media_loading_indicator.dart';
import '../core/media_theme.dart';
import 'media_picker.dart';

enum CompressionPreset {
  low('Compact (Low Data)', 35, 720),
  balanced('Balanced (Recommended)', 65, 1080),
  high('High Detail', 85, 1920),
  custom('Custom', 70, 1080);

  final String label;
  final int defaultQuality;
  final int defaultDimension;
  const CompressionPreset(this.label, this.defaultQuality, this.defaultDimension);
}

class MediaCompressionSheet extends StatefulWidget {
  final File file;
  final bool isVideo;

  const MediaCompressionSheet({
    super.key,
    required this.file,
    this.isVideo = false,
  });

  static Future<File?> show(
    BuildContext context, {
    required File file,
    bool isVideo = false,
  }) {
    return showModalBottomSheet<File?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaCompressionSheet(file: file, isVideo: isVideo),
    );
  }

  @override
  State<MediaCompressionSheet> createState() => _MediaCompressionSheetState();
}

class _MediaCompressionSheetState extends State<MediaCompressionSheet> {
  late CompressionPreset _preset;
  late double _quality;
  late int _maxDimension;

  int _originalSizeBytes = 0;
  int? _compressedSizeBytes;
  bool _isCompressing = false;
  File? _compressedFile;

  @override
  void initState() {
    super.initState();
    _preset = CompressionPreset.balanced;
    _quality = _preset.defaultQuality.toDouble();
    _maxDimension = _preset.defaultDimension;
    _loadFileStats();
  }

  Future<void> _loadFileStats() async {
    if (await widget.file.exists()) {
      final size = await widget.file.length();
      if (mounted) setState(() => _originalSizeBytes = size);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _applyPreset(CompressionPreset preset) {
    setState(() {
      _preset = preset;
      if (preset != CompressionPreset.custom) {
        _quality = preset.defaultQuality.toDouble();
        _maxDimension = preset.defaultDimension;
      }
    });
  }

  Future<void> _executeCompression() async {
    setState(() => _isCompressing = true);

    try {
      if (widget.isVideo) {
        VideoQuality vq = VideoQuality.MediumQuality;
        if (_quality < 45) {
          vq = VideoQuality.LowQuality;
        } else if (_quality > 75) {
          vq = VideoQuality.DefaultQuality;
        }

        final result = await EnhancedMediaCompressor.compressVideo(
          widget.file,
          quality: vq,
          force: true,
        );

        if (result != null && await result.exists()) {
          final size = await result.length();
          if (mounted) {
            setState(() {
              _compressedFile = result;
              _compressedSizeBytes = size;
            });
          }
        }
      } else {
        final result = await EnhancedMediaCompressor.compressImage(
          widget.file,
          quality: _quality.toInt(),
          minWidth: _maxDimension,
          minHeight: _maxDimension,
          fixRotation: true,
        );

        if (result != null && await result.exists()) {
          final size = await result.length();
          if (mounted) {
            setState(() {
              _compressedFile = result;
              _compressedSizeBytes = size;
            });
          }
        }
      }
    } finally {
      if (mounted) setState(() => _isCompressing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fileName = path.basename(widget.file.path);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  widget.isVideo ? Icons.video_file_rounded : Icons.image_rounded,
                  color: MediaTheme.primaryNeon,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Compress Media',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // Size comparison card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Original Size', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        _formatSize(_originalSizeBytes),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 20),
                  Column(
                    children: [
                      const Text('Target Output', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        _compressedSizeBytes != null
                            ? _formatSize(_compressedSizeBytes!)
                            : '~${_formatSize((_originalSizeBytes * (_quality / 100) * 0.7).toInt())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _compressedSizeBytes != null ? MediaTheme.primaryNeon : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Preset options
            const Text('Compression Presets', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CompressionPreset.values.map((preset) {
                final isSelected = _preset == preset;
                return ChoiceChip(
                  label: Text(preset.label),
                  selected: isSelected,
                  selectedColor: MediaTheme.primaryNeon.withValues(alpha: 0.25),
                  onSelected: (selected) {
                    if (selected) _applyPreset(preset);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom quality slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quality Level', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('${_quality.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _quality,
              min: 15,
              max: 95,
              divisions: 16,
              activeColor: MediaTheme.primaryNeon,
              onChanged: (val) {
                setState(() {
                  _quality = val;
                  _preset = CompressionPreset.custom;
                });
              },
            ),

            if (!widget.isVideo) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Max Resolution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${_maxDimension}px', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 720, label: Text('720p')),
                  ButtonSegment(value: 1080, label: Text('1080p')),
                  ButtonSegment(value: 1920, label: Text('Full HD')),
                ],
                selected: {_maxDimension},
                onSelectionChanged: (set) {
                  setState(() {
                    _maxDimension = set.first;
                    _preset = CompressionPreset.custom;
                  });
                },
              ),
            ],

            const SizedBox(height: 24),

            if (_isCompressing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: FuturisticLoadingIndicator(radius: 18),
                ),
              )
            else if (_compressedFile != null)
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Use Compressed File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.pop(context, _compressedFile),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.compress_rounded),
                label: const Text('Compress Media'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MediaTheme.primaryNeon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _executeCompression,
              ),
          ],
        ),
      ),
    );
  }
}
