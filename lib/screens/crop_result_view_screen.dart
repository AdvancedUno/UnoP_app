import 'dart:io';
import 'package:flutter/material.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';

// StatefulWidget for displaying the crop result screen.
class PickerCropResultScreen extends StatefulWidget {
  final Stream<InstaAssetsExportDetails>
      cropStream; // Stream to listen for crop results.

  // Constructor requiring the crop result stream.
  const PickerCropResultScreen({super.key, required this.cropStream});

  @override
  State<PickerCropResultScreen> createState() => _PickerCropResultScreenState();
}

// State class for PickerCropResultScreen.
class _PickerCropResultScreenState extends State<PickerCropResultScreen> {
  List<File> croppedFiles = []; // List to store cropped files.
  List<AssetEntity> selectedAssets = []; // List to store selected assets.

  @override
  void initState() {
    super.initState();
    // Listen to the crop result stream.
    widget.cropStream.listen((details) {
      // When progress is complete (1.0), update state with cropped files and selected assets.
      if (details.progress == 1.0) {
        setState(() {
          croppedFiles = details.croppedFiles;
          selectedAssets = details.selectedAssets;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the available height for the UI.
    final height = MediaQuery.of(context).size.height - kToolbarHeight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insta Picker Result'),
        actions: <Widget>[
          // Button to confirm and return the cropped files.
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, croppedFiles);
            },
          ),
        ],
      ),
      // Display the crop result view.
      body: CropResultView(
        croppedFiles: croppedFiles,
        heightFiles: height / 2, // Allocate half height for cropped files.
        selectedAssets: selectedAssets,
      ),
    );
  }
}

// StatelessWidget for displaying crop results.
class CropResultView extends StatelessWidget {
  final List<File> croppedFiles; // List of cropped files.
  final double heightFiles; // Height allocated for cropped images list.
  final double heightAssets; // Height allocated for selected assets list.
  final List<AssetEntity> selectedAssets; // List of selected assets.

  // Constructor for initializing required values.
  const CropResultView({
    super.key,
    required this.croppedFiles,
    required this.selectedAssets,
    this.heightFiles = 300.0, // Default height for cropped files list.
    this.heightAssets = 120.0, // Default height for selected assets list.
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _buildCroppedImagesListView(context), // Build cropped images list view.
        _buildSelectedAssetsListView(
            context), // Build selected assets list view.
      ],
    );
  }

  // Widget for displaying the list of cropped images.
  Widget _buildCroppedImagesListView(BuildContext context) {
    // If there are no cropped files, show nothing.
    if (croppedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    // List view for displaying cropped files.
    return SizedBox(
      height: heightFiles, // Set specific height for the cropped images list.
      child: ListView.builder(
        physics: const BouncingScrollPhysics(), // Smooth scrolling effect.
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: croppedFiles.length,
        itemBuilder: (BuildContext _, int index) {
          // Display each cropped image in the list.
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Image.file(croppedFiles[index]),
            ),
          );
        },
      ),
    );
  }

  // Widget for displaying the list of selected assets.
  Widget _buildSelectedAssetsListView(BuildContext context) {
    // If there are no selected assets, show nothing.
    if (selectedAssets.isEmpty) return const SizedBox.shrink();

    // List view for displaying selected assets.
    return SizedBox(
      height: heightAssets, // Set specific height for the selected assets list.
      child: ListView.builder(
        physics: const BouncingScrollPhysics(), // Smooth scrolling effect.
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        scrollDirection: Axis.horizontal,
        itemCount: selectedAssets.length,
        itemBuilder: (BuildContext _, int index) {
          final AssetEntity asset = selectedAssets.elementAt(index);

          // Display each selected asset in the list.
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: RepaintBoundary(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image(image: AssetEntityImageProvider(asset)),
              ),
            ),
          );
        },
      ),
    );
  }
}
