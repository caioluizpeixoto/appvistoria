import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/aba_dispositivos_master_widget.dart';

/// Tela Master exclusiva para autorização e gerenciamento de dispositivos móveis.
/// (As vistorias e laudos de todas as empresas são auditados diretamente no Dashboard/Relatórios).
class PainelMasterScreen extends StatelessWidget {
  const PainelMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.phonelink_lock_rounded, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text('Liberar Aparelhos (Master)'),
          ],
        ),
      ),
      body: const AbaDispositivosMasterWidget(),
    );
  }
}
