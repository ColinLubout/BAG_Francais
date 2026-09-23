/// Turns the strings JSON files into a typed Dart class.
///
/// Pure Dart with no file access, so it can be tested directly; the
/// command-line entry point is `tool/gen_strings.dart`.
library;

import 'dart:convert';

/// Every placeholder a string may contain, and the Dart type it becomes.
///
/// Dates and sizes arrive as text: the caller formats them the French way.
const placeholderTypes = <String, String>{
  'n': 'int',
  'version': 'int',
  'date': 'String',
  'size': 'String',
  'drill': 'String',
  'answer': 'String',
  'word': 'String',
};

/// Which count takes the `_one` form of a plural key.
enum PluralRule {
  /// 0 and 1 are singular (*0 carte*, *1 carte*, *2 cartes*).
  french,

  /// Only 1 is singular (*0 cards*, *1 card*, *2 cards*).
  english,
}

/// One strings JSON file and the class generated from it.
class StringsSource {
  const StringsSource({
    required this.path,
    required this.className,
    required this.description,
    required this.pluralRule,
  });

  /// Path of the JSON file, relative to the repo root.
  final String path;

  /// Name of the generated Dart class.
  final String className;

  /// Doc comment for the generated class.
  final String description;

  final PluralRule pluralRule;
}

/// A problem found in a strings file.
class StringsError {
  const StringsError(this.file, this.key, this.message);

  final String file;

  /// Dotted path of the key, e.g. `home.dueCount`; empty for file-level
  /// problems.
  final String key;

  final String message;

  @override
  String toString() =>
      key.isEmpty ? '$file: $message' : '$file: $key: $message';
}

/// Thrown by [parseStrings] with every problem found in the file.
class StringsException implements Exception {
  const StringsException(this.errors);

  final List<StringsError> errors;

  @override
  String toString() => errors.join('\n');
}

/// A piece of a string value: literal text or a placeholder.
sealed class Segment {
  const Segment();
}

class LiteralSegment extends Segment {
  const LiteralSegment(this.text);

  final String text;
}

class PlaceholderSegment extends Segment {
  const PlaceholderSegment(this.name);

  final String name;
}

/// A parsed string value.
class StringValue {
  const StringValue(this.raw, this.segments);

  /// The value exactly as written in the JSON file.
  final String raw;

  final List<Segment> segments;

  /// Placeholder names in order of first appearance.
  List<String> get placeholders => [
    ...{
      for (final segment in segments)
        if (segment is PlaceholderSegment) segment.name,
    },
  ];
}

/// One generated member.
sealed class StringEntry {
  const StringEntry(this.name, this.keyPath);

  /// The Dart member name, e.g. `homeDueCount`.
  final String name;

  /// The dotted JSON path, e.g. `home.dueCount`.
  final String keyPath;

  /// Parameters of the generated method, in order; empty for a constant.
  List<String> get parameters;
}

class SimpleEntry extends StringEntry {
  const SimpleEntry(super.name, super.keyPath, this.value);

  final StringValue value;

  @override
  List<String> get parameters => value.placeholders;
}

/// A `key_one` / `key_other` pair, chosen by `{n}`.
class PluralEntry extends StringEntry {
  const PluralEntry(super.name, super.keyPath, this.one, this.other);

  final StringValue one;
  final StringValue other;

  @override
  List<String> get parameters => [
    'n',
    ...{...other.placeholders, ...one.placeholders}.where((p) => p != 'n'),
  ];
}

/// The entries parsed from one file.
class StringsClass {
  const StringsClass(this.source, this.entries);

  final StringsSource source;
  final List<StringEntry> entries;
}

final _segmentPattern = RegExp(r'^[a-z][A-Za-z0-9]*$');
final _leafPattern = RegExp(r'^([a-z][A-Za-z0-9]*)(?:_(one|other))?$');

const _reservedNames = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', //
  'default', 'do', 'else', 'enum', 'extends', 'false', 'final', 'finally',
  'for', 'if', 'in', 'is', 'new', 'null', 'rethrow', 'return', 'super',
  'switch', 'this', 'throw', 'true', 'try', 'var', 'void', 'while', 'with',
  // Members every Dart object already has.
  'hashCode', 'noSuchMethod', 'runtimeType', 'toString',
};

