# Global Cloud Sync Status Banner

`GlobalSyncStatusBanner` provides a smart, non-intrusive sliding notification when backends, databases, or network sockets drop connection.

---

## Proactive Grace Period & Background Auto-Retry

Transient drops (e.g., cell tower switching or socket refresh) are common on mobile devices. Showing an error instantly causes unnecessary anxiety.

`GlobalSyncStatusBanner`:
1. Waits through a **grace period** (default: 12 seconds).
2. Performs a **silent proactive background retry** in the meantime.
3. Only surfaces the banner if the connection issue persists.
4. Auto-dismisses when connectivity is restored!

---

## Basic Integration

```dart
// Place in your root Stack:
Stack(
  children: [
    child!,
    GlobalSyncStatusBanner(
      graceDuration: Duration(seconds: 12),
      onRetry: () async {
        await myDatabaseService.reconnect();
      },
    ),
  ],
)
```

---

## Broadcasting Status Updates

Update the state from your network listener, Supabase, Firebase, or PowerSync stream:

```dart
// Device is offline
SyncStatusController.update(ServerSyncState.offline);

// Backend paused or DNS lookup failed
SyncStatusController.update(ServerSyncState.serverPaused);

// Auth session expired
SyncStatusController.update(ServerSyncState.authExpired);

// Successfully connected
SyncStatusController.update(ServerSyncState.synced);
```

---

## Custom Configuration (`SyncBannerConfig`)

Customize all titles, subtitles, and explanations:

```dart
GlobalSyncStatusBanner(
  config: SyncBannerConfig(
    offlineTitle: 'No Internet Connection',
    offlineSubtitle: 'Edits are cached locally and will auto-sync.',
    serverPausedTitle: 'Server Maintenance',
    serverPausedSubtitle: 'We are currently performing routine upgrades.',
    localDataSafetyNote: 'Your work is safely preserved on this device.',
  ),
)
```
