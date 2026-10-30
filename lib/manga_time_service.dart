import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MangaTimeSeries {
  final String id;
  final String title;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String coverUrl;
  final String type;
  final String status;
  final String description;
  final List<String> genres;
  final double rating;
  final int chapterCount;
  final String? latestChapter;
  final DateTime? latestDate;

  const MangaTimeSeries({
    required this.id,
    required this.title,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    required this.coverUrl,
    required this.type,
    required this.status,
    required this.description,
    required this.genres,
    required this.rating,
    required this.chapterCount,
    required this.latestChapter,
    required this.latestDate,
  });
}

class MangaTimeChapter {
  final String id;
  final String number;
  final String title;
  final DateTime? publishedAt;
  final int pageCount;
  final bool unlocked;

  const MangaTimeChapter({
    required this.id,
    required this.number,
    required this.title,
    required this.publishedAt,
    required this.pageCount,
    required this.unlocked,
  });
}

class MangaTimeDetails {
  final MangaTimeSeries series;
  final String? author;
  final String? artist;
  final String sourceName;
  final String sourceLogo;
  final List<MangaTimeChapter> chapters;

  const MangaTimeDetails({
    required this.series,
    required this.author,
    required this.artist,
    required this.sourceName,
    required this.sourceLogo,
    required this.chapters,
  });
}

class MangaTimeService {
  static const baseUrl = 'https://mangatime.org';
  static const _cacheLife = Duration(minutes: 5);
  static const _detailsLife = Duration(minutes: 15);

  final HttpClient _client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  final Map<String, _CacheEntry<List<MangaTimeSeries>>> _seriesCache = {};
  final Map<String, _CacheEntry<MangaTimeDetails>> _detailsCache = {};
  final Map<String, List<String>> _pagesCache = {};

  void close() => _client.close(force: true);

