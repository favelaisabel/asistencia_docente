import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Interfaz en español de México (RNF-012).
const idiomaApp = Locale('es', 'MX');

const idiomasSoportados = [Locale('es', 'MX'), Locale('es')];

const delegadosLocalizacion = <LocalizationsDelegate<Object>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
