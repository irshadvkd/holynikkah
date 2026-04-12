class RegistrationModel {
  final String profileId;
  final String name;
  final String phoneNumber;
  final String information;
  final bool isVip;
  final String? categoryId;
  final String? subcategoryId;

  RegistrationModel({
    required this.profileId,
    required this.name,
    required this.phoneNumber,
    required this.information,
    this.isVip = false,
    this.categoryId,
    this.subcategoryId,
  });

  Map<String, dynamic> toJson() => {
    'profile_id': profileId,
    'name': name,
    'phone_number': phoneNumber,
    'information': information,
    'is_vip': isVip,
    'category_id': categoryId,
    'subcategory_id': subcategoryId,
  };

  factory RegistrationModel.fromJson(Map<String, dynamic> json) => RegistrationModel(
    profileId: json['profile_id'] ?? '',
    name: json['name'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
    information: json['information'] ?? '',
    isVip: json['is_vip'] ?? false,
    categoryId: json['category_id'],
    subcategoryId: json['subcategory_id'],
  );
}