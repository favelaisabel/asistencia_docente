import 'dart:async';

/// Utilidades de streams sin dependencias externas.
extension CambiarStream<T> on Stream<T> {
  /// Por cada evento cambia a un nuevo stream y cancela el anterior
  /// (equivalente a `switchMap`).
  Stream<R> cambiarA<R>(Stream<R> Function(T valor) crear) {
    late StreamController<R> controlador;
    StreamSubscription<T>? externa;
    StreamSubscription<R>? interna;

    controlador = StreamController<R>(
      onListen: () {
        externa = listen(
          (valor) {
            unawaited(interna?.cancel());
            interna = crear(
              valor,
            ).listen(controlador.add, onError: controlador.addError);
          },
          onError: controlador.addError,
          onDone: () async {
            await interna?.cancel();
            await controlador.close();
          },
        );
      },
      onCancel: () async {
        await interna?.cancel();
        await externa?.cancel();
      },
    );
    return controlador.stream;
  }
}
