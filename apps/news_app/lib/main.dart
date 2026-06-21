import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NewsLab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff006d77)),
        useMaterial3: true,
      ),
      home: const NewsHomePage(),
    );
  }
}

class NewsItem {
  const NewsItem({
    required this.id,
    required this.title,
    required this.source,
    required this.time,
    required this.imageUrl,
    required this.summary,
    required this.content,
  });

  final int id;
  final String title;
  final String source;
  final String time;
  final String imageUrl;
  final String summary;
  final String content;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as int,
      title: json['title'] as String,
      source: json['source'] as String,
      time: json['time'] as String,
      imageUrl: json['imageUrl'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String,
    );
  }
}

class FavoriteStore {
  Database? _database;
  final Set<int> _webFallback = <int>{};

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final String dbPath = path.join(await getDatabasesPath(), 'news_app.db');
    _database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) {
        return db.execute(
          'CREATE TABLE favorites(id INTEGER PRIMARY KEY, title TEXT, time TEXT)',
        );
      },
    );
    return _database!;
  }

  Future<Set<int>> loadFavoriteIds() async {
    if (kIsWeb) {
      return _webFallback;
    }
    try {
      final Database db = await database;
      final List<Map<String, Object?>> rows = await db.query('favorites');
      return rows.map((Map<String, Object?> row) => row['id'] as int).toSet();
    } catch (_) {
      return _webFallback;
    }
  }

  Future<void> setFavorite(NewsItem item, bool favorite) async {
    if (favorite) {
      _webFallback.add(item.id);
    } else {
      _webFallback.remove(item.id);
    }
    if (kIsWeb) {
      return;
    }
    try {
      final Database db = await database;
      if (favorite) {
        await db.insert(
          'favorites',
          <String, Object?>{
            'id': item.id,
            'title': item.title,
            'time': item.time,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await db.delete(
          'favorites',
          where: 'id = ?',
          whereArgs: <Object>[item.id],
        );
      }
    } catch (_) {
      return;
    }
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({super.key});

  @override
  State<NewsHomePage> createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final FavoriteStore _favoriteStore = FavoriteStore();
  List<NewsItem> _news = <NewsItem>[];
  Set<int> _favorites = <int>{};
  NewsItem? _selected;
  bool _loading = true;
  String _message = '正在加载新闻...';

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _message = '正在请求 Mock 新闻接口...';
    });
    try {
      await http
          .get(Uri.parse('https://example.invalid/mock-news.json'))
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // 先走网络请求流程，再回退到随包提交的本地 JSON 数据。
    }
    final String raw = await rootBundle.loadString('assets/news.json');
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final List<NewsItem> items = decoded
        .map((dynamic item) => NewsItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final Set<int> favorites = await _favoriteStore.loadFavoriteIds();
    setState(() {
      _news = items;
      _favorites = favorites;
      _selected = items.isEmpty ? null : items.first;
      _loading = false;
      _message = '已通过 Mock 网络流程加载本地新闻数据';
    });
  }

  Future<void> _toggleFavorite(NewsItem item) async {
    final bool next = !_favorites.contains(item.id);
    await _favoriteStore.setFavorite(item, next);
    setState(() {
      if (next) {
        _favorites.add(item.id);
      } else {
        _favorites.remove(item.id);
      }
    });
  }

  void _openDetail(NewsItem item, bool wide) {
    setState(() => _selected = item);
    if (!wide) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => NewsDetailPage(
            item: item,
            favorite: _favorites.contains(item.id),
            onToggleFavorite: () => _toggleFavorite(item),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NewsLab'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: _loadNews,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool wide = constraints.maxWidth >= 720;
                  final Widget list = NewsList(
                    items: _news,
                    favorites: _favorites,
                    selected: _selected,
                    message: _message,
                    onTap: (NewsItem item) => _openDetail(item, wide),
                    onToggleFavorite: _toggleFavorite,
                  );
                  if (!wide) {
                    return list;
                  }
                  return Row(
                    children: <Widget>[
                      SizedBox(width: 390, child: list),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: _selected == null
                            ? const Center(child: Text('请选择一条新闻'))
                            : NewsDetailView(
                                item: _selected!,
                                favorite: _favorites.contains(_selected!.id),
                                onToggleFavorite: () =>
                                    _toggleFavorite(_selected!),
                              ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

class NewsList extends StatelessWidget {
  const NewsList({
    super.key,
    required this.items,
    required this.favorites,
    required this.selected,
    required this.message,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final List<NewsItem> items;
  final Set<int> favorites;
  final NewsItem? selected;
  final String message;
  final ValueChanged<NewsItem> onTap;
  final ValueChanged<NewsItem> onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Text(message, style: Theme.of(context).textTheme.labelLarge);
        }
        final NewsItem item = items[index - 1];
        return NewsCard(
          item: item,
          selected: selected?.id == item.id,
          favorite: favorites.contains(item.id),
          onTap: () => onTap(item),
          onToggleFavorite: () => onToggleFavorite(item),
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const SizedBox(height: 12),
      itemCount: items.length + 1,
    );
  }
}

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.item,
    required this.selected,
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final NewsItem item;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NewsImage(url: item.imageUrl, width: 96, height: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.source} · ${item.time}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: favorite ? '取消收藏' : '收藏',
                onPressed: onToggleFavorite,
                icon: Icon(favorite ? Icons.star : Icons.star_border),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsImage extends StatelessWidget {
  const NewsImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
        ) =>
            Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.image),
        ),
      ),
    );
  }
}

