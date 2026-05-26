import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Guarantees that only one Taskline process is alive at a time, and lets
/// subsequent launches surface the existing window.
///
/// Mechanism:
///   1. Bind a TCP socket on a fixed loopback port. The OS gives this to
///      exactly one process — that's our "first instance" guarantee.
///   2. When a later launch tries to bind, it fails immediately. It then
///      *connects* to the existing instance over the same port and sends a
///      "show" command, before exiting.
///   3. The first instance receives the command in its already-running event
///      loop and invokes the [onActivate] callback — which can use
///      window_manager (or anything else that's already initialised) to
///      properly un-hide the window. Win32 FindWindow + ShowWindow was tried
///      first but doesn't reverse window_manager.hide() reliably.
class SingleInstance {
  SingleInstance._();

  // Stable loopback port in the IANA dynamic range; unlikely to collide.
  static const int _port = 49150;
  static const String _windowTitle = 'Taskline';

  // Kept alive for the process lifetime so the port stays bound.
  // ignore: unused_field
  static ServerSocket? _server;

  /// Returns true if this process is the first instance.
  ///
  /// [onActivate] runs inside the first instance whenever a subsequent launch
  /// connects. Use it to surface the window.
  ///
  /// If another instance is already running, this connects to it, signals it
  /// to activate, then exits the current process — the function does not
  /// return in that case.
  static Future<bool> acquireOrForward({
    required FutureOr<void> Function() onActivate,
  }) async {
    try {
      final server =
          await ServerSocket.bind(InternetAddress.loopbackIPv4, _port);
      _server = server;
      server.listen(
        (Socket socket) async {
          // Drain incoming data; the message is just a wake-up signal, but we
          // still need to consume to let the connection close cleanly.
          socket.listen((_) {}, onDone: () => socket.destroy(),
              onError: (_) => socket.destroy());
          try {
            await onActivate();
          } catch (e) {
            stderr.writeln('[SingleInstance] onActivate failed: $e');
          }
        },
        onError: (e) => stderr.writeln('[SingleInstance] listen error: $e'),
      );
      stderr.writeln('[SingleInstance] bound port $_port (first instance)');
      return true;
    } on SocketException catch (e) {
      stderr.writeln(
          '[SingleInstance] port $_port busy, forwarding to existing instance: ${e.message}');
      await _signalExistingInstance();
      exit(0);
    }
  }

  static Future<void> _signalExistingInstance() async {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _port,
        timeout: const Duration(seconds: 2),
      );
      socket.write('show');
      await socket.flush();
      await socket.close();
      stderr.writeln('[SingleInstance] signalled existing instance');
    } catch (e) {
      stderr.writeln(
          '[SingleInstance] could not signal existing instance ($e); falling back to Win32');
      _win32ShowWindow();
    }
  }

  static void _win32ShowWindow() {
    if (!Platform.isWindows) return;
    final titlePtr = _windowTitle.toNativeUtf16();
    try {
      final hWnd = FindWindow(nullptr, titlePtr);
      if (hWnd == 0) return;
      // SW_SHOW = 5 (just make visible). SW_RESTORE = 9 (un-minimize). Do both.
      ShowWindow(hWnd, 5);
      ShowWindow(hWnd, SW_RESTORE);
      SetForegroundWindow(hWnd);
    } finally {
      malloc.free(titlePtr);
    }
  }
}
