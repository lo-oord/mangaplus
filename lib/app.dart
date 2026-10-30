import 'dart:async';
import 'package:flutter/material.dart';

const navy = Color(0xFF121923),
    surface = Color(0xFF1B2532),
    surface2 = Color(0xFF263344),
    accent = Color(0xFF4D9BFF),
    muted = Color(0xFF9BA8B8);

class MangaItem {
  final String title, subtitle, asset, description, status;
  final int chapters;
  final List<String> tags;
  bool favorite;
  MangaItem(this.title, this.subtitle, this.asset, this.description,
      this.status, this.chapters, this.tags,
      {this.favorite = false});
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
      favorite: true),
  MangaItem(
      'زهرة القمر',
      'Moon Bloom',
      'assets/covers/moon.png',
      'رحلة رومانسية بين ساحرة صغيرة وحارس يحمل سرًا من أسرار القمر.',
      'مستمر',
      32,
      ['رومانسي', 'دراما']),
  MangaItem(
      'آخر صياد',
      'The Last Hunter',
      'assets/covers/hunter.png',
      'بعد انهيار المدن، يبقى صياد واحد يبحث عن الناجين وسط عالم مليء بالوحوش.',
      'مكتمل',
      76,
      ['مغامرة', 'أكشن']),
  MangaItem(
      'أكاديمية النجوم',
      'Star Academy',
      'assets/covers/star.png',
      'طلاب موهوبون يتنافسون لصناعة مستقبل جديد بين النجوم.',
      'مستمر',
      25,
      ['مدرسي', 'خيال']),
  MangaItem(
      'متاهة الزجاج',
      'Glass Maze',
      'assets/covers/glass.png',
      'كل باب في المتاهة يكشف ذكرى، وكل ذكرى تقرّب البطلة من الحقيقة.',
      'مستمر',
      19,
      ['غموض', 'دراما']),
  MangaItem(
      'مقهى منتصف الليل',
      'Midnight Cafe',
      'assets/covers/cafe.png',
      'مقهى لا يفتح إلا بعد منتصف الليل، ويستقبل زوارًا من عوالم مختلفة.',
      'مكتمل',
      41,
      ['شريحة من الحياة', 'فانتازيا']),
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

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      this.action,
      this.onAction});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 58, color: muted),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: muted, fontSize: 15)),
            if (action != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(action!))
            ],
          ])));
}

class OfflineState extends StatelessWidget {
  final VoidCallback onRetry;
  const OfflineState({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => EmptyState(
      icon: Icons.cloud_off_rounded,
      title: 'لا يتوفر اتصال بالإنترنت',
      action: 'إعادة المحاولة',
      onAction: onRetry);
}

class MangaPlusApp extends StatelessWidget {
  const MangaPlusApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Manga Plus',
      theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: navy,
          colorScheme: ColorScheme.fromSeed(
              seedColor: accent, brightness: Brightness.dark)),
      home: const Splash());
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
      if (mounted)
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const Shell()));
    });
  }

  @override
  Widget build(BuildContext c) => Scaffold(
      backgroundColor: navy,
      body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        _logo(94),
        const SizedBox(height: 18),
        const Text('MANGA PLUS',
            style: TextStyle(
                letterSpacing: 3, fontSize: 18, fontWeight: FontWeight.w700))
      ])));
}

