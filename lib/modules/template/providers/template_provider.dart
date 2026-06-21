import 'package:flutter/material.dart';

class TemplateProvider extends ChangeNotifier {
  bool _isVipTemplate = false;
  String _templateId = '';
  String _templateName = '';
  String _templateDescription = '';
  String _templateCategory = '';
  String? _templateImagePath;
  DateTime? _createdAt;
  DateTime? _updatedAt;

  // Getters
  bool get isVipTemplate => _isVipTemplate;
  String get templateId => _templateId;
  String get templateName => _templateName;
  String get templateDescription => _templateDescription;
  String get templateCategory => _templateCategory;
  String? get templateImagePath => _templateImagePath;
  DateTime? get createdAt => _createdAt;
  DateTime? get updatedAt => _updatedAt;

  // Setters
  void setVipTemplate(bool isVip) {
    _isVipTemplate = isVip;
    notifyListeners();
  }

  void updateTemplateId(String id) {
    _templateId = id;
    notifyListeners();
  }

  void updateTemplateName(String name) {
    _templateName = name;
    notifyListeners();
  }

  void updateTemplateDescription(String description) {
    _templateDescription = description;
    notifyListeners();
  }

  void updateTemplateCategory(String category) {
    _templateCategory = category;
    notifyListeners();
  }

  void updateTemplateImage(String? imagePath) {
    _templateImagePath = imagePath;
    notifyListeners();
  }

  void updateTimestamps() {
    final now = DateTime.now();
    if (_createdAt == null) {
      _createdAt = now;
    }
    _updatedAt = now;
    notifyListeners();
  }

  void clearTemplate() {
    _isVipTemplate = false;
    _templateId = '';
    _templateName = '';
    _templateDescription = '';
    _templateCategory = '';
    _templateImagePath = null;
    _createdAt = null;
    _updatedAt = null;
    notifyListeners();
  }
}