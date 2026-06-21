import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'movie.dart';

void main() {
  runApp(const MiniDoubanApp());
}

class MiniDoubanApp extends StatelessWidget {
  const MiniDoubanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniDouban',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MovieListPage(),
    );
  }
}

class MovieListPage extends StatefulWidget {
  const MovieListPage({super.key});

  @override
  State<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  static final Uri _remoteUri = Uri.parse(
    'https://raw.githubusercontent.com/dreamapplehappy/hacking-with-flutter/master/douban.json',
  );

  List<Movie> _movies = const <Movie>[];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final http.Response response = await http.get(_remoteUri);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final List<Movie> movies = _parseMovies(response.body);
      setState(() {
        _movies = movies;
        _loading = false;
        _message = '数据来自远程服务器';
      });
    } catch (error) {
      final List<Movie> fallback = await _loadFallbackMovies();
      setState(() {
        _movies = fallback;
        _loading = false;
        _message = '远程数据暂不可用，已加载本地备用数据：$error';
      });
    }
  }

  List<Movie> _parseMovies(String body) {
    final Object decoded = json.decode(body);
    final Object? source = decoded is Map<String, dynamic>
        ? decoded['subjects'] ?? decoded['movies'] ?? decoded['data']
        : decoded;
    if (source is! List) {
      throw const FormatException('电影列表格式不正确');
    }
    return source
        .whereType<Map<String, dynamic>>()
        .map(Movie.fromJson)
        .where((Movie movie) => movie.title.isNotEmpty)
        .toList();
  }

  Future<List<Movie>> _loadFallbackMovies() async {
    final String text = await rootBundle.loadString(
      'assets/json/movies_fallback.json',
    );
    final List<dynamic> list = json.decode(text) as List<dynamic>;
    return list
        .map((dynamic item) => Movie.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniDouban'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: _loading ? null : _loadMovies,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: <Widget>[
        if (_message != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _message!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (BuildContext context, int index) {
              return MovieCard(rank: index + 1, movie: _movies[index]);
            },
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 12),
            itemCount: _movies.length,
          ),
        ),
      ],
    );
  }
}

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.rank, required this.movie});

  final int rank;
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RankingBadge(rank: rank),
            const SizedBox(width: 12),
            MoviePoster(url: movie.coverUrl),
            const SizedBox(width: 14),
            Expanded(child: MovieInfo(movie: movie)),
          ],
        ),
      ),
    );
  }
}

class RankingBadge extends StatelessWidget {
  const RankingBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url,
        width: 82,
        height: 116,
        fit: BoxFit.cover,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
          return Container(
            width: 82,
            height: 116,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Icon(Icons.movie_outlined),
          );
        },
      ),
    );
  }
}

class MovieInfo extends StatelessWidget {
  const MovieInfo({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final String directorText = movie.directors.isEmpty
        ? '导演：未知'
        : '导演：${movie.directors.join(' / ')}';
    final String genreText = movie.genres.isEmpty
        ? movie.year
        : '${movie.year} · ${movie.genres.join(' / ')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          movie.title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            const Icon(Icons.star, size: 18, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              movie.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(genreText, overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 6),
        Text(directorText, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text(
          movie.summary,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
