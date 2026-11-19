import 'package:asistencia_docente/dominio/rol.dart';
import 'package:asistencia_docente/dominio/sesion.dart';
import 'package:asistencia_docente/dominio/usuario.dart';
import 'package:asistencia_docente/modulos/autenticacion/aplicacion/destino.dart';
import 'package:flutter_test/flutter_test.dart';

ConPerfil conRol(Rol rol) => ConPerfil(
  Usuario(
    uid: 'u',
    correo: 'x@demo.edu.mx',
    nombre: 'X',
    rol: rol,
    activo: true,
  ),
);

void main() {
  group('PU-23 navegación por rol', () {
    test('sin sesión manda a Entrar, pero permite Primer acceso', () {
      expect(
        redirigir(
          sesion: const SinSesion(),
          ubicacion: '/recorrido',
          plataforma: Plataforma.movil,
        ),
        Rutas.entrar,
      );
      expect(
        redirigir(
          sesion: const SinSesion(),
          ubicacion: Rutas.primerAcceso,
          plataforma: Plataforma.movil,
        ),
        isNull,
      );
    });

    test('mientras carga la sesión se muestra Cargando', () {
      expect(
        redirigir(sesion: null, ubicacion: '/', plataforma: Plataforma.web),
        Rutas.cargando,
      );
    });

    test('correo sin confirmar o sin perfil manda a Primer acceso', () {
      expect(
        redirigir(
          sesion: const PendienteVerificacion('a@b.mx'),
          ubicacion: '/entrar',
          plataforma: Plataforma.web,
        ),
        Rutas.primerAcceso,
      );
      expect(
        redirigir(
          sesion: const SinPerfil('a@b.mx'),
          ubicacion: '/entrar',
          plataforma: Plataforma.web,
        ),
        Rutas.primerAcceso,
      );
    });

    test('cuenta desactivada manda a No disponible', () {
      expect(
        redirigir(
          sesion: const SesionDesactivada(),
          ubicacion: '/coordinacion',
          plataforma: Plataforma.web,
        ),
        Rutas.noDisponible,
      );
    });

    test('el encargado en la app va al recorrido', () {
      expect(
        redirigir(
          sesion: conRol(Rol.encargado),
          ubicacion: '/entrar',
          plataforma: Plataforma.movil,
        ),
        Rutas.recorrido,
      );
    });

    test(
      'Coordinación en la web va a su panel y puede navegar dentro de él',
      () {
        expect(
          redirigir(
            sesion: conRol(Rol.coordinacion),
            ubicacion: '/entrar',
            plataforma: Plataforma.web,
          ),
          Rutas.coordinacion,
        );
        expect(
          redirigir(
            sesion: conRol(Rol.coordinacion),
            ubicacion: '/coordinacion',
            plataforma: Plataforma.web,
          ),
          isNull,
        );
      },
    );

    test(
      'un rol en la plataforma que no le corresponde va a No disponible',
      () {
        expect(
          redirigir(
            sesion: conRol(Rol.coordinacion),
            ubicacion: '/entrar',
            plataforma: Plataforma.movil,
          ),
          Rutas.noDisponible,
        );
        expect(
          redirigir(
            sesion: conRol(Rol.encargado),
            ubicacion: '/entrar',
            plataforma: Plataforma.web,
          ),
          Rutas.noDisponible,
        );
      },
    );
  });
}
