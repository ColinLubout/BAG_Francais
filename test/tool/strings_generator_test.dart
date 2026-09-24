import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/src/strings_generator.dart';

const _source = StringsSource(
  path: 'test.json',
  className: 'TestStrings',
  description: 'Test strings.',
  pluralRule: PluralRule.french,
);

StringsClass _parse(String json, {StringsSource source = _source}) =>
    parseStrings(source, json);

List<String> _errors(String json) {
  try {
    _parse(json);
  } on StringsException catch (e) {
    return [for (final error in e.errors) error.toString()];
  }
  fail('expected a StringsException');
}

Matcher _hasError(String fragment) => contains(contains(fragment));

String _generate(String json, {StringsSource source = _source}) =>
    generateDart([_parse(json, source: source)]);

void main() {
  group('parseStrings', () {
    test('joins nested keys into lowerCamelCase names, in file order', () {
      final parsed = _parse('''
        {"home": {"dueCount": "a"}, "top": "b", "a": {"b": {"c": "d"}}}
      ''');
      expect(parsed.entries.map((e) => e.name), ['homeDueCount', 'top', 'aBC']);
      expect(parsed.entries.first.keyPath, 'home.dueCount');
    });

    test('skips keys starting with an underscore, at any level', () {
      final parsed = _parse('''
        {"_about": {"purpose": 1}, "s": {"_note": "n", "k": "v"}}
      ''');
      expect(parsed.entries.map((e) => e.name), ['sK']);
    });

    test('text without placeholders has no parameters', () {
      final entry = _parse('{"s": {"k": "plain"}}').entries.single;
      expect(entry, isA<SimpleEntry>());
      expect(entry.parameters, isEmpty);
    });

    test('placeholders become parameters, in order, once each', () {
      final entry = _parse('{"s": {"k": "{word} {n} {word}"}}').entries.single;
      expect(entry.parameters, ['word', 'n']);
    });

    test('accepts every documented placeholder', () {
      final all = placeholderTypes.keys.map((p) => '{$p}').join(' ');
      final entry = _parse('{"s": {"k": "$all"}}').entries.single;
      expect(entry.parameters, placeholderTypes.keys.toList());
    });

    test('pairs _one and _other keys into one plural entry', () {
      final entry = _parse('''
        {"s": {"count_one": "{n} item {word}", "count_other": "{n} items {word}"}}
      ''').entries.single;
      expect(entry, isA<PluralEntry>());
      expect(entry.name, 'sCount');
      expect(entry.keyPath, 's.count');
      expect(entry.parameters, ['n', 'word']);
    });

    test('a plural always takes n, even if a form leaves it out', () {
      final entry = _parse('''
        {"s": {"count_one": "one item", "count_other": "{n} items"}}
      ''').entries.single;
      expect(entry.parameters, ['n']);
    });

    group('rejects', () {
      test('invalid JSON', () {
        expect(_errors('{"s": '), _hasError('is not valid JSON'));
      });

      test('a file that is not a JSON object', () {
        expect(_errors('["a"]'), _hasError('must contain a JSON object'));
      });

      for (final (value, kind) in [
        ('1', 'a number'),
        ('true', 'true/false'),
        ('null', 'null'),
        ('["a"]', 'a list'),
      ]) {
        test('$kind as a value', () {
          expect(
            _errors('{"s": {"k": $value}}'),
            _hasError('s.k: must be text or a section, not $kind'),
          );
        });
      }

      test('an unknown placeholder, listing the allowed ones', () {
        expect(
          _errors('{"s": {"k": "{count} cards"}}'),
          _hasError('unknown placeholder {count}; allowed: {n}, {version}'),
        );
      });

      test('an empty placeholder', () {
        expect(_errors('{"s": {"k": "a {} b"}}'), _hasError('placeholder {}'));
      });

      test('an unclosed brace', () {
        expect(
          _errors('{"s": {"k": "a {n b"}}'),
          _hasError('has a "{" with no matching "}"'),
        );
      });

      test('nested braces', () {
        expect(
          _errors('{"s": {"k": "a {n{word}} b"}}'),
          _hasError('has a "{" with no matching "}"'),
        );
      });

      test('a stray closing brace', () {
        expect(
          _errors('{"s": {"k": "a } b"}}'),
          _hasError('has a "}" with no matching "{"'),
        );
      });

      test('empty text', () {
        expect(_errors('{"s": {"k": ""}}'), _hasError('s.k: is empty'));
        expect(_errors('{"s": {"k": "   "}}'), _hasError('s.k: is empty'));
      });

      for (final key in ['Due', 'due_count', 'due-count', '1st']) {
        test('the key "$key"', () {
          expect(
            _errors('{"s": {"$key": "x"}}'),
            _hasError('keys must be lowerCamelCase'),
          );
        });
      }

      test('a section name that is not lowerCamelCase', () {
        expect(
          _errors('{"Home": {"k": "x"}}'),
          _hasError('Home: section names must be lowerCamelCase'),
        );
      });

      test('a plural with only one form', () {
        expect(
          _errors('{"s": {"count_one": "{n} item"}}'),
          _hasError('a plural needs both s.count_one and s.count_other'),
        );
      });

      test('a key with both a plain and a plural form', () {
        expect(
          _errors('''
            {"s": {"count": "x", "count_one": "{n} a", "count_other": "{n} b"}}
          '''),
          _hasError('has both a plain form and _one/_other forms'),
        );
      });

      test('plural forms with different placeholders', () {
        expect(
          _errors('''
            {"s": {"count_one": "{n} {word}", "count_other": "{n} {drill}"}}
          '''),
          _hasError('_one and _other must use the same placeholders'),
        );
      });

      test('two keys that generate the same name', () {
        expect(
          _errors('{"a": {"bC": "x"}, "aB": {"c": "y"}}'),
          _hasError('aB.c: generates the name "aBC", already used by a.bC'),
        );
      });

      for (final key in ['new', 'toString']) {
        test('the reserved name "$key"', () {
          expect(_errors('{"$key": "x"}'), _hasError('is reserved in Dart'));
        });
      }

      test('reporting every problem at once', () {
        final errors = _errors('''
          {"s": {"a": "", "b": "{nope}", "c": 3}}
        ''');
        expect(errors, hasLength(3));
        expect(errors, everyElement(startsWith('test.json: s.')));
      });
    });
  });

  group('generateDart', () {
    test('names the source files in the header', () {
      final code = _generate('{"s": {"k": "v"}}');
      expect(code, startsWith('// GENERATED CODE - DO NOT MODIFY BY HAND.'));
      expect(code, contains('//   test.json'));
    });

    test('writes one abstract final class per file', () {
      final code = _generate('{"s": {"k": "v"}}');
      expect(
        code,
        contains('/// Test strings.\nabstract final class TestStrings {'),
      );
    });

    test('writes a constant for text without placeholders', () {
      final code = _generate('{"s": {"ok": "fine"}}');
      expect(code, contains("/// fine\nstatic const sOk = 'fine';"));
    });

    test('writes a method with typed named parameters for placeholders', () {
      final code = _generate('{"s": {"m": "{n} of {version} on {date}"}}');
      expect(
        code,
        contains(
          'static String sM({required int n, required int version, '
          r"required String date}) => '$n of $version on $date';",
        ),
      );
    });

    test('escapes quotes, dollar signs, backslashes and line breaks', () {
      final code = _generate(r'''{"s": {"k": "It's $5 \\ a\nb\tc"}}''');
      expect(code, contains(r"static const sK = 'It\'s \$5 \\ a\nb\tc';"));
    });

    test('keeps typographic apostrophes and accents as they are', () {
      final code = _generate('{"s": {"k": "a’b é à ç"}}');
      expect(code, contains("static const sK = 'a’b é à ç';"));
    });

    test('braces a placeholder only when a letter or digit follows', () {
      final code = _generate(
        '{"s": {"a": "{n}th", "b": "{n}.", "c": "{n}{word}", "d": "x{n}"}}',
      );
      expect(code, contains(r"=> '${n}th';"));
      expect(code, contains(r"=> '$n.';"));
      expect(code, contains(r"=> '$n$word';"));
      expect(code, contains(r"=> 'x$n';"));
    });

    test('picks the plural form by n: French makes 0 and 1 singular', () {
      final code = _generate(
        '{"s": {"count_one": "{n} item", "count_other": "{n} items"}}',
      );
      expect(code, contains('/// {n} item · {n} items'));
      expect(
        code,
        contains(
          'static String sCount({required int n}) => '
          r"n.abs() < 2 ? '$n item' : '$n items';",
        ),
      );
    });

    test('picks the plural form by n: English makes only 1 singular', () {
      const english = StringsSource(
        path: 'en.json',
        className: 'En',
        description: 'English.',
        pluralRule: PluralRule.english,
      );
      final code = _generate(
        '{"s": {"count_one": "{n} item", "count_other": "{n} items"}}',
        source: english,
      );
      expect(code, contains(r"n.abs() == 1 ? '$n item' : '$n items';"));
    });

    test('is deterministic', () {
      const json = '{"s": {"a": "x", "b": "{n} y"}}';
      expect(_generate(json), _generate(json));
    });
  });

  group('the real strings files', () {
    for (final path in [
      'strings/strings_fr.json',
      'strings/strings_en_welcome.json',
    ]) {
      test('$path is valid', () {
        final source = StringsSource(
          path: path,
          className: 'S',
          description: '',
          pluralRule: PluralRule.french,
        );
        final parsed = parseStrings(source, File(path).readAsStringSync());
        expect(parsed.entries, isNotEmpty);
      });
    }
  });
}
