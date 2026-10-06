# 08 — Media Display Grids & Fullscreen Viewer 📱

Displaying media in chat bubbles, social feeds, and profile galleries is effortless with `MediaDisplay` and `FullScreenViewer`.

---

## 1. Creating `MediaAsset` Objects

`MediaAsset` is the universal data model for all media items:

```dart
import 'dart:io';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

// From a local file
final localAsset = MediaAsset.fromFile(
  File('/path/to/image.jpg'),
  type: MediaType.image,
);

// From a remote network URL
final remoteAsset = MediaAsset.network(
  url: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119',
  type: MediaType.image,
  id: 'unique_id_123',
);
```

---

## 2. Using `MediaDisplay`

`MediaDisplay` automatically arranges multiple photos or videos into dynamic collages:

```dart
import 'package:flutter/material.dart';
import 'package:nextgen_media_utility/nextgen_media_utility.dart';

class PostMediaWidget extends StatelessWidget {
  final List<MediaAsset> assets;

  const PostMediaWidget({super.key, required this.assets});

  @override
  Widget build(BuildContext context) {
    return MediaDisplay(
      assets: assets,
      mode: MediaDisplayMode.grid, // .grid, .carousel, or .list
      maxGridItems: 4,             // Shows "+N more" badge if there are > 4 items
      onItemTap: (index, asset) {
        // Automatically opens FullScreenViewer, or provide a custom callback
      },
    );
  }
}
```

### Layout Modes:
* **`MediaDisplayMode.grid`**: Like Twitter / Facebook / WhatsApp feeds. Adapts intelligently for 1 item (full width), 2 items (half split), 3 items (hero top + 2 below), or 4+ items (2x2 grid with overlay counter).
* **`MediaDisplayMode.carousel`**: Horizontal swipeable cards with page dots.
* **`MediaDisplayMode.list`**: Vertical list with thumbnail, file name, and file size.

---

## 3. Fullscreen Zoom & Video Player

When a user taps an item in `MediaDisplay`, it launches `FullScreenViewer`:
* **Pinch to Zoom**: Zoom in up to 4x with fluid physics.
* **Swipe to Dismiss**: Flick down or up to close the viewer.
* **Video Controls**: Automatic video player with scrub bar, mute, and play/pause.
* **Save to Device Gallery**: Top-right download icon saves the image or video directly to the user's phone gallery using `gal`.
