class VideoModel {
  final String title;
  final String description;
  final String subtitle;
  final String thumb;
  final List<String> sources;

  VideoModel({
    required this.title,
    required this.description,
    required this.subtitle,
    required this.thumb,
    required this.sources,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      subtitle: json['subtitle'] ?? '',
      thumb: json['thumb'] ?? '',
      sources: List<String>.from(json['sources'] ?? []),
    );
  }
}

class CategoryModel {
  final String name;
  final List<VideoModel> videos;

  CategoryModel({
    required this.name,
    required this.videos,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      name: json['name'] ?? '',
      videos: (json['videos'] as List<dynamic>?)
          ?.map((video) => VideoModel.fromJson(video))
          .toList() ?? [],
    );
  }
}