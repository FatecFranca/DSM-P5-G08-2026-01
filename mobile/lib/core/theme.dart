part of '../main.dart';

final appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

/// URL padrao da API. VM Azure de producao do PI; sobrescreva com --dart-define=API_URL=...
const defaultApiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://4.229.233.225:3333',
);

/// URLs comuns para desenvolvimento local (ver mobile/README.md).
const localApiUrl = 'http://localhost:3333';
const androidEmulatorApiUrl = 'http://10.0.2.2:3333';

const teal600 = Color(0xFF0D9488);
const teal400 = Color(0xFF2DD4BF);
const lightBg = Color(0xFFF4F7FA);
const lightSurface = Color(0xFFFFFFFF);
const lightLine = Color(0xFFE6ECF1);
const lightInk = Color(0xFF0E1A24);
const lightMuted = Color(0xFF5B6B79);
const darkBg = Color(0xFF0C1116);
const darkSurface = Color(0xFF151D25);
const darkLine = Color(0xFF243039);
const darkInk = Color(0xFFECF2F6);
const darkMuted = Color(0xFF9DB0BE);

ThemeData vitalisTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: isDark ? teal400 : teal600,
    primary: isDark ? teal400 : teal600,
    secondary: const Color(0xFFF59E0B),
    tertiary: const Color(0xFF7C3AED),
    surface: isDark ? darkSurface : lightSurface,
    onSurface: isDark ? darkInk : lightInk,
    outlineVariant: isDark ? darkLine : lightLine,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? darkBg : lightBg,
    textTheme:
        GoogleFonts.plusJakartaSansTextTheme(
          ThemeData(brightness: brightness).textTheme,
        ).apply(
          bodyColor: isDark ? darkInk : lightInk,
          displayColor: isDark ? darkInk : lightInk,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF101922) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: isDark ? darkLine : lightLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? darkSurface : lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: (isDark ? darkSurface : const Color(0xFFEAF4F0))
          .withValues(alpha: 0.96),
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.plusJakartaSans(fontSize: 12),
      ),
    ),
  );
}
