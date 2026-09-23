import 'package:bah_francais/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lists the Poppins licence on the licence page.
///
/// Poppins ships under the SIL Open Font License, which has to travel with
/// the font.
void registerFontLicences() => LicenseRegistry.addLicense(_fontLicences);

Stream<LicenseEntry> _fontLicences() async* {
  final licence = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(const [AppTheme.fontFamily], licence);
}
