import 'package:flutter_test/flutter_test.dart';
import 'package:holynikkah/modules/template/models/template_definition.dart';
import 'package:holynikkah/modules/template/models/template_style.dart';

void main() {
  group('Template Models Parsing', () {
    test('parses live vip_3 template response successfully', () {
      final jsonPayload = {
        'id': 'vip_3',
        'schemaVersion': 1,
        'name': 'Vip 3',
        'type': 'vip',
        'status': 'published',
        'isActive': true,
        'previewImage': 'api/templates/assets/46',
        'createdAt': '2026-09-07T17:03:45Z',
        'updatedAt': '2026-09-07T17:03:47Z',
        'canvas': {
          'aspectRatio': 0.6666666666666666,
          'background': {
            'type': 'image',
            'color': '#FFFFFF',
            'image': 'api/templates/assets/45',
            'fit': 'cover',
          },
        },
        'fields': [
          {
            'key': 'text_1',
            'label': 'Info',
            'inputType': 'text',
            'required': true,
            'keyboard': 'text',
            'hint': 'Enter your information',
            'validation': {
              'minLength': 25,
            },
          },
        ],
        'elements': [
          {
            'id': 'imageSlot_1',
            'type': 'imageSlot',
            'rect': {
              'x': 0.128,
              'y': 0.106,
              'w': 0.522,
              'h': 0.563,
            },
            'shape': 'rrect',
            'cornerRadius': 0,
            'fit': 'cover',
            'aspectRatio': 0.6181,
          },
          {
            'id': 'box_1',
            'type': 'box',
            'rect': {
              'x': 0.506,
              'y': 0.263,
              'w': 0.435,
              'h': 0.25,
            },
            'style': {
              'backgroundColor': '#CCCCCC',
              'padding': 12,
              'cornerRadius': 0,
            },
            'children': [],
          },
          {
            'id': 'boundField_1',
            'type': 'boundField',
            'rect': {
              'x': 0.521,
              'y': 0.271,
              'w': 0.408,
              'h': 0.236,
            },
            'field': 'text_1',
            'style': {
              'fontFamily': 'Inter',
              'fontSize': 16,
              'fontWeight': 400,
              'color': '#222222',
              'align': 'left',
            },
          },
        ],
      };

      final template = TemplateDefinition.fromJson(jsonPayload);
      expect(template.id, equals('vip_3'));
      expect(template.name, equals('Vip 3'));
      expect(template.isVip, isTrue);
      expect(template.elements.length, equals(3));
      expect(template.elements[0].aspectRatio, closeTo(0.6181, 0.0001));
      expect(template.elements[0].style?.fit, equals('cover'));
      expect(template.elements[1].style?.borderRadius, equals(0.0));
      expect(template.elements[1].style?.padding, equals(12.0));
      expect(template.elements[2].style?.fontWeight, equals(400));
      expect(template.elements[2].style?.fontSize, equals(16.0));
    });

    test('handles String values for numeric fields gracefully', () {
      final style = TemplateStyle.fromJson({
        'fontSize': '18.5',
        'fontWeight': '600',
        'borderRadius': '8',
        'padding': '16.0',
        'paddingLTRB': ['4', '8', '12', '16'],
        'opacity': '0.9',
        'lineHeight': '1.4',
      });

      expect(style.fontSize, equals(18.5));
      expect(style.fontWeight, equals(600));
      expect(style.borderRadius, equals(8.0));
      expect(style.padding, equals(16.0));
      expect(style.paddingLTRB, equals([4.0, 8.0, 12.0, 16.0]));
      expect(style.opacity, equals(0.9));
      expect(style.lineHeight, equals(1.4));
    });

    test('handles named weights like bold, w700, semibold', () {
      expect(TemplateStyle.fromJson({'fontWeight': 'bold'}).fontWeight, equals(700));
      expect(TemplateStyle.fromJson({'fontWeight': 'semibold'}).fontWeight, equals(600));
      expect(TemplateStyle.fromJson({'fontWeight': 'w500'}).fontWeight, equals(500));
      expect(TemplateStyle.fromJson({'fontWeight': 'normal'}).fontWeight, equals(400));
    });
  });
}
