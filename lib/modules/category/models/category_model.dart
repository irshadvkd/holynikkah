import 'dart:convert';

/// categories : [{"catId":1,"name":"Middle Class","networth":"$2-$25","icon":"home"},{"catId":2,"name":"Upper Middle Class","networth":"$50-$100","icon":"house"},{"catId":3,"name":"HNI (Rich)","networth":"$2-$25","icon":"bank"},{"catId":4,"name":"Super Rich","networth":"$25-$50","icon":"business"},{"catId":5,"name":"Ultra Rich","networth":"$50-$100","icon":"flight"},{"catId":6,"name":"Billionaire","networth":"$800","icon":"car"}]

CategoryModel categoryModelFromJson(String str) =>
    CategoryModel.fromJson(json.decode(str));
String categoryModelToJson(CategoryModel data) => json.encode(data.toJson());

class CategoryModel {
  CategoryModel({this.categories});

  CategoryModel.fromJson(dynamic json) {
    if (json['categories'] != null) {
      categories = [];
      json['categories'].forEach((v) {
        categories?.add(Categories.fromJson(v));
      });
    }
  }
  List<Categories>? categories;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (categories != null) {
      map['categories'] = categories?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

Categories categoriesFromJson(String str) =>
    Categories.fromJson(json.decode(str));
String categoriesToJson(Categories data) => json.encode(data.toJson());

class Categories {
  Categories({
    this.catId,
    this.name,
    this.networth,
    this.bgColor,
    this.textColor,
    this.sortOrder,
    this.gradientEndColor,
    this.icon,
  });

  Categories.fromJson(dynamic json) {
    catId = (json['catId'] ?? json['id'])?.toString();
    name = json['name'] ?? json['title'];
    networth = json['networth'];
    bgColor =
        json['bgColor'] ??
        json['bg_color'] ??
        json['grad_color1'] ??
        json['button_bg_color'];
    textColor =
        json['textColor'] ??
        json['text_color'] ??
        json['button_text_color'];
    sortOrder = _int(json['sort_order']);
    gradientEndColor = json['gradient_end_color'] ??
        json['gradientEndColor'] ??
        json['grad_color2'];
    icon = json['icon'];
  }
  String? catId;
  String? name;
  String? networth;
  String? bgColor;
  String? textColor;
  int? sortOrder;
  String? gradientEndColor;
  String? icon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['catId'] = catId;
    map['name'] = name;
    map['networth'] = networth;
    map['bgColor'] = bgColor;
    map['grad_color1'] = bgColor;
    map['textColor'] = textColor;
    map['sort_order'] = sortOrder;
    map['gradient_end_color'] = gradientEndColor;
    map['grad_color2'] = gradientEndColor;
    map['icon'] = icon;
    return map;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value');
  }
}

/// Parses category list payloads from `/api/categories` and `/api/vip-categories`.
class CategoriesResponse {
  CategoriesResponse._();

  static List<Categories> parseCategories(dynamic json) {
    final items = _extractItems(json);
    return items
        .where(_isActive)
        .map((item) => Categories.fromJson(item))
        .toList()
      ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
  }

  static List<dynamic> _extractItems(dynamic json) {
    if (json is List) return json;
    if (json is Map && json['data'] is List) {
      return json['data'] as List;
    }
    return [];
  }

  static bool _isActive(dynamic item) {
    if (item is! Map) return true;
    final status = item['status']?.toString().toLowerCase();
    return status == null || status == 'active';
  }
}

typedef VipCategoriesResponse = CategoriesResponse;
typedef NormalCategoriesResponse = CategoriesResponse;
