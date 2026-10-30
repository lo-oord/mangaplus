import 'dart:async';

import 'package:flutter/material.dart';

import 'manga_time_service.dart';

const navy = Color(0xFF0B111A);
const surface = Color(0xFF121C29);
const surface2 = Color(0xFF1A293B);
const surface3 = Color(0xFF22364B);
const accent = Color(0xFF75B7FF);
const teal = Color(0xFF65DED5);
const muted = Color(0xFF91A2B5);
const inkText = Color(0xFFF4F7FB);
const danger = Color(0xFFFF7474);
final ValueNotifier<bool> appDarkMode = ValueNotifier<bool>(true);

Image mangaImage(String source, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
  final ImageProvider<Object> provider = source.startsWith('http')
      ? NetworkImage(source) as ImageProvider<Object>
      : AssetImage(source) as ImageProvider<Object>;
  return Image(image: provider, fit: fit, width: width, height: height);
}

String ratingLabel(double rating) => rating > 0 ? rating.toStringAsFixed(1) : '—';

class MangaItem {
  final String id;
  final String slug;
  final String type;
  String title;
  String subtitle;
  String asset;
  String description;
  String status;
  int chapters;
  List<String> tags;
  String author;
  String updated;
  double rating;
  String latestChapterNumber;
  DateTime? latestDate;
  String sourceName = '';
  String sourceLogo = '';
  bool favorite;
  List<MangaTimeChapter> remoteChapters = [];

  MangaItem.remote(MangaTimeSeries series)
      : id = series.id,
        slug = series.slug,
        type = series.type,
        title = series.title,
        subtitle = series.nameEn,
        asset = series.coverUrl,
        description = series.description,
        status = series.status,
        chapters = series.chapterCount,
        tags = series.genres,
        author = '',
        updated = mangaTimeRelativeDate(series.latestDate),
        rating = series.rating,
        latestChapterNumber = series.latestChapter ?? '',
        latestDate = series.latestDate,
        favorite = false;

  String get key => slug.isNotEmpty ? slug : id;

  void updateFrom(MangaTimeSeries series) {
    title = series.title;
    subtitle = series.nameEn;
    asset = series.coverUrl;
    description = series.description;
    status = series.status;
    chapters = series.chapterCount;
    tags = series.genres;
    rating = series.rating;
    if (series.latestChapter != null && series.latestChapter!.isNotEmpty) {
      latestChapterNumber = series.latestChapter!;
    }
    if (series.latestDate != null) {
      latestDate = series.latestDate;
      updated = mangaTimeRelativeDate(series.latestDate);
    }
  }
}

final manga = <MangaItem>[];

enum Page { latest, manga, favorites, storage, notifications, settings, about }

enum DownloadStatus { idle, queued, downloading, success, failed }

class ChapterRecord {
  DownloadStatus download = DownloadStatus.idle;
  bool read = false;
}

class DownloadTask {
  final MangaItem item;
  final List<int> chapters;
  DownloadStatus status = DownloadStatus.queued;
  double progress = 0;
  Timer? timer;

  DownloadTask(this.item, this.chapters);

  bool get done =>
      status == DownloadStatus.success || status == DownloadStatus.failed;

  String get label => '${chapters.length} فصل من ${item.title}';
}

