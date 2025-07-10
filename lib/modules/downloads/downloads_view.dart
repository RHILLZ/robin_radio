import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/responsive/responsive.dart';
import '../../data/models/download_item.dart';
import '../../data/models/offline_song.dart';
import '../../data/services/download_manager.dart';
import '../../data/services/offline_storage_service.dart';
import '../../global/widgets/widgets.dart';

/// Downloads management view for Robin Radio.
///
/// This view provides a comprehensive interface for managing music downloads
/// and offline content. It features a tabbed interface with three main sections:
/// active downloads, download history, and offline songs management.
///
/// Features:
/// - Active downloads tab with real-time progress tracking
/// - Download history showing completed, failed, and cancelled downloads
/// - Offline songs management with storage information
/// - Download queue management with pause/resume/cancel controls
/// - Storage usage monitoring and cleanup options
/// - Responsive grid layout that adapts to different screen sizes
/// - Comprehensive error handling and user feedback
class DownloadsView extends StatefulWidget {
  /// Creates an instance of [DownloadsView].
  ///
  /// The [key] parameter is optional and follows standard Flutter widget conventions.
  const DownloadsView({super.key});

  @override
  State<DownloadsView> createState() => _DownloadsViewState();
}

class _DownloadsViewState extends State<DownloadsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DownloadManager _downloadManager;
  late OfflineStorageService _storageService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _downloadManager = Get.find<DownloadManager>();
    _storageService = Get.find<OfflineStorageService>();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(
          title: const AdaptiveText('Downloads'),
          actions: [
            IconButton(
              onPressed: _showStorageInfo,
              icon: const AdaptiveIcon(Icons.storage),
              tooltip: 'Storage Info',
            ),
            PopupMenuButton<String>(
              icon: const AdaptiveIcon(Icons.more_vert),
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: AdaptiveText('Clear Completed'),
                ),
                const PopupMenuItem(
                  value: 'clear_all_offline',
                  child: AdaptiveText('Clear All Offline'),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Active', icon: Icon(Icons.download)),
              Tab(text: 'History', icon: Icon(Icons.history)),
              Tab(text: 'Offline', icon: Icon(Icons.offline_pin)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveDownloadsTab(),
            _buildDownloadHistoryTab(),
            _buildOfflineSongsTab(),
          ],
        ),
      );

  /// Builds the active downloads tab.
  Widget _buildActiveDownloadsTab() => Obx(() {
        final activeDownloads = _downloadManager.activeDownloads;
        final queuedDownloads = _downloadManager.downloadQueue;
        final allActiveItems = [...activeDownloads, ...queuedDownloads];

        if (allActiveItems.isEmpty) {
          return const Center(
            child: AdaptiveContainer(
              child: EmptyStateWidget(
                title: 'No Active Downloads',
                message: 'Downloads will appear here when active',
                icon: Icons.download_outlined,
              ),
            ),
          );
        }

        return ResponsiveGrid(
          padding: EdgeInsets.all(context.responsivePadding),
          spacing: 12,
          mobileColumns: 1,
          tabletColumns: 1,
          desktopColumns: 2,
          children: allActiveItems.map(_buildDownloadItemCard).toList(),
        );
      });

  /// Builds the download history tab.
  Widget _buildDownloadHistoryTab() => Obx(() {
        final allDownloads = _downloadManager.allDownloads
            .where(
              (item) =>
                  item.status == DownloadStatus.completed ||
                  item.status == DownloadStatus.failed ||
                  item.status == DownloadStatus.cancelled,
            )
            .toList();

        if (allDownloads.isEmpty) {
          return const Center(
            child: AdaptiveContainer(
              child: EmptyStateWidget(
                title: 'No Download History',
                message: 'Completed downloads will appear here',
                icon: Icons.history_outlined,
              ),
            ),
          );
        }

        return ResponsiveGrid(
          padding: EdgeInsets.all(context.responsivePadding),
          spacing: 12,
          mobileColumns: 1,
          tabletColumns: 1,
          desktopColumns: 2,
          children: allDownloads.map(_buildDownloadItemCard).toList(),
        );
      });

  /// Builds the offline songs tab.
  Widget _buildOfflineSongsTab() {
    final offlineSongs = _storageService.getAllOfflineSongs();

    if (offlineSongs.isEmpty) {
      return const Center(
        child: AdaptiveContainer(
          child: EmptyStateWidget(
            title: 'No Offline Songs',
            message: 'Downloaded songs will appear here',
            icon: Icons.offline_pin_outlined,
          ),
        ),
      );
    }

    return ResponsiveGrid(
      padding: EdgeInsets.all(context.responsivePadding),
      spacing: 12,
      mobileColumns: 1,
      tabletColumns: 1,
      desktopColumns: 2,
      children: offlineSongs.map(_buildOfflineSongCard).toList(),
    );
  }

  /// Builds a card for a download item.
  Widget _buildDownloadItemCard(DownloadItem item) => AdaptiveCard(
        child: ListTile(
          leading: _buildDownloadStatusIcon(item.status),
          title: AdaptiveText(
            item.songName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdaptiveText(item.artist),
              const AdaptiveSpacing(mobile: 4),
              _buildProgressIndicator(item),
            ],
          ),
          trailing: _buildDownloadActions(item),
          isThreeLine: true,
        ),
      );

  /// Builds a card for an offline song.
  Widget _buildOfflineSongCard(OfflineSong offlineSong) => AdaptiveCard(
        child: ListTile(
          leading: const AdaptiveIcon(
            Icons.offline_pin,
            color: Colors.green,
          ),
          title: AdaptiveText(
            offlineSong.songName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdaptiveText(offlineSong.artist),
              if (offlineSong.albumName != null)
                AdaptiveText(
                  offlineSong.albumName!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              AdaptiveText(
                'Downloaded: ${_formatDate(offlineSong.downloadDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            icon: const AdaptiveIcon(Icons.more_vert),
            onSelected: (action) =>
                _handleOfflineSongAction(action, offlineSong),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
          isThreeLine: true,
        ),
      );

  /// Builds the download status icon.
  Widget _buildDownloadStatusIcon(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.pending:
        return const AdaptiveIcon(Icons.schedule, color: Colors.orange);
      case DownloadStatus.downloading:
        return const AdaptiveIcon(Icons.download, color: Colors.blue);
      case DownloadStatus.completed:
        return const AdaptiveIcon(Icons.check_circle, color: Colors.green);
      case DownloadStatus.failed:
        return const AdaptiveIcon(Icons.error, color: Colors.red);
      case DownloadStatus.paused:
        return const AdaptiveIcon(Icons.pause_circle, color: Colors.grey);
      case DownloadStatus.cancelled:
        return const AdaptiveIcon(Icons.cancel, color: Colors.grey);
    }
  }

  /// Builds the progress indicator for a download item.
  Widget _buildProgressIndicator(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: item.progress),
            const AdaptiveSpacing(mobile: 2),
            AdaptiveText(
              '${(item.progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      case DownloadStatus.completed:
        return AdaptiveText(
          'Download completed',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
              ),
        );
      case DownloadStatus.failed:
        return AdaptiveText(
          'Failed: ${item.errorMessage ?? "Unknown error"}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.red,
              ),
        );
      case DownloadStatus.pending:
        return AdaptiveText(
          'Waiting to download...',
          style: Theme.of(context).textTheme.bodySmall,
        );
      case DownloadStatus.paused:
        return AdaptiveText(
          'Paused at ${(item.progress * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodySmall,
        );
      case DownloadStatus.cancelled:
        return AdaptiveText(
          'Cancelled',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        );
    }
  }

  /// Builds the action buttons for a download item.
  Widget _buildDownloadActions(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.downloading:
        return IconButton(
          onPressed: () => _downloadManager.pauseDownload(item.id),
          icon: const AdaptiveIcon(Icons.pause),
          tooltip: 'Pause',
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _downloadManager.resumeDownload(item.id),
              icon: const AdaptiveIcon(Icons.play_arrow),
              tooltip: 'Resume',
            ),
            IconButton(
              onPressed: () => _downloadManager.cancelDownload(item.id),
              icon: const AdaptiveIcon(Icons.close),
              tooltip: 'Cancel',
            ),
          ],
        );
      case DownloadStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _downloadManager.retryDownload(item.id),
              icon: const AdaptiveIcon(Icons.refresh),
              tooltip: 'Retry',
            ),
            IconButton(
              onPressed: () => _downloadManager.removeDownloadItem(item.id),
              icon: const AdaptiveIcon(Icons.delete),
              tooltip: 'Remove',
            ),
          ],
        );
      case DownloadStatus.pending:
        return IconButton(
          onPressed: () => _downloadManager.cancelDownload(item.id),
          icon: const AdaptiveIcon(Icons.close),
          tooltip: 'Cancel',
        );
      case DownloadStatus.completed:
      case DownloadStatus.cancelled:
        return IconButton(
          onPressed: () => _downloadManager.removeDownloadItem(item.id),
          icon: const AdaptiveIcon(Icons.delete),
          tooltip: 'Remove',
        );
    }
  }

  /// Handles menu actions.
  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_completed':
        _downloadManager.clearDownloadHistory();
        break;
      case 'clear_all_offline':
        _showClearAllOfflineDialog();
        break;
    }
  }

  /// Handles offline song actions.
  void _handleOfflineSongAction(String action, OfflineSong offlineSong) {
    switch (action) {
      case 'delete':
        _showDeleteOfflineSongDialog(offlineSong);
        break;
    }
  }

  /// Shows storage information dialog.
  Future<void> _showStorageInfo() async {
    final totalSize = await _storageService.getTotalStorageUsed();
    final formattedSize = _formatBytes(totalSize);
    final songCount = _storageService.getAllOfflineSongs().length;

    await Get.dialog<void>(
      AlertDialog(
        title: const AdaptiveText('Storage Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdaptiveText('Total offline songs: $songCount'),
            const AdaptiveSpacing(),
            AdaptiveText('Storage used: $formattedSize'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Get.back<void>,
            child: const AdaptiveText('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog for clearing all offline data.
  void _showClearAllOfflineDialog() {
    Get.dialog<void>(
      AlertDialog(
        title: const AdaptiveText('Clear All Offline Data'),
        content: const AdaptiveText(
          'This will delete all downloaded songs and clear all offline data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: Get.back<void>,
            child: const AdaptiveText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              _storageService.clearAllOfflineData();
            },
            child: const AdaptiveText(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows confirmation dialog for deleting an offline song.
  void _showDeleteOfflineSongDialog(OfflineSong offlineSong) {
    Get.dialog<void>(
      AlertDialog(
        title: const AdaptiveText('Delete Offline Song'),
        content: AdaptiveText(
          'Delete "${offlineSong.songName}" from offline storage?',
        ),
        actions: [
          TextButton(
            onPressed: Get.back<void>,
            child: const AdaptiveText('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back<void>();
              _storageService.deleteOfflineSong(offlineSong.id);
            },
            child: const AdaptiveText(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a DateTime to a readable string.
  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  /// Formats bytes into human-readable format.
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