/// Parses one strings file.
///
/// Sections nest as JSON objects and every leaf is a string. Keys starting
/// with `_` are notes for whoever edits the file and are skipped. A leaf's
/// member name joins its path in lowerCamelCase: `home.dueCount` becomes
/// `homeDueCount`.
///
/// Throws a [StringsException] listing every problem in the file.
StringsClass parseStrings(StringsSource source, String json) {
  final errors = <StringsError>[];
  void error(String key, String message) =>
      errors.add(StringsError(source.path, key, message));

  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException catch (e) {
    throw StringsException([
      StringsError(source.path, '', 'is not valid JSON: ${e.message}'),
    ]);
  }
  if (decoded is! Map<String, Object?>) {
    throw StringsException([
      StringsError(source.path, '', 'must contain a JSON object'),
    ]);
  }

  // Keyed by member name, in file order.
  final simple = <String, SimpleEntry>{};
  final pluralParts = <String, Map<String, StringValue>>{};
  final pluralPaths = <String, String>{};
  final order = <String>[];
  final pathOfName = <String, String>{};

  void claim(String name, String keyPath) {
    final previous = pathOfName[name];
    if (previous != null && previous != keyPath) {
      error(keyPath, 'generates the name "$name", already used by $previous');
      return;
    }
    if (previous == null) {
      pathOfName[name] = keyPath;
      order.add(name);
    }
  }

  void walk(Map<String, Object?> map, List<String> path) {
    for (final MapEntry(:key, :value) in map.entries) {
      if (key.startsWith('_')) continue;
      final keyPath = [...path, key].join('.');

      if (value is Map<String, Object?>) {
        if (!_segmentPattern.hasMatch(key)) {
          error(keyPath, 'section names must be lowerCamelCase');
          continue;
        }
        walk(value, [...path, key]);
        continue;
      }
      if (value is! String) {
        error(keyPath, 'must be text or a section, not ${_describe(value)}');
        continue;
      }

      final match = _leafPattern.firstMatch(key);
      if (match == null) {
        error(
          keyPath,
          'keys must be lowerCamelCase, optionally ending in _one or _other',
        );
        continue;
      }
      final baseKey = match.group(1)!;
      final pluralForm = match.group(2);
      final name = _memberName([...path, baseKey]);
      final basePath = [...path, baseKey].join('.');

      if (_reservedNames.contains(name)) {
        error(keyPath, '"$name" is reserved in Dart; choose another key');
        continue;
      }
      final parsed = _parseValue(value, (m) => error(keyPath, m));
      if (parsed == null) continue;

      claim(name, basePath);
      if (pluralForm == null) {
        simple[name] = SimpleEntry(name, basePath, parsed);
      } else {
        (pluralParts[name] ??= {})[pluralForm] = parsed;
        pluralPaths[name] = basePath;
      }
    }
  }

  walk(decoded, const []);

  final entries = <StringEntry>[];
  for (final name in order) {
    final parts = pluralParts[name];
    if (parts == null) {
      final entry = simple[name];
      if (entry != null) entries.add(entry);
      continue;
    }
    final keyPath = pluralPaths[name]!;
    if (simple.containsKey(name)) {
      error(keyPath, 'has both a plain form and _one/_other forms');
      continue;
    }
    final one = parts['one'];
    final other = parts['other'];
    if (one == null || other == null) {
      error(keyPath, 'a plural needs both ${keyPath}_one and ${keyPath}_other');
      continue;
    }
    final oneNames = one.placeholders.toSet()..remove('n');
    final otherNames = other.placeholders.toSet()..remove('n');
    if (oneNames.length != otherNames.length ||
        !oneNames.containsAll(otherNames)) {
      error(
        keyPath,
        '_one and _other must use the same placeholders (apart from {n})',
      );
      continue;
    }
    entries.add(PluralEntry(name, keyPath, one, other));
  }

  if (errors.isNotEmpty) throw StringsException(errors);
  return StringsClass(source, entries);
}

/// Generates the Dart source for [classes], unformatted.
String generateDart(List<StringsClass> classes) {
  final out = StringBuffer()
    ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
    ..writeln('//')
    ..writeln('// Generated by tool/gen_strings.dart from:');
  for (final c in classes) {
    out.writeln('//   ${c.source.path}');
  }
  out
    ..writeln('// Edit those files, then run `dart run tool/gen_strings.dart`.')
    ..writeln();

  for (final c in classes) {
    out
      ..writeln('/// ${c.source.description}')
      ..writeln('abstract final class ${c.source.className} {');
    for (final entry in c.entries) {
      out
        ..writeln()
        ..writeln(_docComment(entry))
        ..writeln(_member(entry, c.source.pluralRule));
    }
    out
      ..writeln('}')
      ..writeln();
  }
  return out.toString();
}

