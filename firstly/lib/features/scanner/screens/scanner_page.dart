import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../core/theme/app_theme.dart';
import '../services/ocr_service.dart';
import './review_page.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({Key? key}) : super(key: key);

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _cameraController;
  final OcrService _ocrService = OcrService();
  bool _isProcessing = false;
  
  String _selectedVendor = 'Continente';
  final List<String> _vendors = ['Continente', 'Pingo Doce', 'Lidl'];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _cameraController!.takePicture();
      
      // Scan com spatial matching (bounding boxes) para emparelhar itens e preços
      final parsedItems = await _ocrService.scanReceipt(image.path, _selectedVendor);

      if (mounted) {
        if (parsedItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum item reconhecido. Tente novamente com melhor iluminação.')),
          );
        } else {
          // Navigate to Review Page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewPage(scannedItems: parsedItems),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedVendor,
            dropdownColor: Colors.grey[900],
            style: const TextStyle(color: Colors.white, fontSize: 18),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: _vendors.map((String vendor) {
              return DropdownMenuItem<String>(
                value: vendor,
                child: Text(vendor),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedVendor = newValue;
                });
              }
            },
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
          
          // Overlay UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_isProcessing)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
                        ),
                        SizedBox(width: 10),
                        Text('A processar fatura...', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),

                // Capture Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _captureAndProcess,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isProcessing ? Colors.grey : AppTheme.primaryGreen.withOpacity(0.8),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
