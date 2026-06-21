class Movie {
  const Movie({
    required this.title,
    required this.year,
    required this.rating,
    required this.directors,
    required this.genres,
    required this.coverUrl,
    required this.summary,
  });

  final String title;
  final String year;
  final double rating;
  final List<String> directors;
  final List<String> genres;
  final String coverUrl;
  final String summary;

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] as String? ?? '',
      year: (json['year'] as Object?)?.toString() ?? '',
      rating: _readRating(json['rating']),
      directors: _readStringList(json['directors']),
      genres: _readStringList(json['genres']),
      coverUrl: json['coverUrl'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
    );
  }

  static double _readRating(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is Map<String, dynamic>) {
      final Object? average = value['average'];
      if (average is num) {
        return average.toDouble();
      }
    }
    return 0;
  }

  static List<String> _readStringList(Object? value) {
    if (value is List) {
      return value.map((Object? item) => item.toString()).toList();
    }
    return const <String>[];
  }
}