class NewsDetailPage extends StatelessWidget {
  const NewsDetailPage({
    super.key,
    required this.item,
    required this.favorite,
    required this.onToggleFavorite,
  });

  final NewsItem item;
  final bool favorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新闻详情')),
      body: NewsDetailView(
        item: item,
        favorite: favorite,
        onToggleFavorite: onToggleFavorite,
      ),
    );
  }
}

class NewsDetailView extends StatelessWidget {
  const NewsDetailView({
    super.key,
    required this.item,
    required this.favorite,
    required this.onToggleFavorite,
  });

  final NewsItem item;
  final bool favorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('${item.source} · ${item.time}'),
        const SizedBox(height: 16),
        NewsImage(url: item.imageUrl, width: double.infinity, height: 220),
        const SizedBox(height: 16),
        Text(item.content, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: <Widget>[
            FilledButton.icon(
              onPressed: onToggleFavorite,
              icon: Icon(favorite ? Icons.star : Icons.star_border),
              label: Text(favorite ? '取消收藏' : '收藏到 SQLite'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => CommentPage(item: item),
                  ),
                );
              },
              icon: const Icon(Icons.comment),
              label: const Text('写评论'),
            ),
          ],
        ),
      ],
    );
  }
}

class CommentPage extends StatefulWidget {
  const CommentPage({super.key, required this.item});

  final NewsItem item;

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _photo;
  String _status = '评论会提交到 Mock 接口';

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 900,
    );
    if (image != null) {
      setState(() => _photo = image);
    }
  }

  Future<void> _submit() async {
    setState(() => _status = '正在上传评论...');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await http
        .post(
          Uri.parse('https://example.invalid/mock-comment'),
          body: <String, String>{
            'newsId': widget.item.id.toString(),
            'comment': _controller.text,
            'hasPhoto': (_photo != null).toString(),
          },
        )
        .catchError((_) => http.Response('mock ok', 200));
    setState(() => _status = 'Mock 接口返回成功，评论已记录');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新闻评论')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(widget.item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: '评论内容',
            ),
            minLines: 3,
            maxLines: 5,
          ),
          const SizedBox(height: 12),
          if (_photo != null && !kIsWeb)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_photo!.path),
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('拍照'),
              ),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('上传评论'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_status),
        ],
      ),
    );
  }
}
