import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/mensajes.dart';
import '../../../dominio/correo.dart';
import '../aplicacion/destino.dart';
import '../aplicacion/providers.dart';
import 'componentes.dart';

/// Inicio de sesión (RF-001; pantallas M-01 y W-01).
class EntrarPantalla extends ConsumerStatefulWidget {
  const EntrarPantalla({super.key});

  @override
  ConsumerState<EntrarPantalla> createState() => _EntrarPantallaState();
}

class _EntrarPantallaState extends ConsumerState<EntrarPantalla> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _ocultar = true;
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      await ref
          .read(autenticacionRepositorioProvider)
          .iniciarSesion(correo: _correo.text, contrasena: _contrasena.text);
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MarcoAcceso(
      titulo: 'Entrar',
      hijos: [
        Form(
          key: _formulario,
          child: AutofillGroup(
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
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Escribe tu correo.';
                    }
                    if (!esCorreoValido(v)) return 'Escribe un correo válido.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contrasena,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    suffixIcon: IconButton(
                      tooltip: _ocultar
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      icon: Icon(
                        _ocultar ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _ocultar = !_ocultar),
                    ),
                  ),
                  obscureText: _ocultar,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _entrar(),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Escribe tu contraseña.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          AvisoError(_error!),
          const SizedBox(height: 16),
        ],
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _enviando ? null : _entrar,
            child: _enviando
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Entrar'),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go(Rutas.primerAcceso),
          child: const Text('¿Primera vez? Crear mi contraseña'),
        ),
      ],
    );
  }
}
