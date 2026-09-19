import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'background_tasks_state.dart';

import '../../../../injection_container.dart';
import '../../../../features/consulta_bin/data/services/radar_service.dart';

class BackgroundTasksCubit extends Cubit<BackgroundTasksState> {
  BackgroundTasksCubit() : super(const BackgroundTasksState());

  final _uuid = const Uuid();

  /// Inicia uma pesquisa avulsa em background
  Future<void> iniciarPesquisaAvulsa({
    required String produto,
    required String parametro,
    required String valor,
    required String titulo,
    bool forcarNova = false,
    String? tokenConsulta,
    String? redirectPath,
    Map<String, dynamic>? redirectExtra,
  }) async {
    final taskId = _uuid.v4();
    final newTask = BackgroundTask(
      id: taskId,
      title: titulo,
      subtitle: 'Buscando $parametro $valor...',
      createdAt: DateTime.now(),
      status: BackgroundTaskStatus.running,
      redirectPath: redirectPath,
      redirectExtra: redirectExtra,
    );

    // Adiciona a tarefa rodando na lista
    emit(state.copyWith(
      tasks: [newTask, ...state.tasks],
    ));

    try {
      final service = sl<RadarService>();
      final veiculo = await service.consultarVeiculo(
        produto: produto,
        param: parametro,
        value: valor,
        vistoriaId: '',
        forcarNova: forcarNova,
        tokenConsulta: tokenConsulta,
      );

      // Sucesso
      _updateTask(
        taskId,
        status: BackgroundTaskStatus.success,
        subtitle: 'Consulta finalizada com sucesso!',
        resultData: veiculo,
      );
    } catch (e) {
      final erroMsg = e.toString().replaceAll('Exception: ', '').trim();
      final bool isEmAndamento = erroMsg.contains('análise técnica') ||
          erroMsg.contains('em andamento') ||
          erroMsg.contains('processamento') ||
          erroMsg.contains('aberta na Radar');

      if (isEmAndamento) {
         _updateTask(
          taskId,
          status: BackgroundTaskStatus.success,
          subtitle: 'Pesquisa em análise técnica (Detran). Verifique depois.',
          errorMessage: erroMsg,
        );
      } else {
        // Erro real
        _updateTask(
          taskId,
          status: BackgroundTaskStatus.error,
          subtitle: 'Falha na consulta',
          errorMessage: erroMsg,
        );
      }
    }
  }

  void marcarComoLida(String taskId) {
    final newTasks = state.tasks.map((task) {
      if (task.id == taskId) {
        return task.copyWith(isRead: true);
      }
      return task;
    }).toList();
    emit(state.copyWith(tasks: newTasks));
  }

  void _updateTask(
    String id, {
    required BackgroundTaskStatus status,
    required String subtitle,
    String? errorMessage,
    dynamic resultData,
  }) {
    final newTasks = state.tasks.map((task) {
      if (task.id == id) {
        return task.copyWith(
          status: status,
          subtitle: subtitle,
          errorMessage: errorMessage,
          resultData: resultData,
        );
      }
      return task;
    }).toList();

    emit(state.copyWith(tasks: newTasks));
  }
}
