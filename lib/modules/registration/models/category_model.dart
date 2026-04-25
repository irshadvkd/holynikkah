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
  });

  Categories.fromJson(dynamic json) {
    catId = json['catId'];
    name = json['name'];
    networth = json['networth'];
    bgColor = json['bgColor'];
    textColor = json['textColor'];
  }
  String? catId;
  String? name;
  String? networth;
  String? bgColor;
  String? textColor;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['catId'] = catId;
    map['name'] = name;
    map['networth'] = networth;
    map['bgColor'] = bgColor;
    map['textColor'] = textColor;
    return map;
  }
}