String _memberName(List<String> path) => [
  path.first,
  for (final segment in path.skip(1))
    segment[0].toUpperCase() + segment.substring(1),
].join();

String _describe(Object? value) => switch (value) {
  null => 'null',
  num() => 'a number',
  bool() => 'true/false',
  List<Object?>() => 'a list',
  _ => value.runtimeType.toString(),
};

/// Splits [raw] into literal text and placeholders, reporting problems to
/// [error]. Returns null if there were any.
StringValue? _parseValue(String raw, void Function(String) error) {
  if (raw.trim().isEmpty) {
    error('is empty');
    return null;
  }
  final segments = <Segment>[];
  final literal = StringBuffer();
  var ok = true;
  var i = 0;
  while (i < raw.length) {
    final char = raw[i];
    if (char == '}') {
      error('has a "}" with no matching "{"');
      ok = false;
      i++;
      continue;
    }
    if (char != '{') {
      literal.write(char);
      i++;
      continue;
    }
    final close = raw.indexOf('}', i + 1);
    final nextOpen = raw.indexOf('{', i + 1);
    if (close == -1 || (nextOpen != -1 && nextOpen < close)) {
      error('has a "{" with no matching "}"');
      ok = false;
      i++;
      continue;
    }
    final name = raw.substring(i + 1, close);
    if (!placeholderTypes.containsKey(name)) {
      final allowed = placeholderTypes.keys.map((p) => '{$p}').join(', ');
      error('unknown placeholder {$name}; allowed: $allowed');
      ok = false;
    }
    if (literal.isNotEmpty) {
      segments.add(LiteralSegment(literal.toString()));
      literal.clear();
    }
    segments.add(PlaceholderSegment(name));
    i = close + 1;
  }
  if (literal.isNotEmpty) segments.add(LiteralSegment(literal.toString()));
  return ok ? StringValue(raw, segments) : null;
}

String _docComment(StringEntry entry) {
  String flat(String s) => s.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  return switch (entry) {
    SimpleEntry(:final value) => '/// ${flat(value.raw)}',
    PluralEntry(:final one, :final other) =>
      '/// ${flat(one.raw)} · ${flat(other.raw)}',
  };
}

String _member(StringEntry entry, PluralRule rule) {
  final params = entry.parameters;
  if (params.isEmpty) {
    final value = (entry as SimpleEntry).value;
    return 'static const ${entry.name} = ${_literal(value)};';
  }
  final signature = params
      .map((p) => 'required ${placeholderTypes[p]} $p')
      .join(', ');
  final body = switch (entry) {
    SimpleEntry(:final value) => _literal(value),
    PluralEntry(:final one, :final other) =>
      '${_pluralTest(rule)} ? ${_literal(one)} : ${_literal(other)}',
  };
  return 'static String ${entry.name}({$signature}) => $body;';
}

String _pluralTest(PluralRule rule) => switch (rule) {
  PluralRule.french => 'n.abs() < 2',
  PluralRule.english => 'n.abs() == 1',
};

final _identifierChar = RegExp('[A-Za-z0-9_]');

/// A single-quoted Dart string literal for [value], with placeholders
/// interpolated.
String _literal(StringValue value) {
  final out = StringBuffer("'");
  final segments = value.segments;
  for (var i = 0; i < segments.length; i++) {
    switch (segments[i]) {
      case LiteralSegment(:final text):
        out.write(_escape(text));
      case PlaceholderSegment(:final name):
        final next = i + 1 < segments.length ? segments[i + 1] : null;
        final needsBraces =
            next is LiteralSegment && _identifierChar.hasMatch(next.text[0]);
        out.write(needsBraces ? '\${$name}' : '\$$name');
    }
  }
  out.write("'");
  return out.toString();
}

String _escape(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    out.write(switch (char) {
      r'\' => r'\\',
      "'" => r"\'",
      r'$' => r'\$',
      '\n' => r'\n',
      '\r' => r'\r',
      '\t' => r'\t',
      _ when rune < 0x20 => '\\u{${rune.toRadixString(16)}}',
      _ => char,
    });
  }
  return out.toString();
}
