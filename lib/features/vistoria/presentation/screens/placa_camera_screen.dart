import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../core/theme/app_theme.dart';

/// Tela de câmera inline para leitura OCR de placa em tempo real.
/// Retorna a placa detectada via Navigator.pop(context, placa).
class PlacaCameraScreen extends StatefulWidget {
  const PlacaCameraScreen({super.key});

  @override
  State<PlacaCameraScreen> createState() => _PlacaCameraScreenState();
}

class _PlacaCameraScreenState extends State<PlacaCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _isProcessing = false;
  bool _isCameraReady = false;
  String? _placaDetectada;
  String _statusMsg = 'Aponte a câmera para a placa do veículo';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) return;

      final camera = _cameras!.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.nv21,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;

      setState(() => _isCameraReady = true);

      _controller!.startImageStream(_processFrame);
    } catch (e) {
      if (mounted) {
        setState(() => _statusMsg = 'Erro ao acessar a câmera: $e');
      }
    }
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _isProcessing = true;
      try {
        final inputImage = _buildInputImage(image);
        if (inputImage == null) return;

        final recognizedText = await _textRecognizer.processImage(inputImage);

        final placa = _extrairPlaca(recognizedText.text);

        if (placa != null && mounted) {
          setState(() {
            _placaDetectada = placa;
            _statusMsg = 'Placa detectada! ✓';
          });
          // Para o stream e retorna automaticamente após 500ms
          await _controller?.stopImageStream();
          await Future.delayed(const Duration(milliseconds: 600));
          if (mounted) Navigator.of(context).pop(placa);
        }
      } catch (_) {
        // Ignora erros de frame individual
      } finally {
        _isProcessing = false;
      }
    });
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_controller == null || _cameras == null || _cameras!.isEmpty) {
      return null;
    }

    final camera = _cameras!.first;
    final rotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  /// Extrai placa no formato Mercosul (AAA1A11) ou antigo (AAA-1111 / AAA1111)
  String? _extrairPlaca(String texto) {
    final texto_ = texto.toUpperCase().replaceAll(RegExp(r'\s'), '');

    // Padrão Mercosul: 3 letras + 1 dígito + 1 letra + 2 dígitos (ABC1D23)
    final mercosul = RegExp(r'[A-Z]{3}[0-9][A-Z][0-9]{2}');
    final mMatch = mercosul.firstMatch(texto_);
    if (mMatch != null) return mMatch.group(0);

    // Padrão antigo: 3 letras + 4 dígitos (ABC1234)
    final antigo = RegExp(r'[A-Z]{3}[0-9]{4}');
    final aMatch = antigo.firstMatch(texto_);
    if (aMatch != null) return aMatch.group(0);

    return null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Fotografar Placa'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          // Preview da câmera
          if (_isCameraReady && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Máscara com recorte para a placa
          if (_isCameraReady) _buildMask(context),

          // Status message
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStatusBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildMask(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameW = size.width * 0.82;
    final frameH = frameW * 0.28;
    final frameLeft = (size.width - frameW) / 2;
    final frameTop = size.height * 0.35;

    return Stack(
      children: [
        // Escurecimento com buraco central
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.55),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Positioned(
                left: frameLeft,
                top: frameTop,
                child: Container(
                  width: frameW,
                  height: frameH,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Borda da área de leitura
        Positioned(
          left: frameLeft,
          top: frameTop,
          child: Container(
            width: frameW,
            height: frameH,
            decoration: BoxDecoration(
              border: Border.all(
                color: _placaDetectada != null
                    ? AppTheme.conforme
                    : Colors.white,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        // Cantos decorativos
        ..._buildCorners(frameLeft, frameTop, frameW, frameH),

        // Label acima do frame
        Positioned(
          left: frameLeft,
          top: frameTop - 36,
          width: frameW,
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Enquadre a placa aqui',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),

        // Placa detectada exibida dentro do frame
        if (_placaDetectada != null)
          Positioned(
            left: frameLeft,
            top: frameTop,
            width: frameW,
            height: frameH,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.conforme.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _placaDetectada!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCorners(
      double left, double top, double w, double h) {
    const size = 20.0;
    const thickness = 3.0;
    final color =
        _placaDetectada != null ? AppTheme.conforme : Colors.white;

    Widget corner(double l, double t, bool flipH, bool flipV) {
      return Positioned(
        left: l,
        top: t,
        child: Transform.scale(
          scaleX: flipH ? -1 : 1,
          scaleY: flipV ? -1 : 1,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(painter: _CornerPainter(color, thickness)),
          ),
        ),
      );
    }

    return [
      corner(left - 1, top - 1, false, false),
      corner(left + w - size + 1, top - 1, true, false),
      corner(left - 1, top + h - size + 1, false, true),
      corner(left + w - size + 1, top + h - size + 1, true, true),
    ];
  }

  Widget _buildStatusBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_placaDetectada == null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              if (_placaDetectada != null)
                const Icon(Icons.check_circle_rounded,
                    color: AppTheme.conforme, size: 18),
              const SizedBox(width: 8),
              Text(
                _statusMsg,
                style: TextStyle(
                  color: _placaDetectada != null
                      ? AppTheme.conforme
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.keyboard_rounded, size: 18),
            label: const Text('Digitar manualmente'),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ],
      ),
    );
  }
}

// ── Pintor de cantos decorativos ──────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;

  _CornerPainter(this.color, this.thickness);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.thickness != thickness;
}
