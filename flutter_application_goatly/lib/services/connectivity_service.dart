import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// ── STREAM-BASED NETWORK MONITORING ─────────────────────────────────────────
///
/// ESTRATEGIA DE MULTITHREADING — STREAM:
///
/// Un Stream en Dart es un canal de eventos asíncronos. A diferencia de un
/// Future (que resuelve UNA vez), un Stream emite MÚLTIPLES valores a lo largo
/// del tiempo. Aquí lo usamos para escuchar cambios de red en tiempo real.
///
/// Flujo completo:
///   1. `connectivity_plus` corre en un isolate del sistema operativo y emite
///      `List<ConnectivityResult>` cada vez que la red cambia (Wi-Fi ↔ datos ↔ none).
///   2. ConnectivityService escucha ese stream y lo transforma en un stream
///      booleano simple: true = online, false = offline.
///   3. AppState suscribe a `onConnectivityChanged` y actúa: si pasa a online,
///      lanza SyncService.flushPendingOperations() para sincronizar cola offline.
///   4. Las vistas leen `AppState.isOnline` (via Provider) y muestran/ocultan
///      el banner de "Sin conexión" en tiempo real, sin polling ni setState manual.
class ConnectivityService {
  // StreamController.broadcast() permite MÚLTIPLES suscriptores simultáneos.
  // (Un StreamController normal solo admite un suscriptor a la vez.)
  static final _controller = StreamController<bool>.broadcast();

  // Referencia a la suscripción activa — necesaria para cancelarla en dispose().
  static StreamSubscription<List<ConnectivityResult>>? _sub;

  // Estado de red actual en memoria — leído síncronamente por cualquier widget.
  static bool _isOnline = true;

  /// Devuelve true si hay conexión activa. Lectura síncrona, O(1).
  static bool get isOnline => _isOnline;

  /// Stream que emite `true` cuando hay red y `false` cuando se pierde.
  /// Es broadcast: múltiples listeners pueden suscribirse (AppState, widgets).
  static Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Inicia el monitoreo de red. Llamar UNA vez al arrancar la app.
  static void initialize() {
    // ── SUSCRIPCIÓN AL STREAM DEL PLUGIN ────────────────────────────────────
    // `Connectivity().onConnectivityChanged` es un Stream provisto por el plugin.
    // El plugin corre en un background isolate del SO (no bloquea el UI thread).
    // `listen()` registra un callback que se ejecuta CADA VEZ que la red cambia.
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      // `results` es List<ConnectivityResult>: puede haber wifi + datos al mismo tiempo.
      // Si AL MENOS UNO no es `none`, consideramos que hay conexión.
      final online = results.any((r) => r != ConnectivityResult.none);

      // Solo emitir si el estado CAMBIÓ — evita eventos redundantes.
      if (online != _isOnline) {
        _isOnline = online; // actualizar estado interno
        _controller.add(online); // emitir nuevo valor en el Stream
        // → AppState recibirá este evento y actuará (flush + reload).
      }
    });

    // ── ESTADO INICIAL ───────────────────────────────────────────────────────
    // `listen()` solo escucha CAMBIOS futuros. Para saber el estado ACTUAL
    // al arrancar la app, hacemos una consulta puntual asíncrona.
    // `unawaited` porque no bloqueamos el arranque — el UI ya puede pintar.
    _checkInitial();
  }

  /// Consulta el estado de red actual al inicializar (no espera cambios futuros).
  static Future<void> _checkInitial() async {
    // checkConnectivity() hace UNA consulta puntual al SO — no suscribe a cambios.
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    // Emitir el estado inicial al Stream para que AppState arranque correcto.
    _controller.add(_isOnline);
  }

  /// Cancela la suscripción y cierra el stream. Llamar al cerrar la app.
  static void dispose() {
    _sub?.cancel(); // cancela el listener del plugin — libera recursos del SO
    _controller.close(); // cierra el StreamController — libera memoria
  }
}