Widget _logo(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
        color: accent, borderRadius: BorderRadius.circular(size * .28)),
    child:
        Icon(Icons.menu_book_rounded, size: size * .56, color: Colors.white));

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  Page page = Page.latest;
  MangaItem? selected;
  bool compact = false,
      notifications = true,
      wifiOnly = false,
      online = true,
      chaptersDescending = true;
  final Map<String, Map<int, ChapterRecord>> records = {};
  final List<DownloadTask> tasks = [];
  Map<int, ChapterRecord> recordsFor(MangaItem item) =>
      records.putIfAbsent(item.title, () => {});
  ChapterRecord recordFor(MangaItem item, int number) =>
      recordsFor(item).putIfAbsent(number, ChapterRecord.new);
  List<int> downloadedFor(MangaItem item) => recordsFor(item)
      .entries
      .where((e) => e.value.download == DownloadStatus.success)
      .map((e) => e.key)
      .toList()
    ..sort((a, b) => b.compareTo(a));
  void enqueueDownload(MangaItem item, List<int> numbers) {
    final chapters = numbers.toSet().toList()..sort((a, b) => b.compareTo(a));
    if (chapters.isEmpty) return;
    if (!online) {
      setState(() {
        for (final n in chapters)
          recordFor(item, n).download = DownloadStatus.failed;
        tasks.insert(
            0, DownloadTask(item, chapters)..status = DownloadStatus.failed);
      });
      return;
    }
    final task = DownloadTask(item, chapters);
    setState(() {
      tasks.insert(0, task);
      for (final n in chapters)
        recordFor(item, n).download = DownloadStatus.downloading;
      task.status = DownloadStatus.downloading;
    });
    task.timer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        task.progress = (task.progress + .12).clamp(0, 1);
        if (task.progress >= 1) {
          task.status = DownloadStatus.success;
          for (final n in chapters)
            recordFor(item, n).download = DownloadStatus.success;
          timer.cancel();
        }
      });
    });
  }

  void setRead(MangaItem item, List<int> numbers, bool value) => setState(() {
        for (final n in numbers) recordFor(item, n).read = value;
      });
  String get title =>
      selected?.title ??
      switch (page) {
        Page.latest => 'الأحدث',
        Page.manga => 'المانجا',
        Page.favorites => 'المفضلة',
        Page.storage => 'التخزين',
        Page.notifications => 'الإشعارات',
        Page.settings => 'الإعدادات',
        Page.about => 'حول'
      };
  List<MangaItem> ordered(List<MangaItem> items) {
    final result = [...items];
    result.sort((a, b) => chaptersDescending
        ? b.chapters.compareTo(a.chapters)
        : a.chapters.compareTo(b.chapters));
    return result;
  }

  void showSortMenu() => showModalBottomSheet<void>(
      context: context,
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
                padding: EdgeInsets.all(18),
                child: Text('ترتيب المانجا',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 17))),
            ListTile(
                leading: const Icon(Icons.new_releases_outlined, color: accent),
                title: const Text('الأحدث'),
                trailing: chaptersDescending
                    ? const Icon(Icons.check_rounded, color: accent)
                    : null,
                onTap: () {
                  setState(() => chaptersDescending = true);
                  Navigator.pop(context);
                }),
            ListTile(
                leading: const Icon(Icons.sort_rounded, color: accent),
                title: const Text('عدد الفصول'),
                trailing: !chaptersDescending
                    ? const Icon(Icons.check_rounded, color: accent)
                    : null,
                onTap: () {
                  setState(() => chaptersDescending = false);
                  Navigator.pop(context);
                })
          ])));
  void open(Page p) => setState(() {
        page = p;
        selected = null;
      });
  @override
  Widget build(BuildContext c) => Scaffold(
      drawer: drawer(),
      appBar: AppBar(
          backgroundColor: navy,
          elevation: 0,
          title: Row(children: [
            _logo(33),
            const SizedBox(width: 10),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 20))
          ]),
          actions: [
            IconButton(
                icon: const Icon(Icons.sort_rounded), onPressed: showSortMenu),
            IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => showSearch(
                    context: context,
                    delegate: SearchManga((item) {
                      setState(() => selected = item);
                    })))
          ]),
      body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: selected != null
              ? Details(
                  item: selected!,
                  records: recordsFor(selected!),
                  downloadedOnly: page == Page.storage,
                  back: () => setState(() => selected = null),
                  changed: () => setState(() {}),
                  onDownload: (numbers) => enqueueDownload(selected!, numbers),
                  onRead: (numbers, value) =>
                      setRead(selected!, numbers, value))
              : body()));
  Widget body() => !online
      ? OfflineState(onRetry: () => setState(() => online = true))
      : switch (page) {
          Page.latest => Collection(
              items: ordered(manga),
              onTap: (x) => setState(() => selected = x),
              compact: compact,
              header: 'آخر التحديثات'),
          Page.manga => Collection(
              items: ordered(manga),
              onTap: (x) => setState(() => selected = x),
              compact: compact,
              header: 'استكشف المانجا'),
          Page.favorites => Collection(
              items: ordered(manga.where((x) => x.favorite).toList()),
              onTap: (x) => setState(() => selected = x),
              compact: compact,
              header: 'المفضلة'),
          Page.storage => storage(),
          Page.notifications => notices(),
          Page.settings => settings(),
          Page.about => about()
        };
  Widget drawer() => Drawer(
      backgroundColor: surface,
      child: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
            child: Row(children: [
              _logo(48),
              const SizedBox(width: 13),
              const Text('MANGA PLUS',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                      fontSize: 17))
            ])),
        Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
          nav('الأحدث', Icons.auto_awesome_rounded, Page.latest),
          nav('المانجا', Icons.menu_book_rounded, Page.manga),
          nav('المفضلة', Icons.favorite_border_rounded, Page.favorites),
          nav('التخزين', Icons.download_outlined, Page.storage),
          nav('الإشعارات', Icons.notifications_none_rounded,
              Page.notifications),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Divider(color: surface2)),
          nav('الإعدادات', Icons.settings_outlined, Page.settings),
          nav('حول', Icons.info_outline_rounded, Page.about)
        ]))
      ])));
  Widget nav(String text, IconData icon, Page p) {
    final active = page == p && selected == null;
    return ListTile(
        selected: active,
        selectedTileColor: accent.withOpacity(.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: p == Page.notifications && tasks.isNotEmpty
            ? Badge(
                label: Text('${tasks.length}'),
                child: Icon(icon, color: active ? accent : muted))
            : Icon(icon, color: active ? accent : muted),
        title: Text(text,
            style: TextStyle(
                color: active ? Colors.white : muted,
                fontWeight: active ? FontWeight.w700 : null)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22),
        onTap: () {
          Navigator.pop(context);
          open(p);
        });
  }

  Widget storage() {
    final saved =
        manga.where((item) => downloadedFor(item).isNotEmpty).toList();
    if (saved.isEmpty)
      return const EmptyState(
          icon: Icons.download_done_rounded, title: 'لا توجد تنزيلات');
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('التخزين المحلي',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${saved.length} أعمال',
                        style: const TextStyle(color: muted))
                  ]))),
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
          sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, i) {
                final item = saved[i];
                return StorageCard(
                    item: item,
                    count: downloadedFor(item).length,
                    onTap: () => setState(() {
                          selected = item;
                          page = Page.storage;
                        }));
              }, childCount: saved.length),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: .58)))
    ]);
  }

  Widget notices() => tasks.isEmpty
      ? const EmptyState(
          icon: Icons.notifications_none_rounded, title: 'لا توجد تنزيلات')
      : ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
          section('التنزيلات'),
          ...tasks.map((task) => DownloadTaskCard(task: task))
        ]);
  Widget settings() =>
      ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
        section('التفضيلات'),
        setting('إشعارات التحديثات', 'تنبيهات عند صدور فصول جديدة',
            notifications, (v) => setState(() => notifications = v)),
        setting('الاتصال بالإنترنت', 'متصل', online,
            (v) => setState(() => online = v)),
        setting('التنزيل عبر Wi‑Fi فقط', 'تقييد التنزيلات على شبكة Wi‑Fi',
            wifiOnly, (v) => setState(() => wifiOnly = v)),
        setting('عرض مضغوط', 'تقليل المسافات بين البطاقات', compact,
            (v) => setState(() => compact = v)),
        const SizedBox(height: 20),
        section('الحساب'),
        ListTile(
            leading: const Icon(Icons.login_rounded, color: accent),
            title: const Text('تسجيل الدخول'),
            trailing: const Icon(Icons.chevron_left_rounded, color: muted),
            onTap: () {})
      ]);
  Widget about() =>
      ListView(padding: const EdgeInsets.fromLTRB(18, 8, 18, 28), children: [
        const SizedBox(height: 18),
        Center(
            child: Column(children: [
          _logo(104),
          const SizedBox(height: 18),
          const Text('MANGA PLUS',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(height: 6),
          const Text('الإصدار 1.0.0', style: TextStyle(color: muted))
        ])),
        const SizedBox(height: 34),
        section('التطبيق'),
        info(Icons.language_rounded, 'اللغة', 'العربية'),
        info(Icons.shield_outlined, 'الخصوصية', 'سياسة الخصوصية'),
        info(Icons.info_outline_rounded, 'الإصدار', '1.0.0+1')
      ]);
  Widget section(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t,
          style: const TextStyle(
              color: muted, fontWeight: FontWeight.w700, fontSize: 13)));
  Widget setting(String a, String b, bool v, ValueChanged<bool> f) => Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: SwitchListTile(
          value: v,
          onChanged: f,
          activeColor: accent,
          title: Text(a),
          subtitle: Text(b, style: const TextStyle(color: muted)),
          secondary: const Icon(Icons.tune_rounded, color: accent)));
  Widget notice(String a, String b, IconData i) => Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
          contentPadding: const EdgeInsets.all(12),
          leading: CircleAvatar(
              backgroundColor: accent.withOpacity(.16),
              child: Icon(i, color: accent)),
          title: Text(a, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(b, style: const TextStyle(color: muted)),
          trailing: const Icon(Icons.chevron_left_rounded, color: muted)));
  Widget info(IconData i, String a, String b) => Card(
      color: surface,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
          leading: Icon(i, color: accent),
          title: Text(a),
          trailing: Text(b, style: const TextStyle(color: muted))));
  Widget empty(IconData i, String t) => EmptyState(icon: i, title: t);
}

