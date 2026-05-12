import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();
  final controller = StreamController<bool>();

  void emit(bool hasInternet) {
    if (!controller.isClosed) controller.add(hasInternet);
  }

  connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
    emit(result.any((r) => r != ConnectivityResult.none));
  });

  connectivity.checkConnectivity().then((List<ConnectivityResult> result) {
    emit(result.any((r) => r != ConnectivityResult.none));
  });

  ref.onDispose(() => controller.close());

  return controller.stream;
});
