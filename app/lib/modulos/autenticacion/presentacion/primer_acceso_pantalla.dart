import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/mensajes.dart';
import '../../../dominio/contrasena.dart';
import '../../../dominio/correo.dart';
import '../../../dominio/sesion.dart';
import '../aplicacion/destino.dart';
import '../aplicacion/providers.dart';
import 'componentes.dart';

/// Primer acceso de una persona pre-registrada (RF-004, ADR-005, C-21):
/// 1) crea su contraseña, 2) confirma su correo, 3) se crea su perfil.
class PrimerAccesoPantalla extends ConsumerStatefulWidget {
  const PrimerAccesoPantalla({super.key});

  @override
  ConsumerState<PrimerAccesoPantalla> createState() =>
      _PrimerAccesoPantallaState();
}

class _PrimerAccesoPantallaState extends ConsumerState<PrimerAccesoPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _enviando = false;
  String? _error;
  String? _aviso;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _ejecutar(
    Future<void> Function() accion, {
    String? exito,
  }) async {
    setState(() {
      _enviando = true;
      _error = null;
      _aviso = null;
    });
    try {
      await accion();
      if (mounted && exito != null) setState(() => _aviso = exito);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sesion = ref.watch(sesionProvider).value;
    final repositorio = ref.read(autenticacionRepositorioProvider);

    final List<Widget> contenido = switch (sesion) {
      PendienteVerificacion(:final correo) => [
        Text(
          'Te enviamos un enlace a $correo. Ábrelo para confirmar tu correo '
          'y después pulsa «Continuar».',
        ),
        const SizedBox(height: 24),
        _botonPrincipal(
          'Continuar',
          () => _ejecutar(repositorio.completarPerfil),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _enviando
              ? null
              : () => _ejecutar(
                  repositorio.reenviarVerificacion,
                  exito: 'Enlace reenviado. Revisa tu correo.',
                ),
          child: const Text('Reenviar enlace'),
        ),
        TextButton(
          onPressed: repositorio.cerrarSesion,
          child: const Text('Cancelar'),
        ),
      ],
      SinPerfil() => [
        const Text(
          'Tu correo está confirmado. Pulsa «Continuar» para terminar.',
        ),
        const SizedBox(height: 24),
        _botonPrincipal(
          'Continuar',
          () => _ejecutar(repositorio.completarPerfil),
        ),
        TextButton(
          onPressed: repositorio.cerrarSesion,
          child: const Text('Cancelar'),
        ),
      ],
      _ => [
        const Text(
          'Si Coordinación ya te dio de alta, crea aquí tu contraseña con tu '
          'correo institucional.',
        ),
        const SizedBox(height: 16),
        _formularioCuenta(),
        const SizedBox(height: 16),
        _botonPrincipal('Crear contraseña', () {
          if (!(_formulario.currentState?.validate() ?? false)) return;
          _ejecutar(
            () => repositorio.crearCuenta(
              correo: _correo.text,
              contrasena: _contrasena.text,
            ),
          );
        }),
        TextButton(
          onPressed: () => context.go(Rutas.entrar),
          child: const Text('Ya tengo contraseña: Entrar'),
        ),
      ],
    };

    return MarcoAcceso(
      titulo: 'Primer acceso',
      hijos: [
        ...contenido,
        if (_error != null) ...[
          const SizedBox(height: 16),
          AvisoError(_error!),
        ],
        if (_aviso != null) ...[
          const SizedBox(height: 16),
          Semantics(liveRegion: true, child: Text(_aviso!)),
        ],
      ],
    );
  }

  Widget _botonPrincipal(String texto, VoidCallback accion) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: _enviando ? null : accion,
        child: _enviando
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(texto),
      ),
    );
  }

  Widget _formularioCuenta() {
    return Form(
      key: _formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _correo,
            decoration: const InputDecoration(
              labelText: 'Correo institucional',
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Escribe tu correo.';
              if (!esCorreoValido(v)) return 'Escribe un correo válido.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contrasena,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              helperText:
                  'Al menos $longitudMinimaContrasena caracteres, con letras y números.',
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) {
              final problema = validarContrasena(v ?? '');
              return problema == null ? null : mensajeContrasena(problema);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmacion,
            decoration: const InputDecoration(
              labelText: 'Repite la contraseña',
            ),
            obscureText: true,
            validator: (v) =>
                v == _contrasena.text ? null : 'Las contraseñas no coinciden.',
          ),
        ],
      ),
    );
  }
}