class Collection extends StatelessWidget {
  final List<MangaItem> items;
  final ValueChanged<MangaItem> onTap;
  final bool compact;
  final String header;
  const Collection(
      {super.key,
      required this.items,
      required this.onTap,
      required this.compact,
      required this.header});
  @override
  Widget build(BuildContext c) => items.isEmpty
      ? const EmptyState(
          icon: Icons.favorite_border_rounded, title: 'لا توجد مانجا مفضلة')
      : CustomScrollView(slivers: [
          SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(header,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${items.length} عناوين',
                            style: const TextStyle(color: muted))
                      ]))),
          SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, compact ? 12 : 24),
              sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                      (c, i) =>
                          CardManga(item: items[i], tap: () => onTap(items[i])),
                      childCount: items.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: .58)))
        ]);
}

class CardManga extends StatelessWidget {
  final MangaItem item;
  final VoidCallback tap;
  const CardManga({super.key, required this.item, required this.tap});
  @override
  Widget build(BuildContext c) => InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(fit: StackFit.expand, children: [
                  Hero(
                      tag: item.asset,
                      child: Image.asset(item.asset, fit: BoxFit.cover)),
                  Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(item.status,
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold))))
                ]))),
        const SizedBox(height: 8),
        Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 3),
        Text('${item.chapters} فصل  •  ${item.tags.first}',
            style: const TextStyle(color: muted, fontSize: 11))
      ]));
}

