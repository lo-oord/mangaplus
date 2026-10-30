import 'dart:async';

import 'package:flutter/material.dart';

const navy = Color(0xFF0B111A);
const surface = Color(0xFF121C29);
const surface2 = Color(0xFF1A293B);
const surface3 = Color(0xFF22364B);
const accent = Color(0xFF75B7FF);
const teal = Color(0xFF65DED5);
const muted = Color(0xFF91A2B5);
const inkText = Color(0xFFF4F7FB);
const danger = Color(0xFFFF7474);

class MangaItem {
  final String title;
  final String subtitle;
  final String asset;
  final String description;
  final String status;
  final int chapters;
  final List<String> tags;
  final String author;
  final String updated;
  final double rating;
  bool favorite;

  MangaItem(
    this.title,
    this.subtitle,
    this.asset,
    this.description,
    this.status,
    this.chapters,
    this.tags, {
    required this.author,
    required this.updated,
    required this.rating,
    this.favorite = false,
  });
}

final manga = <MangaItem>[
  MangaItem(
    'ظل التنين',
    'Dragon Shade',
    'assets/covers/dragon.png',
    'في مدينة معلقة فوق الغيوم، يكتشف شاب هادئ قوة قديمة تغيّر مصير المملكة.',
    'مستمر',
    48,
    ['أكشن', 'فانتازيا'],
    author: 'رين كاي',
    updated: 'منذ ساعتين',
    rating: 4.8,
    favorite: true,
  ),
  MangaItem(
    'زهرة القمر',
    'Moon Bloom',
    'assets/covers/moon.png',
    'رحلة رومانسية بين ساحرة صغيرة وحارس يحمل سرًا من أسرار القمر.',
    'مستمر',
    32,
    ['رومانسي', 'دراما'],
    author: 'ميورا هانا',
    updated: 'أمس',
    rating: 4.6,
  ),
  MangaItem(
    'آخر صياد',
    'The Last Hunter',
    'assets/covers/hunter.png',
    'بعد انهيار المدن، يبقى صياد واحد يبحث عن الناجين وسط عالم مليء بالوحوش.',
    'مكتمل',
    76,
    ['مغامرة', 'أكشن'],
    author: 'تاكا يوشي',
    updated: 'منذ 3 أيام',
    rating: 4.9,
  ),
  MangaItem(
    'أكاديمية النجوم',
    'Star Academy',
    'assets/covers/star.png',
    'طلاب موهوبون يتنافسون لصناعة مستقبل جديد بين النجوم.',
    'مستمر',
    25,
    ['مدرسي', 'خيال'],
    author: 'سورا آكي',
    updated: 'منذ 5 أيام',
    rating: 4.4,
  ),
  MangaItem(
    'متاهة الزجاج',
    'Glass Maze',
    'assets/covers/glass.png',
    'كل باب في المتاهة يكشف ذكرى، وكل ذكرى تقرّب البطلة من الحقيقة.',
    'مستمر',
    19,
    ['غموض', 'دراما'],
    author: 'إيما ناغي',
    updated: 'منذ أسبوع',
    rating: 4.7,
  ),
  MangaItem(
    'مقهى منتصف الليل',
    'Midnight Cafe',
    'assets/covers/cafe.png',
    'مقهى لا يفتح إلا بعد منتصف الليل، ويستقبل زوارًا من عوالم مختلفة.',
    'مكتمل',
    41,
    ['شريحة من الحياة', 'فانتازيا'],
    author: 'نورا كاي',
    updated: 'منذ أسبوعين',
    rating: 4.5,
  ),
];

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manga Plus',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: navy,
          foregroundColor: inkText,
          elevation: 0,
          centerTitle: false,
        ),
        dividerColor: surface3,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: inkText, height: 1.45),
          bodyMedium: TextStyle(color: muted, height: 1.45),
          titleLarge: TextStyle(color: inkText, fontWeight: FontWeight.w800),
        ),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const Splash(),
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
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 520),
            pageBuilder: (_, animation, __) => const Shell(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(
              opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
              child: child,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: .82, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutBack,
          builder: (_, value, child) => Transform.scale(
            scale: value,
            child: child,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logo(94),
              const SizedBox(height: 20),
              const Text(
                'MANGA PLUS',
                style: TextStyle(
                  letterSpacing: 3.2,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'اقرأ قصتك القادمة',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _logo(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [accent, teal],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      borderRadius: BorderRadius.circular(size * .28),
      boxShadow: [
        BoxShadow(
          color: accent.withOpacity(.2),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Icon(
      Icons.menu_book_rounded,
      size: size * .56,
      color: navy,
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
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: muted, fontSize: 12, height: 1.6),
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
    if (!online) {
      setState(() {
        for (final number in chapters) {
          recordFor(item, number).download = DownloadStatus.failed;
        }
        tasks.insert(
          0,
          DownloadTask(item, chapters)..status = DownloadStatus.failed,
        );
      });
      return;
    }

    final task = DownloadTask(item, chapters);
    setState(() {
      tasks.insert(0, task);
      for (final number in chapters) {
        recordFor(item, number).download = DownloadStatus.downloading;
      }
      task.status = DownloadStatus.downloading;
    });

    task.timer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        task.progress = (task.progress + .12).clamp(0.0, 1.0).toDouble();
        if (task.progress >= 1) {
          task.status = DownloadStatus.success;
          for (final number in chapters) {
            recordFor(item, number).download = DownloadStatus.success;
          }
          timer.cancel();
        }
      });
    });
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
      Page.notifications => 'النشاط',
      Page.settings => 'الإعدادات',
      Page.about => 'حول التطبيق',
    };
  }

  String get subtitle {
    return switch (page) {
      Page.latest => 'فصول جديدة تستحق وقتك',
      Page.manga => 'كل القصص في مكان واحد',
      Page.favorites => 'اختياراتك المحفوظة',
      Page.storage => 'اقرأ بلا اتصال',
      Page.notifications => 'تابع التنزيلات والقراءة',
      Page.settings => 'اضبط تجربتك كما تحب',
      Page.about => 'تجربة قراءة هادئة ومركزة',
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
    });
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
    return AppBar(
      toolbarHeight: 76,
      leading: Builder(
        builder: (context) => IconButton(
          tooltip: 'فتح القائمة',
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu_rounded),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _logo(36),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: muted, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'ترتيب',
          icon: const Icon(Icons.tune_rounded),
          onPressed: showSortMenu,
        ),
        IconButton(
          tooltip: 'بحث',
          icon: const Icon(Icons.search_rounded),
          onPressed: () => showSearch(
            context: context,
            delegate: SearchManga((item) {
              setState(() => selected = item);
            }),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget body() {
    if (!online) {
      return OfflineState(onRetry: () => setState(() => online = true));
    }
    return switch (page) {
      Page.latest => Collection(
          items: ordered(manga),
          onTap: (item) => setState(() => selected = item),
          compact: compact,
          header: 'آخر التحديثات',
          helper: 'قصص جديدة ومختارة لتبدأ بها اليوم',
          featured: true,
        ),
      Page.manga => Collection(
          items: ordered(manga),
          onTap: (item) => setState(() => selected = item),
          compact: compact,
          header: 'كل المانجا',
          helper: 'تصفح العناوين حسب مزاجك واكتشف عالمًا جديدًا',
        ),
      Page.favorites => Collection(
          items: ordered(manga.where((item) => item.favorite).toList()),
          onTap: (item) => setState(() => selected = item),
          compact: compact,
          header: 'المفضلة لديك',
          helper: 'احتفظ بالقصص التي تريد العودة إليها لاحقًا',
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
                        SizedBox(height: 5),
                        Text(
                          'عالمك القصصي بين يديك',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(.18), teal.withOpacity(.08)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: accent.withOpacity(.16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: teal, size: 21),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'اكتشف فصلًا جديدًا اليوم',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: accent.withOpacity(.8)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  _drawerLabel('المكتبة'),
                  nav('الأحدث', Icons.auto_awesome_rounded, Page.latest),
                  nav('استكشف المانجا', Icons.menu_book_rounded, Page.manga),
                  nav('المفضلة', Icons.favorite_border_rounded, Page.favorites),
                  nav('التخزين', Icons.download_outlined, Page.storage),
                  const SizedBox(height: 18),
                  _drawerLabel('التطبيق'),
                  nav(
                    'النشاط والتنزيلات',
                    Icons.notifications_none_rounded,
                    Page.notifications,
                  ),
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
                  const SizedBox(width: 8),
                  const Text(
                    'متصل الآن',
                    style: TextStyle(color: muted, fontSize: 11),
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
        title: 'مساحتك الهادئة للقراءة',
        description: 'نزّل فصولك المفضلة لتظهر هنا وتقرأها بلا اتصال.',
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
        icon: Icons.notifications_none_rounded,
        title: 'لا يوجد نشاط بعد',
        description: 'ابدأ بقراءة فصل أو تنزيله وستظهر تحديثاتك هنا.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _ActivityHeader(count: tasks.length),
        const SizedBox(height: 22),
        ...tasks.map((task) => DownloadTaskCard(task: task)),
      ],
    );
  }

  Widget settings() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
      children: [
        _SettingsProfile(),
        const SizedBox(height: 26),
        const SectionHeading(
          title: 'تجربة القراءة',
          helper: 'اجعل التطبيق يناسب طريقتك في القراءة.',
        ),
        setting(
          'إشعارات التحديثات',
          'تنبيهات عند صدور فصول جديدة',
          notifications,
          (value) => setState(() => notifications = value),
          Icons.notifications_active_outlined,
        ),
        setting(
          'التنزيل عبر Wi‑Fi فقط',
          'تقليل استهلاك بيانات الهاتف',
          wifiOnly,
          (value) => setState(() => wifiOnly = value),
          Icons.wifi_rounded,
        ),
        setting(
          'عرض مضغوط',
          'تقليل المسافات بين البطاقات',
          compact,
          (value) => setState(() => compact = value),
          Icons.view_agenda_outlined,
        ),
        const SizedBox(height: 24),
        const SectionHeading(
          title: 'الحساب والاتصال',
          helper: 'معلومات أساسية عن جلسة التطبيق.',
        ),
        setting(
          'الاتصال بالإنترنت',
          online ? 'متصل وجاهز للتحديث' : 'متوقف مؤقتًا',
          online,
          (value) => setState(() => online = value),
          online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
        ),
        Card(
          color: surface,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withOpacity(.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            leading: const Icon(Icons.login_rounded, color: accent),
            title: const Text('تسجيل الدخول'),
            subtitle: const Text(
              'زامن مكتبتك على أجهزتك',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            trailing: const Icon(Icons.chevron_left_rounded, color: muted),
            onTap: () {},
          ),
        ),
      ],
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
        subtitle: Text(helper, style: const TextStyle(color: muted, fontSize: 11)),
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
              const Text(
                'اقرأ أكثر، انتظر أقل، واستمتع بكل صفحة.',
                style: TextStyle(color: muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
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
        const SectionHeading(
          title: 'عن التطبيق',
          helper: 'تفاصيل صغيرة تصنع تجربة قراءة أفضل.',
        ),
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

  const Collection({
    super.key,
    required this.items,
    required this.onTap,
    required this.compact,
    required this.header,
    required this.helper,
    this.featured = false,
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

    return CustomScrollView(
      slivers: [
        if (featured)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
              child: FeaturedBanner(item: items.first, onTap: () => onTap(items.first)),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, featured ? 2 : 14, 20, 16),
            child: SectionHeading(
              title: header,
              helper: helper,
              trailing: '${items.length} عناوين',
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(18, 0, 18, compact ? 16 : 30),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => CardManga(
                item: items[index],
                index: index,
                tap: () => onTap(items[index]),
              ),
              childCount: items.length,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 182,
              mainAxisSpacing: 18,
              crossAxisSpacing: 14,
              childAspectRatio: .62,
            ),
          ),
        ),
      ],
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
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              ),
              const SizedBox(height: 5),
              Text(
                helper,
                style: const TextStyle(color: muted, fontSize: 11, height: 1.45),
              ),
            ],
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .96, end: 1),
      duration: const Duration(milliseconds: 540),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Transform.scale(scale: value, child: child),
      child: Material(
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
                Image.asset(item.asset, fit: BoxFit.cover),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.5),
                            ),
                          ],
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
      ),
    );
  }
}

class CardManga extends StatelessWidget {
  final MangaItem item;
  final int index;
  final VoidCallback tap;

  const CardManga({super.key, required this.item, required this.index, required this.tap});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (index * 45)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(offset: Offset(0, 18 * (1 - value)), child: child),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _CoverFrame(item: item, hero: true),
              ),
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
                    item.rating.toStringAsFixed(1),
                    style: const TextStyle(color: inkText, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${item.chapters} فصل',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: muted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverFrame extends StatelessWidget {
  final MangaItem item;
  final bool hero;

  const _CoverFrame({required this.item, this.hero = false});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(item.asset, fit: BoxFit.cover);
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
  final VoidCallback back;
  final VoidCallback changed;
  final Map<int, ChapterRecord> records;
  final bool downloadedOnly;
  final ValueChanged<List<int>> onDownload;
  final void Function(List<int>, bool) onRead;

  const Details({
    super.key,
    required this.item,
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
    final availableChapters = List.generate(
      widget.item.chapters,
      (index) => widget.item.chapters - index,
    ).where(
      (number) =>
          !widget.downloadedOnly ||
          widget.records[number]?.download == DownloadStatus.success,
    );

    return SafeArea(
      top: true,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _detailsHero()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 38),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _primaryActions(),
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
                      onAll: () => setState(() => selected.addAll(
                            List.generate(widget.item.chapters, (index) => widget.item.chapters - index),
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
                  ...availableChapters.take(12).map(
                    (number) => ChapterTile(
                      number: number,
                      record: widget.records[number],
                      selected: selected.contains(number),
                      onLongPress: () => setState(() {
                        selecting = true;
                        selected.add(number);
                      }),
                      onTap: () {
                        if (selecting) {
                          setState(() {
                            selected.contains(number)
                                ? selected.remove(number)
                                : selected.add(number);
                            if (selected.isEmpty) selecting = false;
                          });
                        } else {
                          widget.records.putIfAbsent(number, ChapterRecord.new).read = true;
                          widget.changed();
                        }
                      },
                    ),
                  ),
                  if (availableChapters.length > 12) ...[
                    const SizedBox(height: 4),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.expand_more_rounded),
                        label: Text('عرض بقية الفصول (${availableChapters.length - 12})'),
                      ),
                    ),
                  ],
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
          Image.asset(widget.item.asset, fit: BoxFit.cover),
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
                      child: Image.asset(widget.item.asset, fit: BoxFit.cover),
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
  final bool selected;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const ChapterTile({
    super.key,
    required this.number,
    this.record,
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
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
                        record?.read == true ? 'مقروء · اضغط لإعادة الفتح' : 'جاهز للقراءة · اضغط مطولًا للتحديد',
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
                child: Image.asset(task.item.asset, width: 47, height: 62, fit: BoxFit.cover),
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
                const Text('جارٍ الحفظ على جهازك', style: TextStyle(color: muted, fontSize: 10)),
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
                child: Text('فشل التنزيل · حاول مرة أخرى', style: TextStyle(color: danger, fontSize: 10)),
              ),
            ),
          if (success)
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text('تم الحفظ · متاح بلا اتصال', style: TextStyle(color: teal, fontSize: 10)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('جاهز للقراءة بلا اتصال', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(height: 4),
                Text('كل ما حفظته مؤمن في مكتبتك المحلية.', style: TextStyle(color: muted, fontSize: 10)),
              ],
            ),
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

class SearchManga extends SearchDelegate<MangaItem?> {
  final ValueChanged<MangaItem> open;

  SearchManga(this.open);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(backgroundColor: surface, foregroundColor: inkText),
      inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear_rounded)),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_forward_rounded),
    );
  }

  @override
  Widget buildResults(BuildContext context) => results(context);

  @override
  Widget buildSuggestions(BuildContext context) => results(context);

  Widget results(BuildContext context) {
    final found = manga
        .where(
          (item) => item.title.contains(query) || item.subtitle.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    if (found.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'لا توجد نتائج مطابقة',
        description: 'جرّب اسمًا مختلفًا أو ابحث بالعنوان الإنجليزي.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      itemCount: found.length,
      separatorBuilder: (_, __) => const SizedBox(height: 9),
      itemBuilder: (_, index) {
        final item = found[index];
        return Material(
          color: surface,
          borderRadius: BorderRadius.circular(17),
          child: ListTile(
            onTap: () {
              close(context, item);
              open(item);
            },
            contentPadding: const EdgeInsets.all(9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(item.asset, width: 48, height: 62, fit: BoxFit.cover),
            ),
            title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('${item.subtitle}  ·  ${item.chapters} فصل', style: const TextStyle(color: muted, fontSize: 10)),
            ),
            trailing: const Icon(Icons.chevron_left_rounded, color: muted),
          ),
        );
      },
    );
  }
}
