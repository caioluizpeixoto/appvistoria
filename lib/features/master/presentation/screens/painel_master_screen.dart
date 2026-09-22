import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/aba_dispositivos_master_widget.dart';
import '../widgets/aba_creditos_master_widget.dart';

/// Tela Master exclusiva para autorização e gerenciamento de dispositivos móveis,
/// bem como gestão e devolução de créditos (carteiras).
class PainelMasterScreen extends StatelessWidget {
  const PainelMasterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 22),
              SizedBox(width: 8),
              Text('Painel Master'),
            ],
          ),
          bottom: const TabBar(
            indicatorColor: AppTheme.primary,
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.phonelink_lock_rounded), text: 'Aparelhos'),
              Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: 'Créditos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AbaDispositivosMasterWidget(),
            AbaCreditosMasterWidget(),
          ],
        ),
      ),
    );
  }
}