class Details extends StatefulWidget {
  final MangaItem item;
  final VoidCallback back, changed;
  final Map<int, ChapterRecord> records;
  final bool downloadedOnly;
  final ValueChanged<List<int>> onDownload;
  final void Function(List<int>, bool) onRead;
  const Details(
      {super.key,
      required this.item,
      required this.back,
      required this.changed,
      required this.records,
      required this.downloadedOnly,
      required this.onDownload,
      required this.onRead});
  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final Set<int> selected = {};
  bool selecting = false;
  @override
  Widget build(BuildContext c) => CustomScrollView(slivers: [
        SliverToBoxAdapter(
            child: Stack(children: [
          SizedBox(
              height: 300,
              width: double.infinity,
              child: Image.asset(widget.item.asset, fit: BoxFit.cover)),
          Positioned.fill(
              child: DecoratedBox(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black26, navy])))),
          Positioned(
              top: 12,
              right: 12,
              child: IconButton.filledTonal(
                  onPressed: widget.back,
                  icon: const Icon(Icons.arrow_forward_rounded))),
          Positioned(
              bottom: 22,
              right: 20,
              left: 20,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(widget.item.asset,
                        width: 92, height: 132, fit: BoxFit.cover)),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.item.title,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                      Text(widget.item.subtitle,
                          style: const TextStyle(color: muted)),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 6,
                          children: widget.item.tags
                              .map((x) => Chip(
                                  label: Text(x,
                                      style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                  side: BorderSide.none,
                                  backgroundColor: accent.withOpacity(.18)))
                              .toList()),
                    ])),
              ])),
        ])),
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
            sliver: SliverToBoxAdapter(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('ابدأ القراءة'))),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                        onPressed: () {
                          widget.item.favorite = !widget.item.favorite;
                          widget.changed();
                        },
                        icon: Icon(
                            widget.item.favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: widget.item.favorite
                                ? Colors.redAccent
                                : null)),
                  ]),
                  const SizedBox(height: 24),
                  const Text('نبذة',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.item.description,
                      style: const TextStyle(color: muted, height: 1.7)),
                  const SizedBox(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الفصول',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${widget.item.chapters} فصل',
                            style: const TextStyle(color: accent))
                      ]),
                  const SizedBox(height: 10),
                  if (selecting)
                    SelectionBar(
                        selected: selected,
                        total: widget.item.chapters,
                        onAll: () => setState(() => selected.addAll(
                            List.generate(widget.item.chapters,
                                (i) => widget.item.chapters - i))),
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
                        }),
                  ...List.generate(8, (i) => widget.item.chapters - i)
                      .where((n) =>
                          !widget.downloadedOnly ||
                          widget.records[n]?.download == DownloadStatus.success)
                      .map((n) => ChapterTile(
                          number: n,
                          record: widget.records[n],
                          selected: selected.contains(n),
                          onLongPress: () => setState(() {
                                selecting = true;
                                selected.add(n);
                              }),
                          onTap: () {
                            if (selecting)
                              setState(() {
                                selected.contains(n)
                                    ? selected.remove(n)
                                    : selected.add(n);
                                if (selected.isEmpty) selecting = false;
                              });
                            else {
                              widget.records
                                  .putIfAbsent(n, ChapterRecord.new)
                                  .read = true;
                              widget.changed();
                            }
                          })),
                ]))),
      ]);
}

