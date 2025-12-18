import 'package:flutter/material.dart';

class TareaCard extends StatelessWidget {
  const TareaCard({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO EXAMEN:
    // - mostrar título
    // - estado pendiente/hecho
    // - botón editar
    // - botón eliminar
    return Card(
      child: ListTile(
        title: Text('Tarea'),
      ),
    );
  }
}
