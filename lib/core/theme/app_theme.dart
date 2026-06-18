import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Paleta de cores ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF1976D2);
  static const Color accent = Color(0xFF1E88E5);

  static const Color conforme = Color(0xFF2E7D32);
  static const Color conformeLight = Color(0xFFE8F5E9);
  static const Color comObs = Color(0xFFF57F17);
  static const Color comObsLight = Color(0xFFFFF8E1);
  static const Color naoConforme = Color(0xFFC62828);
  static const Color naoConformeLight = Color(0xFFFFEBEE);
  static const Color naoAplicavel = Color(0xFF757575);
  static const Color naoAplicavelLight = Color(0xFFF5F5F5);
  static const Color emAndamento = Color(0xFF455A64);
  static const Color emAndamentoLight = Color(0xFFECEFF1);

  static const Color divergencia = Color(0xFFB71C1C);
  static const Color divergenciaLight = Color(0xFFFFCDD2);

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // ── Tema claro (padrão) ──────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: naoConforme,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.roboto(
            fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary),
        displayMedium: GoogleFonts.roboto(
            fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
        headlineLarge: GoogleFonts.roboto(
            fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.roboto(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        headlineSmall: GoogleFonts.roboto(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.roboto(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.roboto(
            fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
        titleSmall: GoogleFonts.roboto(
            fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
        bodyLarge: GoogleFonts.roboto(
            fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
        bodyMedium: GoogleFonts.roboto(
            fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
        bodySmall: GoogleFonts.roboto(
            fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
        labelLarge: GoogleFonts.roboto(
            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: GoogleFonts.roboto(
            fontSize: 12, fontWeight: FontWeight.w500, color: textSecondary),
        labelSmall: GoogleFonts.roboto(
            fontSize: 11, fontWeight: FontWeight.w400, color: textHint),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: naoConforme),
        ),
        labelStyle:
            GoogleFonts.roboto(fontSize: 14, color: textSecondary),
        hintStyle:
            GoogleFonts.roboto(fontSize: 14, color: textHint),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle:
            GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentTextStyle: GoogleFonts.roboto(fontSize: 14),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ── Helpers de status ────────────────────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'conforme':
        return conforme;
      case 'conforme_obs':
        return comObs;
      case 'nao_conforme':
        return naoConforme;
      case 'nao_aplicavel':
        return naoAplicavel;
      case 'em_andamento':
        return emAndamento;
      default:
        return textSecondary;
    }
  }

  static Color statusBgColor(String status) {
    switch (status) {
      case 'conforme':
        return conformeLight;
      case 'conforme_obs':
        return comObsLight;
      case 'nao_conforme':
        return naoConformeLight;
      case 'nao_aplicavel':
        return naoAplicavelLight;
      case 'em_andamento':
        return emAndamentoLight;
      default:
        return surfaceVariant;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'conforme':
        return 'Conforme';
      case 'conforme_obs':
        return 'Com Observação';
      case 'nao_conforme':
        return 'Não Conforme';
      case 'nao_aplicavel':
        return 'N/A';
      case 'em_andamento':
        return 'Em Andamento';
      default:
        return status;
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'conforme':
        return Icons.check_circle_rounded;
      case 'conforme_obs':
        return Icons.warning_amber_rounded;
      case 'nao_conforme':
        return Icons.cancel_rounded;
      case 'nao_aplicavel':
        return Icons.remove_circle_outline_rounded;
      case 'em_andamento':
        return Icons.pending_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