class SelectionBar extends StatelessWidget {
  final Set<int> selected;
  final int total;
  final VoidCallback onAll, onDownload;
  final ValueChanged<bool> onRead;
  const SelectionBar(
      {super.key,
      required this.selected,
      required this.total,
      required this.onAll,
      required this.onDownload,
      required this.onRead});
  @override
  Widget build(BuildContext context) => Card(
      color: surface2,
      child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${selected.length} محدد'),
                TextButton(onPressed: onAll, child: const Text('تحديد الكل')),
                IconButton(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download_rounded)),
                IconButton(
                    onPressed: () => onRead(true),
                    icon: const Icon(Icons.done_all_rounded)),
                IconButton(
                    onPressed: () => onRead(false),
                    icon: const Icon(Icons.mark_email_unread_outlined))
              ])));
}

class ChapterTile extends StatelessWidget {
  final int number;
  final ChapterRecord? record;
  final bool selected;
  final VoidCallback onLongPress, onTap;
  const ChapterTile(
      {super.key,
      required this.number,
      this.record,
      required this.selected,
      required this.onLongPress,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final status = record?.download ?? DownloadStatus.idle;
    final icon = status == DownloadStatus.success
        ? Icons.download_done_rounded
        : status == DownloadStatus.failed
            ? Icons.error_outline_rounded
            : status == DownloadStatus.downloading
                ? Icons.downloading_rounded
                : Icons.download_outlined;
    return Card(
        color: selected ? accent.withOpacity(.18) : surface,
        child: ListTile(
            onTap: onTap,
            onLongPress: onLongPress,
            leading: CircleAvatar(
                backgroundColor: accent.withOpacity(.14),
                child: Text('$number',
                    style: const TextStyle(color: accent, fontSize: 12))),
            title: Text('الفصل $number',
                style: TextStyle(
                    fontWeight: record?.read == true
                        ? FontWeight.normal
                        : FontWeight.bold)),
            subtitle: Text(record?.read == true ? 'مقروء' : 'غير مقروء',
                style: const TextStyle(color: muted)),
            trailing: status == DownloadStatus.downloading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: accent))
                : Icon(icon,
                    color: status == DownloadStatus.failed
                        ? Colors.redAccent
                        : status == DownloadStatus.success
                            ? accent
                            : muted)));
  }
}

