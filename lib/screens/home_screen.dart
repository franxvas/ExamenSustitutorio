import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO EXAMEN:
    // - obtener uid del usuario
    // - mostrar lista de tareas (StreamBuilder)
    // - botón para agregar tarea
    // - cerrar sesión
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Tareas')),
      body: Container(),
    );
  }
}
