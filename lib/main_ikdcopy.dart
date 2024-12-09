import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_accurascan_kyc/flutter_accurascan_kyc.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Basic MaterialApp structure
    return MaterialApp(
      title: 'MICR POC Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MICRHomePage(),
    );
  }
}

class MICRHomePage extends StatefulWidget {
  const MICRHomePage({super.key});

  @override
  State<MICRHomePage> createState() => _MICRHomePageState();
}

class _MICRHomePageState extends State<MICRHomePage> {
  bool _isMICREnabled = false;
  String _scanResult = "No result yet";
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _initializeSDK();
  }

  /// Step 1: Initialize SDK and get metadata.
  Future<void> _initializeSDK() async {
    print("[LOG] Initializing Accura MICR SDK...");
    try {
      // Fetch metadata to verify license and available features
      String? metaData = await AccuraOcr.getMetaData();
      print("[LOG] Metadata fetched: $metaData");
      if (metaData != null && metaData.isNotEmpty) {
        dynamic jsonData = json.decode(metaData);
        if (jsonData is Map && jsonData.containsKey("isMICREnable")) {
          _isMICREnabled = jsonData["isMICREnable"] as bool;
          print("[LOG] MICR Enabled: $_isMICREnabled");
        } else {
          print("[ERROR] MICR enable key not found in metadata response.");
        }
      } else {
        print(
            "[ERROR] Metadata returned null or empty. Check license placement.");
      }
    } on PlatformException catch (e) {
      print("[ERROR] Error getting metadata: $e");
    }

    // If MICR is enabled, proceed to set configuration
    if (_isMICREnabled) {
      print("[LOG] Setting MICR configurations...");
      await _setAccuraConfig();
    } else {
      print("[ERROR] MICR is not enabled. Cannot proceed with configuration.");
    }
  }

  /// Step 2: Set the Accura MICR Configurations
  Future<void> _setAccuraConfig() async {
    try {
      print("[LOG] Configuring Accura Scan parameters...");
      await AccuraOcr.setLowLightTolerance(10);
      print("[LOG] setLowLightTolerance(10) done.");

      await AccuraOcr.setMinGlarePercentage(6);
      print("[LOG] setMinGlarePercentage(6) done.");

      await AccuraOcr.setMaxGlarePercentage(99);
      print("[LOG] setMaxGlarePercentage(99) done.");

      await AccuraOcr.setBlurPercentage(60);
      print("[LOG] setBlurPercentage(60) done.");

      // Set error messages and titles
      print("[LOG] Setting error codes and messages...");
      await AccuraOcr.ACCURA_ERROR_CODE_MOTION("Keep Document Steady");
      await AccuraOcr.ACCURA_ERROR_CODE_DOCUMENT_IN_FRAME(
          "Keep document in frame");
      await AccuraOcr.ACCURA_ERROR_CODE_BRING_DOCUMENT_IN_FRAME(
          "Bring card near to frame");
      await AccuraOcr.ACCURA_ERROR_CODE_PROCESSING("Processing");
      await AccuraOcr.ACCURA_ERROR_CODE_BLUR_DOCUMENT(
          "Blur detect in document");
      await AccuraOcr.ACCURA_ERROR_CODE_GLARE_DOCUMENT(
          "Glare detect in document");
      await AccuraOcr.ACCURA_ERROR_CODE_WRONG_SIDE(
          "Scanning wrong side of Document");
      await AccuraOcr.SCAN_TITLE_MICR("Scan MICR");
      await AccuraOcr.ACCURA_ERROR_CODE_MICR_IN_FRAME("Keep MICR in Frame");
      await AccuraOcr.ACCURA_ERROR_CODE_CLOSER("Move phone Closer");
      await AccuraOcr.ACCURA_ERROR_CODE_AWAY("Move phone Away");

      // Camera UI customization
      print("[LOG] Setting camera UI properties...");
      await AccuraOcr.CameraScreen_CornerBorder_Enable(false);
      await AccuraOcr.CameraScreen_Border_Width(15);
      await AccuraOcr.CameraScreen_Color("#80000000");
      await AccuraOcr.CameraScreen_Back_Button(1);
      await AccuraOcr.CameraScreen_Frame_Color("#D5323F");
      await AccuraOcr.CameraScreen_Text_Border_Color("#000000");
      await AccuraOcr.CameraScreen_Text_Color("#FFFFFF");
      await AccuraOcr.isShowLogo(1);
      // Apply the config
      await AccuraOcr.setAccuraConfigs();
      print("[LOG] setAccuraConfigs completed without errors.");
      setState(() {
        _isConfigured = true;
      });
      print("[LOG] _isConfigured set to $_isConfigured");
    } on PlatformException catch (e) {
      print("[ERROR] Error setting configuration: $e");
    }
  }

  /// Step 3: Start the MICR scanning process.
  Future<void> _startMICRScan() async {
    print(
        "[LOG] Checking if MICR is enabled and configured before scanning...");
    if (!_isMICREnabled) {
      print("[ERROR] MICR is not enabled. Cannot start scanning.");
      return;
    }
    // if (!_isConfigured) {
    //   print("[ERROR] Configuration not set. Cannot start scanning.");
    //   return;
    // }

    print("[LOG] Starting MICR scanning...");
    try {
      String result = await AccuraOcr.startMICR();
      print("[LOG] MICR scan result: $result");
      dynamic jsonResult = json.decode(result);
      setState(() {
        _scanResult = json.encode(jsonResult);
      });
    } on PlatformException catch (e) {
      print("[ERROR] Error starting MICR scan: $e");
      setState(() {
        _scanResult = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("[LOG] Building UI...");
    return Scaffold(
      appBar: AppBar(
        title: const Text("MICR POC"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("MICR Enabled: $_isMICREnabled"),
            Text("Configuration Set: $_isConfigured"),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: _startMICRScan,
                child: const Text("Start MICR Scan")),
            const SizedBox(height: 20),
            Text("Scan Result: $_scanResult"),
          ],
        ),
      ),
    );
  }
}