class StorageCard extends StatelessWidget {
  final MangaItem item;
  final int count;
  final VoidCallback onTap;
  const StorageCard(
      {super.key,
      required this.item,
      required this.count,
      required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(item.asset, fit: BoxFit.cover),
                  Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('$count فصل',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold))))
                ]))),
        const SizedBox(height: 8),
        Text(item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        const Text('متاح بدون إنترنت',
            style: TextStyle(color: muted, fontSize: 11))
      ]));
}

class DownloadTaskCard extends StatelessWidget {
  final DownloadTask task;
  const DownloadTaskCard({super.key, required this.task});
  @override
  Widget build(BuildContext context) {
    final failed = task.status == DownloadStatus.failed,
        success = task.status == DownloadStatus.success;
    return Card(
        color: surface,
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Image.asset(task.item.asset,
                    width: 44, height: 58, fit: BoxFit.cover),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(task.item.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(task.label,
                          style: const TextStyle(color: muted, fontSize: 12))
                    ])),
                Icon(
                    failed
                        ? Icons.error_outline_rounded
                        : success
                            ? Icons.check_circle_outline_rounded
                            : Icons.downloading_rounded,
                    color: failed
                        ? Colors.redAccent
                        : success
                            ? accent
                            : muted)
              ]),
              if (!success && !failed) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                    value: task.progress,
                    color: accent,
                    backgroundColor: surface2),
                const SizedBox(height: 6),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${(task.progress * 100).round()}%',
                        style: const TextStyle(color: muted, fontSize: 11)))
              ],
              if (failed)
                const Align(
                    alignment: Alignment.centerRight,
                    child: Text('فشل التنزيل',
                        style:
                            TextStyle(color: Colors.redAccent, fontSize: 12))),
              if (success)
                const Align(
                    alignment: Alignment.centerRight,
                    child: Text('تم التنزيل',
                        style: TextStyle(color: accent, fontSize: 12)))
            ])));
  }
}

class SearchManga extends SearchDelegate<MangaItem?> {
  final ValueChanged<MangaItem> open;
  SearchManga(this.open);
  @override
  List<Widget>? buildActions(BuildContext c) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];
  @override
  Widget? buildLeading(BuildContext c) => IconButton(
      onPressed: () => close(c, null), icon: const Icon(Icons.arrow_back));
  @override
  Widget buildResults(BuildContext c) => results(c);
  @override
  Widget buildSuggestions(BuildContext c) => results(c);
  Widget results(BuildContext c) {
    final found = manga
        .where((x) =>
            x.title.contains(query) ||
            x.subtitle.toLowerCase().contains(query.toLowerCase()))
        .toList();
    if (found.isEmpty)
      return const EmptyState(
          icon: Icons.search_off_rounded, title: 'لا توجد نتائج');
    return ListView.builder(
        itemCount: found.length,
        itemBuilder: (_, i) => ListTile(
            onTap: () {
              close(c, found[i]);
              open(found[i]);
            },
            leading: Image.asset(found[i].asset,
                width: 44, height: 58, fit: BoxFit.cover),
            title: Text(found[i].title),
            subtitle:
                Text(found[i].subtitle, style: const TextStyle(color: muted))));
  }
}
