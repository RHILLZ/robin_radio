import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/responsive/responsive.dart';
import '../../data/models/album.dart';
import '../../global/widgets/widgets.dart';
import '../app/app_controller.dart';

/// Enhanced albums view with responsive design system.
///
/// Demonstrates the use of the new responsive design components
/// to create adaptive layouts that work across mobile, tablet, and desktop.
class ResponsiveAlbumsView extends StatefulWidget {
  const ResponsiveAlbumsView({super.key});

  @override
  State<ResponsiveAlbumsView> createState() => _ResponsiveAlbumsViewState();
}

class _ResponsiveAlbumsViewState extends State<ResponsiveAlbumsView> {
  final RxString searchQuery = ''.obs;
  final Rx<List<Album>> filteredAlbums = Rx<List<Album>>([]);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final RxBool isSearchVisible = false.obs;
  Worker? _searchWorker;

  @override
  void initState() {
    super.initState();

    final controller = Get.find<AppController>();
    filteredAlbums.value = controller.albums;

    _searchWorker = ever(searchQuery, (query) {
      final controller = Get.find<AppController>();
      filteredAlbums.value = controller.searchAlbums(query);
    });

    _searchFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_searchFocusNode.hasFocus && searchQuery.value.isEmpty) {
      isSearchVisible.value = false;
    }
  }

  @override
  void dispose() {
    _searchWorker?.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GetBuilder<AppController>(
        builder: (controller) {
          if (searchQuery.value.isEmpty) {
            filteredAlbums.value = controller.albums;
          }

          if (controller.hasError) {
            return _buildErrorView(context, controller);
          }

          if (controller.isLoading) {
            return _buildLoadingView(context, controller);
          }

          if (controller.albums.isEmpty) {
            return _buildEmptyView(context);
          }

          return _buildResponsiveAlbumsView(context, controller);
        },
      );

  /// Builds the main responsive albums view with adaptive layout.
  Widget _buildResponsiveAlbumsView(
    BuildContext context,
    AppController controller,
  ) =>
      ResponsiveScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        adaptivePadding:
            false, // We'll handle padding manually for more control
        body: AdaptiveSafeArea(
          child: Column(
            children: [
              // Adaptive header with search
              _buildAdaptiveHeader(context),

              // Responsive spacing
              const AdaptiveSpacing(),

              // Main content with responsive layout
              Expanded(
                child: _buildAdaptiveContent(context, controller),
              ),
            ],
          ),
        ),
      );

  /// Builds an adaptive header that changes based on screen size.
  Widget _buildAdaptiveHeader(BuildContext context) => ResponsiveLayout(
        mobile: _buildMobileHeader,
        tablet: _buildTabletHeader,
        desktop: _buildDesktopHeader,
      );

  /// Mobile header with compact search bar.
  Widget _buildMobileHeader(BuildContext context) => AdaptiveContainer(
        mobilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AdaptiveText(
              'Albums',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Spacer(),
            IconButton(
              onPressed: () => isSearchVisible.value = !isSearchVisible.value,
              icon: const AdaptiveIcon(
                Icons.search,
                mobileSize: 24,
              ),
            ),
          ],
        ),
      );

  /// Tablet header with inline search.
  Widget _buildTabletHeader(BuildContext context) => AdaptiveContainer(
        tabletPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            AdaptiveText(
              'Albums',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const AdaptiveSpacing(
              direction: Axis.horizontal,
              tablet: 24,
            ),
            Expanded(
              child: _buildInlineSearchField(context),
            ),
          ],
        ),
      );

  /// Desktop header with expanded search and navigation.
  Widget _buildDesktopHeader(BuildContext context) => AdaptiveContainer(
        desktopPadding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          children: [
            AdaptiveText(
              'Music Library',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const AdaptiveSpacing(
              direction: Axis.horizontal,
              desktop: 32,
            ),
            Expanded(
              flex: 2,
              child: _buildInlineSearchField(context),
            ),
            const AdaptiveSpacing(
              direction: Axis.horizontal,
            ),
            _buildViewToggleButtons(context),
          ],
        ),
      );

  /// Builds an inline search field for larger screens.
  Widget _buildInlineSearchField(BuildContext context) => TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search albums...',
          prefixIcon: const AdaptiveIcon(Icons.search),
          suffixIcon: searchQuery.value.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    searchQuery.value = '';
                  },
                  icon: const AdaptiveIcon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              const ResponsiveValue<double>(
                mobile: 8,
                tablet: 12,
                desktop: 16,
              ).value(context),
            ),
          ),
        ),
        onChanged: (value) => searchQuery.value = value,
      );

  /// Builds view toggle buttons for desktop layout.
  Widget _buildViewToggleButtons(BuildContext context) => Row(
        children: [
          AdaptiveCard(
            desktopPadding: const EdgeInsets.all(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {}, // Toggle grid view
                  icon: const AdaptiveIcon(Icons.grid_view),
                  tooltip: 'Grid View',
                ),
                IconButton(
                  onPressed: () {}, // Toggle list view
                  icon: const AdaptiveIcon(Icons.view_list),
                  tooltip: 'List View',
                ),
              ],
            ),
          ),
        ],
      );

  /// Builds the main content with responsive grid layout.
  Widget _buildAdaptiveContent(
    BuildContext context,
    AppController controller,
  ) =>
      Obx(() {
        if (searchQuery.value.isNotEmpty && filteredAlbums.value.isEmpty) {
          return _buildEmptySearchResults(context);
        }

        return OrientationLayout(
          portrait: (context, orientation) => _buildPortraitContent(context),
          landscape: (context, orientation) => _buildLandscapeContent(context),
        );
      });

  /// Builds content optimized for portrait orientation.
  Widget _buildPortraitContent(BuildContext context) => ResponsiveGrid(
        padding: EdgeInsets.all(context.responsivePadding),
        spacing: const ResponsiveValue<double>(
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ).value(context),
        mobileColumns: 2,
        tabletColumns: 3,
        desktopColumns: 4,
        children: filteredAlbums.value.map(_buildAlbumCard).toList(),
      );

  /// Builds content optimized for landscape orientation.
  Widget _buildLandscapeContent(BuildContext context) => ResponsiveGrid(
        padding: EdgeInsets.all(context.responsivePadding),
        spacing: const ResponsiveValue<double>(
          mobile: 12,
          tablet: 16,
          desktop: 20,
        ).value(context),
        mobileColumns: 3,
        tabletColumns: 4,
        desktopColumns: 6,
        children: filteredAlbums.value.map(_buildAlbumCard).toList(),
      );

  /// Builds an adaptive album card.
  Widget _buildAlbumCard(Album album) => AdaptiveCard(
        desktopElevation: 6,
        child: AlbumCardWidget(
          key: ValueKey(album.id),
          album: album,
          onTap: () => Get.find<AppController>().openTrackList(album),
        ),
      );

  /// Builds empty search results view.
  Widget _buildEmptySearchResults(BuildContext context) => Center(
        child: AdaptiveContainer(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AdaptiveIcon(
                Icons.search_off,
                mobileSize: 48,
                tabletSize: 64,
                desktopSize: 80,
                color: Theme.of(context).dividerColor,
              ),
              const AdaptiveSpacing(
                mobile: 16,
                tablet: 20,
                desktop: 24,
              ),
              AdaptiveText(
                'No Results Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const AdaptiveSpacing(),
              AdaptiveText(
                'No albums match "${searchQuery.value}"',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  /// Builds error view with responsive layout.
  Widget _buildErrorView(BuildContext context, AppController controller) =>
      ResponsiveScaffold(
        body: Center(
          child: AdaptiveContainer(
            child: ErrorStateWidget(
              title: 'Error Loading Albums',
              message: controller.errorMessage,
              onRetry: () => controller.refreshMusic(),
            ),
          ),
        ),
      );

  /// Builds loading view with responsive layout.
  Widget _buildLoadingView(BuildContext context, AppController controller) =>
      ResponsiveScaffold(
        body: Center(
          child: LoadingStateWidget(
            title: 'Loading Albums',
            message: controller.loadingStatusMessage,
            progress: controller.loadingProgress,
          ),
        ),
      );

  /// Builds empty state view with responsive layout.
  Widget _buildEmptyView(BuildContext context) => const ResponsiveScaffold(
        body: Center(
          child: AdaptiveContainer(
            child: EmptyStateWidget(
              title: 'No Albums',
              message: 'No albums available',
              icon: Icons.library_music,
            ),
          ),
        ),
      );
}
