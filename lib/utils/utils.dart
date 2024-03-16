import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';

// for picking up image from gallery
pickImage(ImageSource source) async {
  final ImagePicker imagePicker = ImagePicker();
  XFile? file = await imagePicker.pickImage(
    source: source,
    imageQuality: 5,
  );
  if (file != null) {
    return await file.readAsBytes();
  }
}

// for displaying snackbars
showSnackBar(BuildContext context, String text) {
  return ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
    ),
  );
}

Widget buildListItem(
  BuildContext context, {
  required Widget title,
  required leading,
  required trailing,
}) {
  final theme = Theme.of(context);

  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 16.0,
    ),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.dividerColor,
          width: 0.5,
        ),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (leading != null) leading,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            child: title,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    ),
  );
}

// Future function to show an End-User License Agreement (EULA) dialog.
// Returns a Future<bool> indicating whether the user accepted the EULA.
Future<bool> showEulaDialog(BuildContext context) async {
  // Completer to manually complete the Future based on user action.
  Completer<bool> _completion = Completer<bool>();

  // Show dialog asynchronously.
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      // Building the dialog with AlertDialog widget.
      return AlertDialog(
        title: Text('End-User License Agreement'),
        // Use a container to constrain the height of the WebView.
        content: Container(
          width: double.maxFinite,
          height: 400, // Set the height as needed.
          // Embedding a WebView to display the EULA content.
          child: WebView(
            initialUrl:
                'https://www.termsfeed.com/live/0b74925b-6b3a-4fdb-966a-e5001ecd797b',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController controller) {
              // Evaluate JavaScript when the page is loaded to add a scroll listener.
              // This listener changes the URL to signal acceptance when the user scrolls to the bottom.
              controller.evaluateJavascript('''
                window.addEventListener("scroll", function(){
                  if((window.innerHeight + window.scrollY) >= document.body.offsetHeight) {
                    window.location.href = 'https://www.termsfeed.com/live/0b74925b-6b3a-4fdb-966a-e5001ecd797b/accepted';
                  }
                });
              ''');
            },
            // Handling navigation requests within the WebView.
            navigationDelegate: (NavigationRequest request) {
              // Check if the navigation request URL matches the acceptance URL.
              if (request.url ==
                  'https://www.termsfeed.com/live/0b74925b-6b3a-4fdb-966a-e5001ecd797b/accepted') {
                // If so, pop the dialog and indicate acceptance.
                Navigator.of(context).pop(true);
                // Prevent further navigation since we've handled it.
                return NavigationDecision.prevent;
              }
              // Allow all other navigations.
              return NavigationDecision.navigate;
            },
          ),
        ),
        actions: <Widget>[
          Text(
              "Do you agree on above term and agree that no tolerance for objectionable content or abusive users?"),
          TextButton(
            onPressed: () {
              // Pop the dialog and indicate disagreement.
              Navigator.of(context).pop(true);
            },
            child: Text('Agree'),
          ),
          // Button to explicitly disagree, dismissing the dialog.
          TextButton(
            onPressed: () {
              // Pop the dialog and indicate disagreement.
              Navigator.of(context).pop(false);
            },
            child: Text('Disagree'),
          ),
        ],
      );
    },
  ).then((value) {
    // Once the dialog is dismissed, check if the completion has not already been completed.
    if (!_completion.isCompleted) {
      // Complete the completer with the value (true if accepted, false otherwise).
      _completion.complete(value ?? false);
    }
  });

  // Return the future of the completer, which resolves to the user's decision.
  return _completion.future;
}
