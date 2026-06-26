import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/mock/mock_consulta_bin.dart';
import 'database/app_database.dart';
import 'database/daos/vistoria_dao.dart';
import 'database/daos/bin_dao.dart';
import 'database/daos/autocred_dao.dart';
import 'features/consulta_bin/data/repositories/radar_repository.dart';
import 'features/consulta_bin/data/services/radar_service.dart';
import 'core/services/image_service.dart';
import 'core/services/ocr_service.dart';
import 'core/services/pdf_generator_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await sl.reset();
  // ── Supabase ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ── Banco local (Drift) ───────────────────────────────────────────────────
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());

  sl.registerLazySingleton<VistoriaDao>(
    () => sl<AppDatabase>().vistoriaDao,
  );

  sl.registerLazySingleton<BinDao>(
    () => sl<AppDatabase>().binDao,
  );

  sl.registerLazySingleton<AutocredDao>(
    () => sl<AppDatabase>().autocredDao,
  );

  // ── Radar Consultas ───────────────────────────────────────────────────────
  sl.registerLazySingleton<RadarRepository>(
    () => RadarRepository(supabase: sl<SupabaseClient>(), localDao: sl<AutocredDao>()),
  );
  sl.registerLazySingleton<RadarService>(
    () => RadarService(supabase: sl<SupabaseClient>(), repository: sl<RadarRepository>()),
  );

  // ── Mock ──────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MockConsultaBinDatasource>(
    () => MockConsultaBinDatasource(),
  );

  // ── Serviços de Imagem e OCR ──────────────────────────────────────────────
  sl.registerLazySingleton<ImageService>(
    () => ImageService(supabase: sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<OcrService>(
    () => OcrService(),
  );
  sl.registerLazySingleton<PdfGeneratorService>(
    () => PdfGeneratorService(),
  );
}
