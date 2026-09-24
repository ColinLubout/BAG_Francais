/// Generates `lib/core/strings.g.dart` from the files in `strings/`.
///
/// Run from the repo root:
///
///     dart run tool/gen_strings.dart
///
/// Exits with a non-zero code, listing every problem, if a file is invalid.
library;

import 'dart:io';

import 'src/strings_generator.dart';

const _sources = [
  StringsSource(
    path: 'strings/strings_fr.json',
    className: 'Strings',
    description: "The app's French text, from `strings/strings_fr.json`.",
    pluralRule: PluralRule.french,
  ),
  StringsSource(
    path: 'strings/strings_en_welcome.json',
    className: 'WelcomeStrings',
    description:
        "The welcome screen's English text, from "
        '`strings/strings_en_welcome.json`.',
    pluralRule: PluralRule.english,
  ),
];

const _output = 'lib/core/strings.g.dart';

void main() {
  final classes = <StringsClass>[];
  final errors = <StringsError>[];

  for (final source in _sources) {
    final file = File(source.path);
    if (!file.existsSync()) {
      stderr.writeln(
        '${source.path} not found. Run this from the repo root: '
        'dart run tool/gen_strings.dart',
      );
      exit(2);
    }
    try {
      classes.add(parseStrings(source, file.readAsStringSync()));
    } on StringsException catch (e) {
      errors.addAll(e.errors);
    }
  }

  if (errors.isNotEmpty) {
    stderr.writeln('The strings files have ${errors.length} problem(s):');
    for (final error in errors) {
      stderr.writeln('  $error');
    }
    exit(1);
  }

  File(_output).writeAsStringSync(generateDart(classes));

  final format = Process.runSync(Platform.resolvedExecutable, [
    'format',
    _output,
  ]);
  if (format.exitCode != 0) {
    stderr
      ..writeln('dart format failed on $_output:')
      ..writeln(format.stdout)
      ..writeln(format.stderr);
    exit(1);
  }

  final count = classes.fold(0, (sum, c) => sum + c.entries.length);
  stdout.writeln('Wrote $_output ($count strings).');
}
