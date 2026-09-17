import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Serviço responsável pelo controle de segurança e trava de aprovação de aparelho
class DeviceSecurityService {
  final SupabaseClient _supabase;
  final Uuid _uuid = const Uuid();

  static const String _configFile = 'device_identity.json';

  bool _isMasterBypass = false;
  String? _cachedDeviceId;
  Map<String, dynamic>? _cachedData;

  DeviceSecurityService({required SupabaseClient supabase})
      : _supabase = supabase;

  /// Define se a sessão atual é de um Master (bypass de trava)
  void setMasterBypass(bool isMaster) {
    _isMasterBypass = isMaster;
  }

  bool get isMasterBypass => _isMasterBypass;

  /// Retorna sincronamente se o aparelho está aprovado com base no cache local ou bypass
  bool get isCachedApproved =>
      _isMasterBypass || (_cachedData?['is_approved'] == true);

  /// Inicializa e pré-carrega a identidade do aparelho
  Future<void> init() async {
    await _readLocalData();
  }

  /// Arquivo local de identidade do aparelho
  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_configFile');
  }

  /// Lê as configurações locais persistidas
  Future<Map<String, dynamic>> _readLocalData() async {
    if (_cachedData != null) return _cachedData!;
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        _cachedData = jsonDecode(content) as Map<String, dynamic>;
        _cachedDeviceId = _cachedData?['device_id'] as String?;
        return _cachedData!;
      }
    } catch (e) {
      debugPrint('[DeviceSecurityService] Erro ao ler arquivo local: $e');
    }
    _cachedData = {};
    return _cachedData!;
  }

  /// Salva dados atualizados no arquivo local
  Future<void> _writeLocalData(Map<String, dynamic> data) async {
    try {
      final file = await _getLocalFile();
      await file.writeAsString(jsonEncode(data));
      _cachedData = data;
      _cachedDeviceId = data['device_id'] as String?;
    } catch (e) {
      debugPrint('[DeviceSecurityService] Erro ao salvar arquivo local: $e');
    }
  }

  /// Obtém o identificador único e persistente deste celular/aparelho
  Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) {
      return _cachedDeviceId!;
    }

    final data = await _readLocalData();
    if (data['device_id'] != null &&
        (data['device_id'] as String).trim().isNotEmpty) {
      _cachedDeviceId = data['device_id'] as String;
      return _cachedDeviceId!;
    }

    // Gera um código legível no formato VIST-XXXXXXXX
    final shortUuid = _uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
    final newDeviceId = 'VIST-$shortUuid';

    data['device_id'] = newDeviceId;
    data['created_at'] = DateTime.now().toIso8601String();
    data['status'] = 'pendente';
    data['is_approved'] = false;

    await _writeLocalData(data);
    _cachedDeviceId = newDeviceId;
    return newDeviceId;
  }

  /// Obtém descrição amigável do modelo e sistema operacional do aparelho
  Future<String> getDeviceModel() async {
    try {
      if (kIsWeb) return 'Navegador Web';
      final os = Platform.operatingSystem.toUpperCase();
      final host = Platform.localHostname;
      if (host.isNotEmpty && host != 'localhost') {
        return '$os ($host)';
      }
      return os;
    } catch (_) {
      return 'Aparelho Mobile';
    }
  }

  /// Dados salvos do solicitante
  Future<Map<String, String>> getSolicitanteInfo() async {
    final data = await _readLocalData();
    return {
      'nome': (data['solicitante_nome'] as String?) ?? '',
      'telefone': (data['solicitante_telefone'] as String?) ?? '',
    };
  }

  /// Atualiza nome e telefone do solicitante localmente
  Future<void> saveSolicitanteInfo({
    required String nome,
    required String telefone,
  }) async {
    final data = await _readLocalData();
    data['solicitante_nome'] = nome.trim();
    data['solicitante_telefone'] = telefone.trim();
    await _writeLocalData(data);
  }

  /// Consulta ou registra o aparelho no Supabase
  Future<Map<String, dynamic>> checkDeviceStatus({
    String? solicitanteNome,
    String? solicitanteTelefone,
    String? userId,
  }) async {
    // Se o usuário atual for Master, auto-aprova
    if (_isMasterBypass) {
      return {
        'status': 'aprovado',
        'isApproved': true,
        'motivo': null,
        'solicitante_nome': solicitanteNome ?? 'Admin Master',
      };
    }

    final deviceId = await getDeviceId();
    final deviceModel = await getDeviceModel();
    final os = kIsWeb ? 'Web' : Platform.operatingSystem;

    final localData = await _readLocalData();
    final nome = solicitanteNome ?? (localData['solicitante_nome'] as String?);
    final fone = solicitanteTelefone ?? (localData['solicitante_telefone'] as String?);

    // 1. Consulta DIRETA à tabela dispositivos_autorizados (Rápida, confiável e imune a erros de RPC)
    try {
      final existing = await _supabase
          .from('dispositivos_autorizados')
          .select('id, device_id, status, motivo_bloqueio, solicitante_nome')
          .eq('device_id', deviceId)
          .maybeSingle();

      if (existing != null) {
        final status = (existing['status'] as String? ?? 'pendente').toLowerCase();
        final isApproved = status == 'aprovado';
        final motivo = existing['motivo_bloqueio'] as String?;

        // Atualiza cache local
        localData['status'] = status;
        localData['is_approved'] = isApproved;
        localData['motivo_bloqueio'] = motivo;
        localData['last_remote_check'] = DateTime.now().toIso8601String();
        if (nome != null && nome.isNotEmpty) localData['solicitante_nome'] = nome;
        if (fone != null && fone.isNotEmpty) localData['solicitante_telefone'] = fone;
        await _writeLocalData(localData);

        // Atualiza última atividade em segundo plano
        _supabase.from('dispositivos_autorizados').update({
          'ultima_atividade': DateTime.now().toIso8601String(),
          if (userId != null) 'user_id': userId,
        }).eq('device_id', deviceId).catchError((_) => {});

        return {
          'status': status,
          'isApproved': isApproved,
          'motivo': motivo,
          'solicitante_nome': existing['solicitante_nome'] ?? nome,
        };
      } else {
        // Se o dispositivo ainda não existe na base, registra-o como pendente
        try {
          await _supabase.from('dispositivos_autorizados').insert({
            'device_id': deviceId,
            'device_model': deviceModel,
            'sistema_operacional': os,
            'solicitante_nome': nome,
            'solicitante_telefone': fone,
            if (userId != null) 'user_id': userId,
            'status': 'pendente',
            'created_at': DateTime.now().toIso8601String(),
            'ultima_atividade': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        localData['status'] = 'pendente';
        localData['is_approved'] = false;
        await _writeLocalData(localData);

        return {
          'status': 'pendente',
          'isApproved': false,
          'motivo': null,
          'solicitante_nome': nome,
        };
      }
    } catch (eDirect) {
      debugPrint('[DeviceSecurityService] Consulta direta à tabela: $eDirect. Tentando fallback via RPC...');
    }

    // 2. Fallback via RPC
    try {
      final res = await _supabase.rpc('registrar_ou_consultar_dispositivo', params: {
        'p_device_id': deviceId,
        'p_device_model': deviceModel,
        'p_sistema_operacional': os,
        'p_solicitante_nome': nome,
        'p_solicitante_telefone': fone,
        'p_user_id': userId,
      });

      if (res != null && res is List && res.isNotEmpty) {
        final row = res.first as Map<String, dynamic>;
        final status = (row['status'] as String? ?? 'pendente').toLowerCase();
        final isApproved = status == 'aprovado';
        final motivo = row['motivo_bloqueio'] as String?;

        // Atualiza cache local
        localData['status'] = status;
        localData['is_approved'] = isApproved;
        localData['motivo_bloqueio'] = motivo;
        localData['last_remote_check'] = DateTime.now().toIso8601String();
        if (nome != null && nome.isNotEmpty) localData['solicitante_nome'] = nome;
        if (fone != null && fone.isNotEmpty) localData['solicitante_telefone'] = fone;
        await _writeLocalData(localData);

        return {
          'status': status,
          'isApproved': isApproved,
          'motivo': motivo,
          'solicitante_nome': row['solicitante_nome'] ?? nome,
        };
      }
    } catch (e) {
      debugPrint('[DeviceSecurityService] Falha ao consultar Supabase (possível offline): $e');
      
      // Fallback Offline: se já havia sido aprovado antes, mantém liberado para vistorias em campo
      final wasApproved = localData['is_approved'] == true;
      if (wasApproved) {
        return {
          'status': 'aprovado',
          'isApproved': true,
          'motivo': null,
          'isOffline': true,
        };
      }
    }

    // Retorna status local cacheado
    final currentStatus = (localData['status'] as String? ?? 'pendente').toLowerCase();
    return {
      'status': currentStatus,
      'isApproved': currentStatus == 'aprovado',
      'motivo': localData['motivo_bloqueio'],
      'isOffline': true,
    };
  }

  /// Verifica se o dispositivo está aprovado para uso
  Future<bool> isDeviceApproved({bool forceRemote = false, String? userId}) async {
    if (_isMasterBypass) return true;

    final data = await _readLocalData();
    final bool cachedApproved = data['is_approved'] == true;

    // Se já foi aprovado e a verificação não é forçada, verifica validade do cache (12 horas)
    if (cachedApproved && !forceRemote) {
      final lastCheckStr = data['last_remote_check'] as String?;
      if (lastCheckStr != null) {
        final lastCheck = DateTime.tryParse(lastCheckStr);
        if (lastCheck != null &&
            DateTime.now().difference(lastCheck).inHours < 12) {
          return true;
        }
      }
    }

    // Consulta remota
    final result = await checkDeviceStatus(userId: userId);
    return result['isApproved'] == true;
  }
}
