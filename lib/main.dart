import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "YOUR_API_KEY",
      projectId: "temtech-f2a77",
      messagingSenderId: "1059350868768",
      appId: "1:1059350868768:web:9a9054a995f4c5c1825d45",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? filename;
  String? uploadStatus;
  double uploadProgress = 0.0;

  Future<String?> uploadFileAndGetUrl(
      Uint8List fileBytes, String fileName) async {
    try {
      firebase_storage.Reference ref =
          firebase_storage.FirebaseStorage.instance.ref().child(fileName);
      firebase_storage.UploadTask uploadTask = ref.putData(fileBytes);

      // Listen for state changes, errors, and completion of the upload.
      uploadTask.snapshotEvents.listen(
          (firebase_storage.TaskSnapshot snapshot) {
        setState(() {
          uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
        });
      }, onError: (e) {
        setState(() {
          uploadStatus = 'Error uploading file: $e';
        });
      });

      // Wait until the upload is complete
      await uploadTask;

      // Get the download URL for the uploaded file
      String downloadUrl = await ref.getDownloadURL();

      // Update UI accordingly
      setState(() {
        uploadStatus = 'File uploaded successfully';
      });

      // Return the download URL
      return downloadUrl;
    } catch (e) {
      // Handle errors
      setState(() {
        uploadStatus = 'Error uploading file: $e';
      });
      return null;
    }
  }

  Future<void> pickFileAndUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
        allowMultiple: false,
      );

      if (result != null) {
        Uint8List? fileBytes = result.files.single.bytes;
        String? fileName = result.files.single.name;
        if (fileBytes != null && fileName != null) {
          // Perform file size validation here if needed
          if (fileBytes.length <= 10 * 1024 * 1024) {
            setState(() {
              filename = fileName;
            });
            String? downloadUrl =
                await uploadFileAndGetUrl(fileBytes, fileName);
            if (downloadUrl != null) {
              // File uploaded successfully, do something with the download URL
              print('Download URL: $downloadUrl');
            }
          } else {
            setState(() {
              uploadStatus = 'File size exceeds the limit (10 MB)';
            });
          }
        }
      } else {
        setState(() {
          filename = null;
          uploadStatus = 'User canceled the picker';
        });
      }
    } catch (e) {
      setState(() {
        uploadStatus = 'Error picking/uploading file: $e';
      });
    }
  }

  void clearSelection() {
    setState(() {
      filename = null;
      uploadStatus = null;
      uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("File Picker"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: pickFileAndUpload,
              child: const Text('Pick File and Upload'),
            ),
            if (filename != null) ...[
              const SizedBox(height: 20),
              Text(
                'Selected File:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                filename!,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (uploadStatus != null) ...[
                Text(
                  'Upload Status:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  uploadStatus!,
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
                if (uploadProgress > 0 && uploadProgress < 1) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Upload Progress:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: uploadProgress),
                ],
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: clearSelection,
                child: const Text('Clear Selection'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
