import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const ScanScreen({Key? key, required this.onToggleTheme}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _serialController = TextEditingController();
  String? _errorText;

  final Color darkNavy = const Color(0xFF001F3F); // Dark navy color

  Future<void> scanBarcode() async {
    try {
      var result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _navigateToResults(result.rawContent.trim());
      }
    } catch (e) {
      // TODO: Handle error or cancellation if needed
    }
  }

  void _navigateToResults(String serialNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(serialNumber: serialNumber),
      ),
    );
  }

  void _submitManual() {
    final serial = _serialController.text.trim();
    if (serial.isEmpty) {
      setState(() {
        _errorText = 'Please enter a serial number';
      });
    } else {
      setState(() {
        _errorText = null;
      });
      _navigateToResults(serial);
    }
  }

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: darkNavy,
        title: const Text(
          'Serial History Viewer',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: Image.asset(
                        'assets/fppicture.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      onPressed: scanBarcode,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        'Scan Barcode',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkNavy,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Enter Serial Number Manually',
                        style: TextStyle(
                          color: darkNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _serialController,
                      decoration: InputDecoration(
                        labelText: 'Serial Number',
                        border: const OutlineInputBorder(),
                        errorText: _errorText,
                      ),
                      onSubmitted: (_) => _submitManual(),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitManual,
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkNavy,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 65),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