class MangaPlusApp extends StatelessWidget {
  const MangaPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: appDarkMode,
      builder: (context, dark, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manga Plus',
        theme: ThemeData(
          useMaterial3: true,
          brightness: dark ? Brightness.dark : Brightness.light,
          scaffoldBackgroundColor: dark ? navy : const Color(0xFFF5F7FB),
          colorScheme: ColorScheme.fromSeed(
            seedColor: accent,
            brightness: dark ? Brightness.dark : Brightness.light,
            surface: dark ? surface : Colors.white,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: dark ? navy : const Color(0xFFF5F7FB),
            foregroundColor: dark ? inkText : const Color(0xFF152033),
            elevation: 0,
            centerTitle: false,
          ),
          dividerColor: dark ? surface3 : const Color(0xFFE3E8F0),
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: dark ? inkText : const Color(0xFF152033), height: 1.45),
            bodyMedium: TextStyle(color: dark ? muted : const Color(0xFF627085), height: 1.45),
            titleLarge: TextStyle(color: dark ? inkText : const Color(0xFF152033), fontWeight: FontWeight.w800),
          ),
        ),
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Splash(),
      ),
    );
  }
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Shell()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _logo(118),
            const SizedBox(height: 18),
            const Text(
              'MANGA PLUS',
              style: TextStyle(
                color: navy,
                letterSpacing: 3.2,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _logo(double size) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(size * .22),
    child: Container(
      width: size,
      height: size,
      color: Colors.white,
      child: Image.asset('assets/app_logo.png', fit: BoxFit.contain),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? action;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description = 'ستظهر محتوياتك هنا عندما تصبح جاهزة.',
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: accent.withOpacity(.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: accent),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OfflineState extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflineState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'لا يتوفر اتصال بالإنترنت',
      description: 'تحقق من الشبكة ثم أعد المحاولة للوصول إلى آخر التحديثات.',
      action: 'إعادة المحاولة',
      onAction: onRetry,
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Page page = Page.latest;
  MangaItem? selected;
  bool compact = false;
  bool notifications = true;
  bool wifiOnly = false;
  bool online = true;
  bool chaptersDescending = true;
  final Map<String, Map<int, ChapterRecord>> records = {};
  final List<DownloadTask> tasks = [];
  final MangaTimeService source = MangaTimeService();
  List<MangaItem> latestItems = [];
  List<MangaItem> catalogItems = [];
  bool sourceLoading = true;
  String? sourceError;
  int latestPage = 1;
  int catalogPage = 1;
  bool latestHasMore = true;
  bool catalogHasMore = true;
  bool loadingMore = false;
  bool searching = false;
  String searchQuery = '';
  List<MangaItem> remoteSearchItems = [];
  bool searchLoading = false;
  Timer? searchDebounce;
  Color themeColor = accent;

  @override
  void initState() {
    super.initState();
    refreshSource();
  }

  Future<void> refreshSource() async {
    if (mounted) setState(() { sourceLoading = true; sourceError = null; });
    try {
      final results = await Future.wait([
        source.searchSeries(sortBy: 'recent'),
        source.searchSeries(sortBy: 'popularity'),
      ]);
      final existing = {for (final item in manga) item.key: item};
      final canonical = <String, MangaItem>{};
      MangaItem mapSeries(MangaTimeSeries series) {
        final item = existing[series.slug] ?? MangaItem.remote(series);
        item.updateFrom(series);
        return canonical.putIfAbsent(item.key, () => item);
      }
      final latest = results[0].map(mapSeries).toList();
      final catalog = results[1].map(mapSeries).toList();
      manga
        ..clear()
        ..addAll(canonical.values);
      if (!mounted) return;
      setState(() {
        latestItems = latest;
        catalogItems = catalog;
        latestPage = 1;
        catalogPage = 1;
        latestHasMore = results[0].length >= 24;
        catalogHasMore = results[1].length >= 24;
        sourceLoading = false;
      });
      await restoreDownloads();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        sourceLoading = false;
        sourceError = error.toString();
      });
    }
  }

  Future<void> restoreDownloads() async {
    final entries = await source.readDownloadedManifest();
    for (final entry in entries) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      MangaItem? item;
      for (final candidate in manga) {
        if (candidate.slug == parts[0]) {
          item = candidate;
          break;
        }
      }
      final number = int.tryParse(parts[1]);
      if (item != null && number != null) {
        recordFor(item, number).download = DownloadStatus.success;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> loadMore(Page target) async {
    if (sourceLoading || loadingMore || searchQuery.trim().isNotEmpty) return;
    final isLatest = target == Page.latest;
    if (isLatest ? !latestHasMore : !catalogHasMore) return;
    setState(() => loadingMore = true);
    try {
      final nextPage = (isLatest ? latestPage : catalogPage) + 1;
      final response = await source.searchSeries(
        sortBy: isLatest ? 'recent' : 'popularity',
        page: nextPage,
      );
      final existing = {for (final item in manga) item.key: item};
      final targetKeys = (isLatest ? latestItems : catalogItems).map((item) => item.key).toSet();
      final additions = <MangaItem>[];
      for (final series in response) {
        final item = existing[series.slug] ?? MangaItem.remote(series);
        item.updateFrom(series);
        if (!existing.containsKey(item.key)) {
          existing[item.key] = item;
          manga.add(item);
        }
        if (targetKeys.add(item.key)) additions.add(item);
      }
      if (mounted) {
        setState(() {
          if (isLatest) {
            latestItems = [...latestItems, ...additions];
            latestPage = nextPage;
            latestHasMore = response.length >= 24;
          } else {
            catalogItems = [...catalogItems, ...additions];
            catalogPage = nextPage;
            catalogHasMore = response.length >= 24;
          }
          loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  Map<int, ChapterRecord> recordsFor(MangaItem item) =>
      records.putIfAbsent(item.title, () => {});

  ChapterRecord recordFor(MangaItem item, int number) =>
      recordsFor(item).putIfAbsent(number, ChapterRecord.new);

  List<int> downloadedFor(MangaItem item) => recordsFor(item)
      .entries
      .where((entry) => entry.value.download == DownloadStatus.success)
      .map((entry) => entry.key)
      .toList()
    ..sort((a, b) => b.compareTo(a));

  void enqueueDownload(MangaItem item, List<int> numbers) {
    final chapters = numbers.toSet().toList()..sort((a, b) => b.compareTo(a));
    if (chapters.isEmpty) return;
    final task = DownloadTask(item, chapters);
    setState(() {
      tasks.insert(0, task);
      for (final number in chapters) {
        recordFor(item, number).download = DownloadStatus.downloading;
      }
      task.status = DownloadStatus.downloading;
    });
    _downloadTask(task, item, chapters);
  }

  Future<void> _downloadTask(DownloadTask task, MangaItem item, List<int> chapters) async {
    try {
      if (!online) throw StateError('لا يوجد اتصال');
      await source.downloadChapters(
        slug: item.slug,
        chapterNumbers: chapters.map((number) => number.toString()).toList(),
        onProgress: (progress) {
          if (!mounted) return;
          setState(() => task.progress = progress);
        },
      );
      if (!mounted) return;
      await source.markDownloaded(item.slug, chapters.map((number) => number.toString()).toList());
      setState(() {
        task.status = DownloadStatus.success;
        task.progress = 1;
        for (final number in chapters) {
          recordFor(item, number).download = DownloadStatus.success;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        task.status = DownloadStatus.failed;
        for (final number in chapters) {
          recordFor(item, number).download = DownloadStatus.failed;
        }
      });
    }
  }

  void setRead(MangaItem item, List<int> numbers, bool value) => setState(() {
        for (final number in numbers) {
          recordFor(item, number).read = value;
        }
      });

  String get title {
    if (selected != null) return selected!.title;
    return switch (page) {
      Page.latest => 'الأحدث',
      Page.manga => 'استكشف',
      Page.favorites => 'المفضلة',
      Page.storage => 'التخزين',
      Page.notifications => 'التحميلات',
      Page.settings => 'الإعدادات',
      Page.about => 'حول التطبيق',
    };
  }

  List<MangaItem> ordered(List<MangaItem> items) {
    final result = [...items];
    result.sort(
      (a, b) => chaptersDescending
          ? b.chapters.compareTo(a.chapters)
          : a.chapters.compareTo(b.chapters),
    );
    return result;
  }

  void open(Page nextPage) {
    setState(() {
      page = nextPage;
      selected = null;
      searching = false;
      searchQuery = '';
      remoteSearchItems = [];
    });
  }

  bool get canSearch =>
      page == Page.latest || page == Page.manga || page == Page.favorites;

  List<MangaItem> filtered(List<MangaItem> source) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) return source;
    return source
        .where((item) =>
            item.title.toLowerCase().contains(query) ||
            item.subtitle.toLowerCase().contains(query))
        .toList();
  }

  void updateSearch(String value) {
    setState(() {
      searchQuery = value;
      if (value.trim().isEmpty) remoteSearchItems = [];
    });
    if (page == Page.favorites || value.trim().length < 2) return;
    searchDebounce?.cancel();
    searchDebounce = Timer(const Duration(milliseconds: 380), () => searchRemote(value.trim()));
  }

  Future<void> searchRemote(String query) async {
    if (!mounted) return;
    setState(() => searchLoading = true);
    try {
      final result = await source.searchSeries(sortBy: 'popularity', query: query);
      final existing = {for (final item in manga) item.key: item};
      final mapped = result.map((series) {
        final item = existing[series.slug] ?? MangaItem.remote(series);
        item.updateFrom(series);
        return item;
      }).toList();
      if (mounted && searchQuery.trim() == query) {
        setState(() => remoteSearchItems = mapped);
      }
    } finally {
      if (mounted) setState(() => searchLoading = false);
    }
  }

  @override
  void dispose() {
    searchDebounce?.cancel();
    source.close();
    super.dispose();
  }

  void showSortMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ترتيب المانجا',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 4),
              const Text(
                'غيّر طريقة عرض العناوين في هذه الصفحة.',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              _sortOption(
                icon: Icons.auto_awesome_rounded,
                title: 'الأحدث أولًا',
                selected: chaptersDescending,
                onTap: () {
                  setState(() => chaptersDescending = true);
                  Navigator.pop(context);
                },
              ),
              _sortOption(
                icon: Icons.sort_rounded,
                title: 'الأقل فصولًا أولًا',
                selected: !chaptersDescending,
                onTap: () {
                  setState(() => chaptersDescending = false);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortOption({
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: selected ? accent : muted),
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: teal)
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDetails = selected != null;
    return Scaffold(
      drawer: hasDetails ? null : drawer(),
      appBar: hasDetails ? null : _appBar(),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey('${page.name}-${selected?.title ?? 'root'}'),
          child: hasDetails
              ? Details(
                  item: selected!,
                  source: source,
                  records: recordsFor(selected!),
                  downloadedOnly: page == Page.storage,
                  back: () => setState(() => selected = null),
                  changed: () => setState(() {}),
                  onDownload: (numbers) => enqueueDownload(selected!, numbers),
                  onRead: (numbers, value) =>
                      setRead(selected!, numbers, value),
                )
              : body(),
        ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    if (searching) {
      return AppBar(
        toolbarHeight: 64,
        leading: IconButton(
          tooltip: 'إغلاق البحث',
          onPressed: () => setState(() {
            searching = false;
            searchQuery = '';
          }),
          icon: const Icon(Icons.arrow_forward_rounded),
        ),
        titleSpacing: 0,
        title: TextField(
          autofocus: true,
          onChanged: updateSearch,
          style: const TextStyle(color: inkText, fontSize: 16),
          decoration: const InputDecoration(
            hintText: 'بحث',
            hintStyle: TextStyle(color: muted),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (searchQuery.isNotEmpty)
            IconButton(
              tooltip: 'مسح',
              onPressed: () => updateSearch(''),
              icon: const Icon(Icons.clear_rounded),
            ),
        ],
      );
    }

    return AppBar(
      toolbarHeight: 64,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'فتح القائمة',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      actions: [
        if (canSearch)
          IconButton(
            tooltip: 'بحث',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => setState(() => searching = true),
          ),
        if (canSearch)
          IconButton(
            tooltip: 'ترتيب',
            icon: const Icon(Icons.tune_rounded),
            onPressed: showSortMenu,
          ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget body() {
    if (!online) {
      return OfflineState(onRetry: () => setState(() => online = true));
    }
    if (sourceLoading) {
      return const Center(child: CircularProgressIndicator(color: accent));
    }
    if (sourceError != null && latestItems.isEmpty) {
      return EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'تعذر الاتصال بالمصدر',
        description: '',
        action: 'إعادة المحاولة',
        onAction: refreshSource,
      );
    }
    final allItems = ordered(catalogItems);
    final favoriteItems = ordered(manga.where((item) => item.favorite).toList());
    final searchingRemote = searchQuery.trim().isNotEmpty && page != Page.favorites;
    if (searchingRemote && searchLoading && remoteSearchItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: accent));
    }
    final latestResults = searchingRemote ? remoteSearchItems : latestItems;
    final catalogResults = searchingRemote ? remoteSearchItems : allItems;
    return switch (page) {
      Page.latest => Collection(
          items: filtered(latestResults),
          onTap: (item) => setState(() => selected = item),
          compact: compact,
          header: 'آخر التحديثات',
          helper: '',
          latestView: true,
          onLoadMore: () => loadMore(Page.latest),
          featured: !searching && searchQuery.isEmpty,
        ),
      Page.manga => Collection(
          items: filtered(catalogResults),
          onTap: (item) => setState(() => selected = item),
          compact: compact,
          header: 'كل المانجا',
          helper: '',
          onLoadMore: () => loadMore(Page.manga),
        ),
      Page.favorites => Collection(
          items: filtered(favoriteItems),
          onTap: (item) => setState(() => selected = item),
          compact: compact,
          header: 'المفضلة',
          helper: '',
        ),
      Page.storage => storage(),
      Page.notifications => notices(),
      Page.settings => settings(),
      Page.about => about(),
    };
  }

  Widget drawer() {
    return Drawer(
      width: 318,
      backgroundColor: navy,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Row(
                children: [
                  _logo(52),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MANGA PLUS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                            fontSize: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _drawerLabel('المكتبة'),
                  nav('الأحدث', Icons.auto_awesome_rounded, Page.latest),
                  nav('استكشف المانجا', Icons.menu_book_rounded, Page.manga),
                  nav('المفضلة', Icons.favorite_border_rounded, Page.favorites),
                  nav('التحميلات', Icons.downloading_rounded, Page.notifications),
                  nav('التخزين', Icons.download_outlined, Page.storage),
                  const SizedBox(height: 18),
                  _drawerLabel('التطبيق'),
                  nav('الإعدادات', Icons.settings_outlined, Page.settings),
                  nav('حول التطبيق', Icons.info_outline_rounded, Page.about),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'الإصدار 1.1',
                    style: TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Text(
        text,
        style: const TextStyle(
          color: muted,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget nav(String text, IconData icon, Page target) {
    final active = page == target && selected == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: active ? accent.withOpacity(.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.pop(context);
            open(target);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, color: active ? accent : muted, size: 21),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: active ? inkText : muted,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (target == Page.notifications && tasks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: const TextStyle(
                        color: teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (active)
                  const Icon(Icons.chevron_left_rounded, color: accent, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget storage() {
    final saved = manga.where((item) => downloadedFor(item).isNotEmpty).toList();
    if (saved.isEmpty) {
      return const EmptyState(
        icon: Icons.download_done_rounded,
        title: 'لا توجد فصول محفوظة',
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: _StorageSummary(count: saved.length),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = saved[index];
                return StorageCard(
                  item: item,
                  count: downloadedFor(item).length,
                  onTap: () => setState(() {
                    selected = item;
                    page = Page.storage;
                  }),
                );
              },
              childCount: saved.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 182,
              mainAxisSpacing: 17,
              crossAxisSpacing: 14,
              childAspectRatio: .62,
            ),
          ),
        ),
      ],
    );
  }

  Widget notices() {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.downloading_rounded,
        title: 'لا توجد تحميلات',
        description: '',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('التحميلات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
            ),
            Text('${tasks.length}', style: const TextStyle(color: accent, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 16),
        ...tasks.map((task) => DownloadTaskCard(task: task)),
      ],
    );
  }

  Widget settings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      children: [
        const _SettingsHeading(title: 'الحساب والمزامنة'),
        _simpleSetting('تسجيل الدخول', Icons.login_rounded, onTap: () {}),
        const SizedBox(height: 22),
        const _SettingsHeading(title: 'الثيم والظهور'),
        _simpleSetting('اللغة', Icons.language_rounded, value: 'العربية'),
        setting('الوضع الداكن', '', appDarkMode.value, (value) {
          setState(() => appDarkMode.value = value);
        }, Icons.dark_mode_outlined),
        const SizedBox(height: 7),
        const Text('الثيم', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 10),
        _themePicker(),
        const SizedBox(height: 22),
        const _SettingsHeading(title: 'القارئ'),
        setting('عرض مضغوط', '', compact, (value) => setState(() => compact = value), Icons.view_agenda_outlined),
        const SizedBox(height: 22),
        const _SettingsHeading(title: 'التنزيلات'),
        setting('التنزيل عبر Wi‑Fi فقط', '', wifiOnly, (value) => setState(() => wifiOnly = value), Icons.wifi_rounded),
        setting('الاتصال بالإنترنت', '', online, (value) => setState(() => online = value), Icons.cloud_done_outlined),
      ],
    );
  }

  Widget _simpleSetting(String title, IconData icon, {String? value, VoidCallback? onTap}) {
    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        leading: Icon(icon, color: accent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: value == null
            ? const Icon(Icons.chevron_left_rounded, color: muted)
            : Text(value, style: const TextStyle(color: muted, fontSize: 11)),
        onTap: onTap,
      ),
    );
  }

  Widget _themePicker() {
    final options = <Color>[accent, const Color(0xFFFF6B78), const Color(0xFF56D596), const Color(0xFF6FD5FF)];
    return Row(
      children: options.map((color) {
        final selected = themeColor.value == color.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => themeColor = color),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(.18),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? color : Colors.transparent, width: 2),
                ),
                child: Icon(selected ? Icons.check_rounded : Icons.circle, color: color, size: selected ? 20 : 14),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget setting(
    String title,
    String helper,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.white.withOpacity(.05)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: teal,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        secondary: Icon(icon, color: accent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget about() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [surface2, accent.withOpacity(.1)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: accent.withOpacity(.12)),
          ),
          child: Column(
            children: [
              _logo(88),
              const SizedBox(height: 17),
              const Text(
                'MANGA PLUS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 7),
              const SizedBox(height: 17),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: teal.withOpacity(.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'الإصدار 1.1.0',
                  style: TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeading(title: 'عن التطبيق', helper: ''),
        info(Icons.language_rounded, 'اللغة', 'العربية'),
        info(Icons.devices_rounded, 'مصمم لـ', 'هواتف وأجهزة أندرويد'),
        info(Icons.auto_awesome_rounded, 'الهدف', 'قراءة هادئة بلا تشتيت'),
        info(Icons.shield_outlined, 'الخصوصية', 'بياناتك تحت سيطرتك'),
      ],
    );
  }

  Widget info(IconData icon, String title, String value) {
    return Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        leading: Icon(icon, color: accent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: Text(value, style: const TextStyle(color: muted, fontSize: 11)),
      ),
    );
  }
}

class Collection extends StatelessWidget {
  final List<MangaItem> items;
  final ValueChanged<MangaItem> onTap;
  final bool compact;
  final String header;
  final String helper;
  final bool featured;
  final bool latestView;
  final VoidCallback? onLoadMore;

  const Collection({
    super.key,
    required this.items,
    required this.onTap,
    required this.compact,
    required this.header,
    required this.helper,
    this.featured = false,
    this.latestView = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'لا توجد عناوين محفوظة',
        description: 'اضغط على القلب في صفحة أي مانجا لتظهر هنا.',
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >= notification.metrics.maxScrollExtent - 500) {
          onLoadMore?.call();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          if (featured)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: FeaturedBanner(item: items.first, onTap: () => onTap(items.first)),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: featured ? 0 : 14)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, compact ? 16 : 30),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final itemIndex = featured ? index + 1 : index;
                  return CardManga(
                    item: items[itemIndex],
                    index: itemIndex,
                    latestView: latestView,
                    tap: () => onTap(items[itemIndex]),
                  );
                },
                childCount: featured ? items.length - 1 : items.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 182,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: .65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  final String title;
  final String helper;
  final String? trailing;

  const SectionHeading({
    super.key,
    required this.title,
    required this.helper,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w700),
          ),
      ],
    );
  }
}

class FeaturedBanner extends StatelessWidget {
  final MangaItem item;
  final VoidCallback onTap;

  const FeaturedBanner({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(26),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 210,
          child: Stack(
            fit: StackFit.expand,
            children: [
              mangaImage(item.asset),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, navy.withOpacity(.96)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [.18, 1],
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: teal.withOpacity(.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: teal.withOpacity(.26)),
                  ),
                  child: const Text(
                    'اختيار اليوم',
                    style: TextStyle(color: teal, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              Positioned(
                right: 18,
                left: 18,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(color: accent, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_rounded, color: navy),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardManga extends StatelessWidget {
  final MangaItem item;
  final int index;
  final bool latestView;
  final VoidCallback tap;

  const CardManga({super.key, required this.item, required this.index, this.latestView = false, required this.tap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CoverFrame(item: item, hero: true, chapter: latestView ? item.latestChapterNumber : null)),
            const SizedBox(height: 9),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFFFC857), size: 13),
                const SizedBox(width: 3),
                Text(
                  ratingLabel(item.rating),
                  style: const TextStyle(color: inkText, fontSize: 10, fontWeight: FontWeight.w700),
                ),
                if (latestView) ...[
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item.updated,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverFrame extends StatelessWidget {
  final MangaItem item;
  final bool hero;
  final String? chapter;

  const _CoverFrame({required this.item, this.hero = false, this.chapter});

  @override
  Widget build(BuildContext context) {
    final image = mangaImage(item.asset);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          hero ? Hero(tag: 'manga-${item.asset}', child: image) : image,
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(.62)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [.52, 1],
              ),
            ),
          ),
          Positioned(
            top: 9,
            right: 9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: item.status == 'مكتمل' ? teal.withOpacity(.18) : accent.withOpacity(.18),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white.withOpacity(.13)),
              ),
              child: Text(
                item.status,
                style: TextStyle(
                  color: item.status == 'مكتمل' ? teal : Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (item.favorite)
            const Positioned(
              top: 10,
              left: 10,
              child: Icon(Icons.favorite_rounded, color: Color(0xFFFF7890), size: 17),
            ),
          if (chapter != null && chapter!.isNotEmpty)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(color: navy.withOpacity(.82), borderRadius: BorderRadius.circular(9)),
                child: Text('الفصل $chapter', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
          if (chapter == null || chapter!.isEmpty)
            Positioned(
            right: 11,
            left: 11,
            bottom: 11,
            child: Text(
              item.tags.take(2).join('  •  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class Details extends StatefulWidget {
  final MangaItem item;
  final MangaTimeService source;
  final VoidCallback back;
  final VoidCallback changed;
  final Map<int, ChapterRecord> records;
  final bool downloadedOnly;
  final ValueChanged<List<int>> onDownload;
  final void Function(List<int>, bool) onRead;

  const Details({
    super.key,
    required this.item,
    required this.source,
    required this.back,
    required this.changed,
    required this.records,
    required this.downloadedOnly,
    required this.onDownload,
    required this.onRead,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final Set<int> selected = {};
  bool selecting = false;
  bool loadingSource = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.slug.isNotEmpty && widget.item.remoteChapters.isEmpty) {
      loadRemoteDetails();
    }
  }

  Future<void> loadRemoteDetails() async {
    setState(() => loadingSource = true);
    try {
      final data = await widget.source.fetchDetails(widget.item.slug);
      widget.item.updateFrom(data.series);
      widget.item.author = data.author ?? '';
      widget.item.sourceName = data.sourceName;
      widget.item.sourceLogo = data.sourceLogo;
      widget.item.remoteChapters = data.chapters;
      widget.item.chapters = data.chapters.length;
    } catch (_) {
      // Keep the cached catalog data visible if the details request is unavailable.
    } finally {
      if (mounted) setState(() => loadingSource = false);
    }
  }

  int get readCount => widget.records.values.where((record) => record.read).length;

  int? get lastRead {
    final chapters = widget.records.entries
        .where((entry) => entry.value.read)
        .map((entry) => entry.key)
        .toList();
    if (chapters.isEmpty) return null;
    chapters.sort((a, b) => b.compareTo(a));
    return chapters.first;
  }

  @override
  Widget build(BuildContext context) {
    final remoteChapters = widget.item.remoteChapters;
    final availableChapters = (remoteChapters.isEmpty
            ? List.generate(widget.item.chapters, (index) => MangaTimeChapter(
                id: '', number: '${widget.item.chapters - index}', title: '', publishedAt: null, pageCount: 0, unlocked: true))
            : remoteChapters)
        .where((chapter) => !widget.downloadedOnly || widget.records[int.tryParse(chapter.number) ?? 0]?.download == DownloadStatus.success)
        .toList();

    return SafeArea(
      top: true,
      child: CustomScrollView(
        slivers: [
          if (loadingSource) const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2, color: accent)),
          SliverToBoxAdapter(child: _detailsHero()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 38),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _primaryActions(),
                  if (widget.item.sourceName.isNotEmpty && widget.item.sourceLogo.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _sourceBadge(),
                  ],
                  const SizedBox(height: 22),
                  _resumeCard(),
                  const SizedBox(height: 28),
                  const SectionHeading(
                    title: 'نبذة عن القصة',
                    helper: 'ملخص سريع قبل أن تبدأ الفصل الأول.',
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.item.description,
                    style: const TextStyle(color: muted, height: 1.75, fontSize: 13),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Expanded(
                        child: SectionHeading(
                          title: 'الفصول',
                          helper: 'اضغط مطولًا لتحديد أكثر من فصل.',
                        ),
                      ),
                      Text(
                        '${widget.item.chapters} فصل',
                        style: const TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  if (selecting) ...[
                    SelectionBar(
                      selected: selected,
                      total: widget.item.chapters,
                      onAll: () => setState(() => selected.addAll(availableChapters.map((chapter) => int.tryParse(chapter.number) ?? 0),
                          )),
                      onDownload: () {
                        widget.onDownload(selected.toList());
                        setState(() {
                          selected.clear();
                          selecting = false;
                        });
                      },
                      onRead: (value) {
                        widget.onRead(selected.toList(), value);
                        setState(() {
                          selected.clear();
                          selecting = false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  ...availableChapters.map(
                    (chapter) {
                      final number = int.tryParse(chapter.number) ?? 0;
                      return ChapterTile(
                        number: number,
                        dateLabel: mangaTimeRelativeDate(chapter.publishedAt),
                        record: widget.records[number],
                        selected: selected.contains(number),
                        onLongPress: () => setState(() {
                          selecting = true;
                          selected.add(number);
                        }),
                        onTap: () {
                          if (selecting) {
                            setState(() {
                              selected.contains(number) ? selected.remove(number) : selected.add(number);
                              if (selected.isEmpty) selecting = false;
                            });
                          } else {
                            widget.records.putIfAbsent(number, ChapterRecord.new).read = true;
                            widget.changed();
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsHero() {
    return SizedBox(
      height: 350,
      child: Stack(
        fit: StackFit.expand,
        children: [
          mangaImage(widget.item.asset),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [navy.withOpacity(.28), navy.withOpacity(.46), navy],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, .45, 1],
              ),
            ),
          ),
          Positioned(
            top: 14,
            right: 16,
            child: _roundAction(
              icon: Icons.arrow_forward_rounded,
              onTap: widget.back,
              tooltip: 'العودة',
            ),
          ),
          Positioned(
            top: 14,
            left: 16,
            child: _roundAction(
              icon: widget.item.favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: widget.item.favorite ? const Color(0xFFFF7890) : null,
              onTap: () {
                setState(() => widget.item.favorite = !widget.item.favorite);
                widget.changed();
              },
              tooltip: 'المفضلة',
            ),
          ),
          Positioned(
            right: 20,
            left: 20,
            bottom: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    width: 108,
                    height: 154,
                    child: Hero(
                      tag: 'manga-${widget.item.asset}',
                      child: mangaImage(widget.item.asset),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.item.subtitle,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '⭐${ratingLabel(widget.item.rating)}  ·  ${widget.item.updated}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.item.tags
                              .map((tag) => _TagPill(label: tag))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceBadge() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(7, 7, 12, 7),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(width: 30, height: 30, child: mangaImage(widget.item.sourceLogo)),
            ),
            const SizedBox(width: 8),
            Text(widget.item.sourceName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _roundAction({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withOpacity(.34),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color ?? Colors.white, size: 21),
          ),
        ),
      ),
    );
  }

  Widget _primaryActions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              final first = lastRead ?? widget.item.chapters;
              widget.records.putIfAbsent(first, ChapterRecord.new).read = true;
              widget.changed();
            },
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: navy,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(lastRead == null ? 'ابدأ القراءة' : 'تابع القراءة'),
          ),
        ),
        const SizedBox(width: 10),
        _secondaryAction(
          icon: Icons.share_outlined,
          onTap: () {},
          tooltip: 'مشاركة',
        ),
      ],
    );
  }

  Widget _secondaryAction({required IconData icon, required VoidCallback onTap, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: surface2,
          foregroundColor: inkText,
          minimumSize: const Size(54, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        ),
      ),
    );
  }

  Widget _resumeCard() {
    final readLabel = lastRead == null ? 'جاهز للفصل الأول' : 'آخر قراءة: الفصل $lastRead';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: teal.withOpacity(.13),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(readLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  '$readCount من ${widget.item.chapters} فصل مقروء',
                  style: const TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          _MiniStat(value: widget.item.rating.toStringAsFixed(1), label: 'تقييم', icon: Icons.star_rounded),
          const SizedBox(width: 16),
          _MiniStat(value: widget.item.updated, label: 'التحديث', icon: Icons.schedule_rounded),
        ],
      ),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withOpacity(.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: const TextStyle(color: accent, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _MiniStat({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: icon == Icons.star_rounded ? const Color(0xFFFFC857) : accent, size: 13),
            const SizedBox(width: 3),
            Text(value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: muted, fontSize: 9)),
      ],
    );
  }
}

class SelectionBar extends StatelessWidget {
  final Set<int> selected;
  final int total;
  final VoidCallback onAll;
  final VoidCallback onDownload;
  final ValueChanged<bool> onRead;

  const SelectionBar({
    super.key,
    required this.selected,
    required this.total,
    required this.onAll,
    required this.onDownload,
    required this.onRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: surface2,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withOpacity(.14)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: accent.withOpacity(.13), borderRadius: BorderRadius.circular(9)),
            child: Text('${selected.length} محدد', style: const TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
          const Spacer(),
          TextButton(onPressed: onAll, child: const Text('الكل', style: TextStyle(fontSize: 11))),
          IconButton(onPressed: onDownload, tooltip: 'تنزيل', icon: const Icon(Icons.download_rounded, size: 20)),
          IconButton(onPressed: () => onRead(true), tooltip: 'تحديد كمقروء', icon: const Icon(Icons.done_all_rounded, size: 20)),
          IconButton(onPressed: () => onRead(false), tooltip: 'تحديد كغير مقروء', icon: const Icon(Icons.mark_email_unread_outlined, size: 20)),
        ],
      ),
    );
  }
}

class ChapterTile extends StatelessWidget {
  final int number;
  final ChapterRecord? record;
  final String? dateLabel;
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const ChapterTile({
    super.key,
    required this.number,
    this.record,
    this.dateLabel,
    required this.selected,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = record?.download ?? DownloadStatus.idle;
    final downloaded = status == DownloadStatus.success;
    final failed = status == DownloadStatus.failed;
    final icon = downloaded
        ? Icons.download_done_rounded
        : failed
            ? Icons.error_outline_rounded
            : Icons.download_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? accent.withOpacity(.14) : surface,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected ? accent : accent.withOpacity(.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: selected ? navy : accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الفصل $number',
                        style: TextStyle(
                          fontWeight: record?.read == true ? FontWeight.w500 : FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel ?? (record?.read == true ? 'مقروء' : 'غير مقروء'),
                        style: const TextStyle(color: muted, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (status == DownloadStatus.downloading)
                  const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(strokeWidth: 2, color: accent),
                  )
                else
                  Icon(icon, color: failed ? danger : downloaded ? teal : muted, size: 21),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StorageCard extends StatelessWidget {
  final MangaItem item;
  final int count;
  final VoidCallback onTap;

  const StorageCard({super.key, required this.item, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _CoverFrame(item: item)),
            const SizedBox(height: 9),
            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 4),
            Text('$count فصول محفوظة', style: const TextStyle(color: teal, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;

  const DownloadTaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final failed = task.status == DownloadStatus.failed;
    final success = task.status == DownloadStatus.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: mangaImage(task.item.asset, width: 47, height: 62),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(height: 5),
                    Text(task.label, style: const TextStyle(color: muted, fontSize: 10)),
                  ],
                ),
              ),
              Icon(
                failed
                    ? Icons.error_outline_rounded
                    : success
                        ? Icons.check_circle_outline_rounded
                        : Icons.downloading_rounded,
                color: failed ? danger : success ? teal : accent,
              ),
            ],
          ),
          if (!success && !failed) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: task.progress,
                minHeight: 6,
                color: accent,
                backgroundColor: surface3,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Text('جاري التنزيل', style: TextStyle(color: muted, fontSize: 10)),
                const Spacer(),
                Text('${(task.progress * 100).round()}%', style: const TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
          if (failed)
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('فشل التنزيل', style: TextStyle(color: danger, fontSize: 10)),
              ),
            ),
          if (success)
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('تم التنزيل', style: TextStyle(color: teal, fontSize: 10)),
              ),
            ),
        ],
      ),
    );
  }
}

class _StorageSummary extends StatelessWidget {
  final int count;

  const _StorageSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [surface2, teal.withOpacity(.08)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal.withOpacity(.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(color: teal.withOpacity(.14), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.offline_bolt_rounded, color: teal),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('القراءة دون اتصال', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          Text('$count أعمال', style: const TextStyle(color: teal, fontWeight: FontWeight.w800, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ActivityHeader extends StatelessWidget {
  final int count;

  const _ActivityHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(color: accent.withOpacity(.13), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.bolt_rounded, color: accent),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('آخر نشاط', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
              SizedBox(height: 4),
              Text('تظهر هنا حالة الفصول التي تحفظها أو تقرؤها.', style: TextStyle(color: muted, fontSize: 10)),
            ],
          ),
        ),
        Text('$count', style: const TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _SettingsHeading extends StatelessWidget {
  final String title;

  const _SettingsHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
    );
  }
}

class _SettingsProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: Colors.white.withOpacity(.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [accent, teal]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: navy),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قارئ Manga Plus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                SizedBox(height: 4),
                Text('خصص التجربة لتناسب وقتك ومكتبتك.', style: TextStyle(color: muted, fontSize: 10)),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: muted, size: 19),
        ],
      ),
    );
  }
}
