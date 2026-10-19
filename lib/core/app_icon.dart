import 'dart:convert';
import 'dart:math';

/// Icon representation compatible with the original MoneyWallet JSON format:
///
///  * `{"type":"color","color":"#RRGGBB","name":"AB"}`
///  * `{"type":"resource","resource":"ic_icon_car"}`
///
/// The raw JSON is kept so unknown icons survive a round trip unchanged.
sealed class AppIcon {
  const AppIcon();

  String toJson();

  static AppIcon parse(String? raw) {
    if (raw == null || raw.isEmpty) return fallback;
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        switch (map['type']) {
          case 'color':
            final color = map['color'];
            final name = map['name'];
            if (color is String && name is String) {
              return ColorIcon(color, name);
            }
          case 'resource':
            final resource = map['resource'];
            final color = map['color'];
            if (resource is String) {
              return ResourceIcon(resource, color: color is String ? color : null);
            }
        }
      }
    } on FormatException {
      // fall through
    }
    return fallback;
  }

  static const fallback = ColorIcon('#FFC107', '?');
}

class ColorIcon extends AppIcon {
  const ColorIcon(this.color, this.name);

  /// Color in `#RRGGBB` (or `#AARRGGBB`) notation.
  final String color;

  /// Short text (initials) painted on top of the color.
  final String name;

  int get argb => _parseArgb(color) ?? 0xFFFFC107;

  @override
  String toJson() => jsonEncode({'type': 'color', 'color': color, 'name': name});

  @override
  bool operator ==(Object other) =>
      other is ColorIcon && other.color == color && other.name == name;

  @override
  int get hashCode => Object.hash(color, name);
}

class ResourceIcon extends AppIcon {
  const ResourceIcon(this.resource, {this.color});

  final String resource;

  /// Optional background color in `#RRGGBB` notation; `null` uses the theme.
  final String? color;

  int? get argb => color == null ? null : _parseArgb(color!);

  @override
  String toJson() => jsonEncode({
        'type': 'resource',
        'resource': resource,
        if (color != null) 'color': color,
      });

  @override
  bool operator ==(Object other) =>
      other is ResourceIcon && other.resource == resource && other.color == color;

  @override
  int get hashCode => Object.hash(resource, color);
}

int? _parseArgb(String color) {
  var hex = color.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return int.tryParse(hex, radix: 16);
}

/// Material palette used for generated color icons (same idea as the
/// original `Utils.getRandomMDColor`).
const materialIconColors = <String>[
  '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5', '#2196F3',
  '#03A9F4', '#00BCD4', '#009688', '#4CAF50', '#8BC34A', '#CDDC39',
  '#FFC107', '#FF9800', '#FF5722', '#795548', '#607D8B',
];

/// Initials of the first two words, otherwise the first letter (uppercase).
String iconInitials(String name) {
  final words =
      name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length >= 2) {
    return (words[0].characters1 + words[1].characters1).toUpperCase();
  }
  return words[0].characters1.toUpperCase();
}

ColorIcon randomColorIcon(String name, {Random? random}) {
  final r = random ?? Random();
  return ColorIcon(
    materialIconColors[r.nextInt(materialIconColors.length)],
    iconInitials(name),
  );
}

extension on String {
  String get characters1 => isEmpty ? '' : String.fromCharCode(runes.first);
}
