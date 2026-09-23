import 'dart:convert';
import 'dart:io';

import 'package:bah_francais/core/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Checks the committed generated class against the JSON it came from.
void main() {
  Map<String, Object?> load(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

  final fr = load('strings/strings_fr.json');
  final en = load('strings/strings_en_welcome.json');

  String text(Map<String, Object?> file, String section, String key) =>
      (file[section]! as Map<String, Object?>)[key]! as String;

  test('constants carry the JSON text exactly', () {
    expect(Strings.commonAppName, text(fr, 'common', 'appName'));
    expect(Strings.navigationHome, text(fr, 'navigation', 'home'));
    expect(Strings.homeDrillSettings, text(fr, 'home', 'drillSettings'));
  });

  test('methods fill in their placeholders', () {
    expect(
      Strings.homeDueCount(n: 12),
      text(fr, 'home', 'dueCount').replaceAll('{n}', '12'),
    );
    expect(
      Strings.settingsContentVersion(version: 14, date: 'DATE'),
      text(
        fr,
        'settings',
        'contentVersion',
      ).replaceAll('{version}', '14').replaceAll('{date}', 'DATE'),
    );
  });

  test('the welcome screen has its own English class', () {
    expect(WelcomeStrings.welcomeTitle, text(en, 'welcome', 'title'));
    expect(
      WelcomeStrings.welcomePointKnownWords,
      text(en, 'welcome', 'pointKnownWords'),
    );
  });
}