  Future<List<MangaTimeSeries>> searchSeries({
    required String sortBy,
    String? query,
    int page = 1,
    int limit = 24,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$sortBy|${query ?? ''}|$page|$limit';
    final cached = _seriesCache[cacheKey];
    if (!forceRefresh && cached != null && !cached.expired(_cacheLife)) return cached.value;
    if (!forceRefresh) {
      final disk = await _readSeriesCache(cacheKey);
      if (disk != null) {
        _seriesCache[cacheKey] = _CacheEntry(disk);
        return disk;
      }
    }

    final payload = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortOrder': 'desc',
      if (query != null && query.trim().isNotEmpty) 'query': query.trim(),
    };
    final data = await _query('search.searchSeries', payload);
    final results = (data['results'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _seriesFromJson(Map<String, dynamic>.from(item)))
        .toList();
    _seriesCache[cacheKey] = _CacheEntry(results);
    unawaited(_writeSeriesCache(cacheKey, results));
    return results;
  }

  Future<MangaTimeDetails> fetchDetails(String slug, {bool forceRefresh = false}) async {
    final cached = _detailsCache[slug];
    if (!forceRefresh && cached != null && !cached.expired(_detailsLife)) return cached.value;
    if (!forceRefresh) {
      final disk = await _readDetailsCache(slug);
      if (disk != null) {
        _detailsCache[slug] = _CacheEntry(disk);
        return disk;
      }
    }

    final detailsJson = await _query('content.getSeriesBySlug', {'slug': slug});
    final id = (detailsJson['id'] ?? '').toString();
    final chaptersFuture = _query('content.getChapters', {'seriesId': id, 'limit': -1});
    final chaptersJson = await chaptersFuture;
    final series = _seriesFromJson(detailsJson);
    final chapters = (chaptersJson['chapters'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _chapterFromJson(Map<String, dynamic>.from(item)))
        .toList();
    final result = MangaTimeDetails(
      series: series,
      author: _nullableString(detailsJson['author']),
      artist: _nullableString(detailsJson['artist']),
      sourceName: _teamName(detailsJson),
      sourceLogo: _teamLogo(detailsJson),
      chapters: chapters,
    );
    _detailsCache[slug] = _CacheEntry(result);
    unawaited(_writeDetailsCache(slug, result));
    return result;
  }

  Future<List<String>> fetchPages(String slug, String chapterNumber) async {
    final key = '$slug|$chapterNumber';
    final cached = _pagesCache[key];
    if (cached != null) return cached;
    final data = await _query('content.getChapterPages', {
      'seriesSlug': slug,
      'chapterNumber': int.tryParse(chapterNumber) ?? chapterNumber,
    });
    if (data['isUnlocked'] == false) throw StateError('الفصل مقفل');
    final pages = (data['pages'] as List? ?? const [])
        .map((url) => _imageUrl(url.toString()))
        .where((url) => url.isNotEmpty)
        .toList();
    _pagesCache[key] = pages;
    return pages;
  }

  Future<void> downloadChapters({
    required String slug,
    required List<String> chapterNumbers,
    required void Function(double progress) onProgress,
  }) async {
    if (chapterNumbers.isEmpty) return;
    final root = await getApplicationDocumentsDirectory();
    final safeSlug = slug.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    var completed = 0;
    for (final chapter in chapterNumbers) {
      final pages = await fetchPages(slug, chapter);
      final chapterDir = Directory('${root.path}/manga_time/$safeSlug/$chapter');
      await chapterDir.create(recursive: true);
      for (var index = 0; index < pages.length; index++) {
        final file = File('${chapterDir.path}/${(index + 1).toString().padLeft(3, '0')}.webp');
        if (!await file.exists()) {
          final response = await _client.getUrl(Uri.parse(pages[index])).then((request) => request.close());
          if (response.statusCode < 200 || response.statusCode >= 300) {
            throw HttpException('تعذر حفظ صفحة الفصل', uri: Uri.parse(pages[index]));
          }
          final bytes = <int>[];
          await for (final chunk in response) {
            bytes.addAll(chunk);
          }
          await file.writeAsBytes(bytes, flush: false);
        }
      }
      completed++;
      onProgress(completed / chapterNumbers.length);
    }
  }

  Future<Set<String>> readDownloadedManifest() async {
    try {
      final file = File('${(await _cacheDirectory()).path}/downloads.json');
      if (!await file.exists()) return <String>{};
      return (jsonDecode(await file.readAsString()) as List).map((item) => item.toString()).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> markDownloaded(String slug, List<String> chapters) async {
    final entries = await readDownloadedManifest();
    entries.addAll(chapters.map((chapter) => '$slug|$chapter'));
    final file = File('${(await _cacheDirectory()).path}/downloads.json');
    await file.writeAsString(jsonEncode(entries.toList()));
  }

  Future<Map<String, dynamic>> _query(String endpoint, Map<String, dynamic> payload) async {
    final envelope = jsonEncode({'0': {'json': payload}});
    final uri = Uri.parse('$baseUrl/api/trpc/$endpoint').replace(
      queryParameters: {'batch': '1', 'input': envelope},
    );
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.headers.set(HttpHeaders.userAgentHeader, 'MangaPlus/1.0');
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Manga Time returned ${response.statusCode}', uri: uri);
    }
    final decoded = jsonDecode(body);
    final root = decoded is List && decoded.isNotEmpty ? decoded.first : decoded;
    dynamic data = root['result']['data'];
    if (data is Map && data.containsKey('json')) data = data['json'];
    if (data is! Map) throw const FormatException('استجابة Manga Time غير صالحة');
    return Map<String, dynamic>.from(data);
  }

  MangaTimeSeries _seriesFromJson(Map<String, dynamic> json) {
    final latest = json['latestChapter'] is Map ? Map<String, dynamic>.from(json['latestChapter']) : null;
    final rating = _asDouble(json['rating'] ?? (json['stats'] is Map ? json['stats']['rating'] : null));
    return MangaTimeSeries(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? json['nameAr'] ?? json['nameEn'] ?? 'بدون عنوان').toString(),
      nameAr: (json['nameAr'] ?? json['title'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      coverUrl: _imageUrl((json['coverUrl'] ?? '').toString()),
      type: (json['type'] ?? '').toString(),
      status: _status((json['status'] ?? '').toString()),
      description: (json['description'] ?? '').toString(),
      genres: (json['genres'] as List? ?? const []).map((genre) {
        if (genre is Map) return (genre['name'] ?? '').toString();
        return genre.toString();
      }).where((genre) => genre.isNotEmpty).toList(),
      rating: rating,
      chapterCount: _asInt(json['chapterCount'] ?? (json['stats'] is Map ? json['stats']['chapterCount'] : null)),
      latestChapter: latest == null ? null : (latest['number'] ?? '').toString(),
      latestDate: _date(latest?['releasedAt'] ?? json['lastChapterAt'] ?? json['updatedAt']),
    );
  }

  MangaTimeChapter _chapterFromJson(Map<String, dynamic> json) {
    return MangaTimeChapter(
      id: (json['id'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      title: (json['title'] ?? 'الفصل ${json['number'] ?? ''}').toString(),
      publishedAt: _date(json['publishedAt'] ?? json['createdAt']),
      pageCount: _asInt(json['pageCount']),
      unlocked: json['isUnlocked'] != false,
    );
  }

  String _imageUrl(String value) => value.startsWith('http') ? value : '$baseUrl$value';

  String _teamName(Map<String, dynamic> json) {
    final team = json['team'];
    return team is Map ? (team['name'] ?? '').toString() : '';
  }

  String _teamLogo(Map<String, dynamic> json) {
    final team = json['team'];
    final logo = team is Map ? (team['logo'] ?? '').toString() : '';
    return logo.isEmpty ? '' : _imageUrl(logo);
  }

  Future<Directory> _cacheDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/manga_time_cache');
    await directory.create(recursive: true);
    return directory;
  }

  String _cacheName(String value) => base64Url.encode(utf8.encode(value)).replaceAll('=', '_');

  Future<List<MangaTimeSeries>?> _readSeriesCache(String key) async {
    try {
      final file = File('${(await _cacheDirectory()).path}/series_${_cacheName(key)}.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      final saved = DateTime.tryParse(json['savedAt'].toString());
      if (saved == null || DateTime.now().difference(saved) > _cacheLife) return null;
      return (json['items'] as List).map((item) => _seriesFromJson(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeSeriesCache(String key, List<MangaTimeSeries> items) async {
    try {
      final file = File('${(await _cacheDirectory()).path}/series_${_cacheName(key)}.json');
      await file.writeAsString(jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'items': items.map(_seriesToJson).toList(),
      }));
    } catch (_) {}
  }

  Future<MangaTimeDetails?> _readDetailsCache(String slug) async {
    try {
      final file = File('${(await _cacheDirectory()).path}/details_${_cacheName(slug)}.json');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      final saved = DateTime.tryParse(json['savedAt'].toString());
      if (saved == null || DateTime.now().difference(saved) > _detailsLife) return null;
      final series = _seriesFromJson(Map<String, dynamic>.from(json['series']));
      final chapters = (json['chapters'] as List).map((item) => _chapterFromJson(Map<String, dynamic>.from(item))).toList();
      return MangaTimeDetails(
        series: series,
        author: json['author']?.toString(),
        artist: json['artist']?.toString(),
        sourceName: json['sourceName']?.toString() ?? '',
        sourceLogo: json['sourceLogo']?.toString() ?? '',
        chapters: chapters,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDetailsCache(String slug, MangaTimeDetails details) async {
    try {
      final file = File('${(await _cacheDirectory()).path}/details_${_cacheName(slug)}.json');
      await file.writeAsString(jsonEncode({
        'savedAt': DateTime.now().toIso8601String(),
        'series': _seriesToJson(details.series),
        'author': details.author,
        'artist': details.artist,
        'sourceName': details.sourceName,
        'sourceLogo': details.sourceLogo,
        'chapters': details.chapters.map(_chapterToJson).toList(),
      }));
    } catch (_) {}
  }

  Map<String, dynamic> _seriesToJson(MangaTimeSeries item) => {
        'id': item.id,
        'title': item.title,
        'nameAr': item.nameAr,
        'nameEn': item.nameEn,
        'slug': item.slug,
        'coverUrl': item.coverUrl,
        'type': item.type,
        'status': item.status,
        'description': item.description,
        'genres': item.genres,
        'rating': item.rating,
        'chapterCount': item.chapterCount,
        'latestChapter': item.latestChapter == null ? null : {'number': item.latestChapter, 'releasedAt': item.latestDate?.toIso8601String()},
      };

  Map<String, dynamic> _chapterToJson(MangaTimeChapter item) => {
        'id': item.id,
        'number': item.number,
        'title': item.title,
        'publishedAt': item.publishedAt?.toIso8601String(),
        'pageCount': item.pageCount,
        'isUnlocked': item.unlocked,
      };

  String _status(String value) => switch (value.toLowerCase()) {
        'completed' || 'مكتمل' => 'مكتمل',
        'hiatus' || 'متوقف' => 'متوقف',
        'cancelled' || 'ملغى' => 'ملغى',
        _ => 'مستمر',
      };

  static DateTime? _date(dynamic value) => value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
  static String? _nullableString(dynamic value) => value == null || value.toString().isEmpty ? null : value.toString();
  static int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
  static double _asDouble(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
}

class _CacheEntry<T> {
  final T value;
  final DateTime createdAt = DateTime.now();

  _CacheEntry(this.value);

  bool expired(Duration life) => DateTime.now().difference(createdAt) > life;
}

String mangaTimeRelativeDate(DateTime? date) {
  if (date == null) return '—';
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.isNegative || difference.inSeconds < 60) return 'قبل لحظات';
  if (difference.inMinutes < 60) return 'قبل ${difference.inMinutes} دقيقة';
  if (difference.inHours < 2) return 'قبل ساعة';
  if (difference.inHours < 24) return 'قبل ${difference.inHours} ساعة';
  if (difference.inDays == 1) return 'أمس';
  if (difference.inDays == 2) return 'أول أمس';
  if (difference.inDays < 7) return 'قبل ${difference.inDays} أيام';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
