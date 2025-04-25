import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription? _linkSubscription;
  bool _initialURILinkHandled = false;

  Future<void> handleInitialUri(Function(Uri) onLink) async {
    if (!_initialURILinkHandled) {
      _initialURILinkHandled = true;
      try {
        if (!kIsWeb) {
          final uri = await getInitialUri();
          if (uri != null) {
            debugPrint('Initial URI received $uri');
            onLink(uri);
          }
        } else {
          // For web, we can parse the current URL
          final uri = Uri.base;
          if (uri.path.contains('verify-email')) {
            debugPrint('Initial web URI received $uri');
            onLink(uri);
          }
        }
      } catch (e) {
        debugPrint('Error handling initial URI: $e');
      }
    }
  }

  void handleIncomingLinks(Function(Uri) onLink) {
    if (_linkSubscription != null) {
      _linkSubscription?.cancel();
    }

    if (!kIsWeb) {
      // Only set up stream listener for non-web platforms
      _linkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          debugPrint('Received URI: $uri');
          if (uri != null) {
            onLink(uri);
          }
        },
        onError: (err) {
          debugPrint('Error handling incoming links: $err');
        },
      );
    }
    // For web, we don't need to set up a stream as the page will reload with new URLs
  }

  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
  }
} 