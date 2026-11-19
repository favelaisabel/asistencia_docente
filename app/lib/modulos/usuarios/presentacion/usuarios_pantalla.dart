import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/mensajes.dart';
import '../../../dominio/correo.dart';
import '../../../dominio/rol.dart';
import '../../../dominio/sesion.dart';
import '../../../dominio/usuario.dart';
import '../../autenticacion/aplicacion/providers.dart';
import '../../autenticacion/presentacion/componentes.dart';
import '../aplicacion/providers.dart';

/// Pestaña Usuarios de Coordinación (W-06, RF-004, flujo F9).
class UsuariosPantalla extends ConsumerWidget {
  const UsuariosPantalla({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        final ancho = restricciones.maxWidth >= 900;
        const listas = _Listas();
        const formulario = _FormularioPreregistro();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ancho
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: listas),
                        SizedBox(width: 24),
                        Expanded(flex: 2, child: formulario),
                      ],
                    )
                  : const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [formulario, SizedBox(height: 24), listas],
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _Listas extends ConsumerWidget {
  const _Listas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosProvider);
    final pendientes = ref.watch(preregistrosPendientesProvider);
    final sesion = ref.watch(sesionProvider).value;
    final miUid = sesion is ConPerfil ? sesion.usuario.uid : null;
    final estilo = Theme.of(context).textTheme.titleMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Usuarios', style: estilo),
        const SizedBox(height: 8),
        Card(
          child: usuarios.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: AvisoError(mensajeDeError(e)),
            ),
            data: (lista) => lista.isEmpty
                ? const ListTile(title: Text('Aún no hay usuarios.'))
                : Column(
                    children: [
                      for (final u in lista)
                        _FilaUsuario(usuario: u, esYo: u.uid == miUid),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Pre-registros pendientes', style: estilo),
        const SizedBox(height: 8),
        Card(
          child: pendientes.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: AvisoError(mensajeDeError(e)),
            ),
            data: (lista) => lista.isEmpty
                ? const ListTile(
                    title: Text('No hay pre-registros pendientes.'),
                  )
                : Column(
                    children: [for (final p in lista) _FilaPreregistro(p)],
                  ),
          ),
        ),
      ],
    );
  }
}

class _FilaUsuario extends ConsumerWidget {
  const _FilaUsuario({required this.usuario, required this.esYo});

  final Usuario usuario;
  final bool esYo;

  Future<void> _cambiar(
    BuildContext context,
    WidgetRef ref,
    bool activo,
  ) async {
    if (!activo) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desactivar usuario'),
          content: Text(
            '¿Desactivar a ${usuario.nombre}? No podrá entrar al sistema.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }
    try {
      await ref
          .read(usuarioRepositorioProvider)
          .cambiarActivo(uid: usuario.uid, activo: activo);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = usuario.activo ? 'Activo' : 'Desactivado';
    return ListTile(
      title: Text(usuario.nombre),
      subtitle: Text('${usuario.correo} · ${usuario.rol.nombre} · $estado'),
      trailing: Tooltip(
        message: esYo ? 'No puedes desactivar tu propia cuenta' : 'Activo',
        child: Switch(
          value: usuario.activo,
          onChanged: esYo ? null : (valor) => _cambiar(context, ref, valor),
        ),
      ),
    );
  }
}

class _FilaPreregistro extends ConsumerWidget {
  const _FilaPreregistro(this.preregistro);

  final Preregistro preregistro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(preregistro.nombre),
      subtitle: Text(
        '${preregistro.correo} · ${preregistro.rol.nombre} · Pendiente de primer acceso',
      ),
      trailing: TextButton(
        onPressed: () async {
          try {
            await ref
                .read(usuarioRepositorioProvider)
                .cancelarPreregistro(preregistro.correo);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
            }
          }
        },
        child: const Text('Cancelar'),
      ),
    );
  }
}

class _FormularioPreregistro extends ConsumerStatefulWidget {
  const _FormularioPreregistro();

  @override
  ConsumerState<_FormularioPreregistro> createState() =>
      _FormularioPreregistroState();
}

class _FormularioPreregistroState
    extends ConsumerState<_FormularioPreregistro> {
  final _formulario = GlobalKey<FormState>();
  final _correo = TextEditingController();
  final _nombre = TextEditingController();
  Rol _rol = Rol.encargado;
  bool _enviando = false;
  String? _error;
  String? _exito;

  /// MVP: encargado y Coordinación. Docentes en v1.1 (EP7).
  static const _rolesDisponibles = [Rol.encargado, Rol.coordinacion];

  @override
  void dispose() {
    _correo.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _preregistrar() async {
    if (!(_formulario.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _error = null;
      _exito = null;
    });
    try {
      await ref
          .read(usuarioRepositorioProvider)
          .preregistrar(correo: _correo.text, nombre: _nombre.text, rol: _rol);
      if (!mounted) return;
      setState(() {
        _exito =
            'Pre-registro creado. La persona debe entrar a «Primer acceso» con ese correo.';
        _correo.clear();
        _nombre.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pre-registrar usuario',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _correo,
                decoration: const InputDecoration(
                  labelText: 'Correo institucional',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Escribe el correo.';
                  }
                  if (!esCorreoValido(v)) return 'Escribe un correo válido.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                decoration: const InputDecoration(labelText: 'Nombre completo'),
                validator: (v) {
                  final texto = v?.trim() ?? '';
                  if (texto.length < 3) return 'Escribe el nombre completo.';
                  if (texto.length > 120) {
                    return 'El nombre admite hasta 120 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Rol>(
                initialValue: _rol,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: [
                  for (final rol in _rolesDisponibles)
                    DropdownMenuItem(value: rol, child: Text(rol.nombre)),
                ],
                onChanged: (rol) => setState(() => _rol = rol ?? _rol),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                AvisoError(_error!),
                const SizedBox(height: 12),
              ],
              if (_exito != null) ...[
                Semantics(liveRegion: true, child: Text(_exito!)),
                const SizedBox(height: 12),
              ],
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _enviando ? null : _preregistrar,
                  child: const Text('Pre-registrar'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'La persona crea su contraseña al entrar por primera vez y recibe este rol.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
