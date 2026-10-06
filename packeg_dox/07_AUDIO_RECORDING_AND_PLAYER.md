# 07 — Audio Recording & Waveform Player 🎙️

`nextgen_media_utility` comes with an audio subsystem for WhatsApp/Telegram-style voice messaging and audio playback.

---

## 1. Pulse-Animated Voice Recorder (`EnhancedAudioRecorder`)

Open the interactive voice recording bottom sheet:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

Future<void> recordVoiceNote(BuildContext context) async {
  final File? recordedAudio = await EnhancedAudioRecorder.show(
    context,
    maxDurationSeconds: 120, // Optional maximum recording time (e.g. 2 minutes)
  );

  if (recordedAudio != null) {
    print('Voice note recorded at: ${recordedAudio.path}');
  }
}
```

### Recorder Features:
* **Real-time Amplitude Waveform**: Live visualizer bars that bounce with the user's voice volume.
* **Duration Counter**: Formatted mm:ss counter.
* **Playback Preview**: Allows listening to the recording before deciding to send or discard.
* **Controls**: Pause, Resume, Trash/Discard, and Send/Confirm.

---

## 2. Interactive Waveform Audio Player (`AnimatedAudioPlayer`)

Play any local audio file or remote HTTP streaming URL with an animated scrubbing waveform:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

class AudioMessageBubble extends StatelessWidget {
  final File audioFile;

  const AudioMessageBubble({super.key, required this.audioFile});

  @override
  Widget build(BuildContext context) {
    return AnimatedAudioPlayer(
      filePath: audioFile.path, // Or pass a remote URL: 'https://example.com/audio.mp3'
      isLocal: true,
      accentColor: const Color(0xFF00E676), // Neon green or your app's brand color
      showWaveform: true,
      onPlaybackComplete: () {
        print('Finished playing audio');
      },
    );
  }
}
```

### Player Features:
* **Audio Sources**: Works with both local device files (`.m4a`, `.aac`, `.mp3`) and remote URLs.
* **Scrubbing Seekbar**: Drag across the waveform to jump forward/backward in the audio.
* **Compact Chat Mode**: Perfectly sized to drop inside a chat bubble widget.
