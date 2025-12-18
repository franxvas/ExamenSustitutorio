import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/tarea_model.dart';
import '../services/firestore_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Tarea? tarea;
  const AddEditTaskScreen({super.key, this.tarea});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _prioridad = 'media';
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 1));

  @override
  void initState() {
    super.initState();
    if (widget.tarea != null) {
      _tituloCtrl.text = widget.tarea!.titulo;
      _descCtrl.text = widget.tarea!.descripcion;
      _prioridad = widget.tarea!.prioridad;
      _fechaLimite = widget.tarea!.fechaLimite;
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final nuevaTarea = Tarea(
        titulo: _tituloCtrl.text,
        descripcion: _descCtrl.text,
        prioridad: _prioridad,
        fechaLimite: _fechaLimite,
        uid: user.uid,
        estaCompletada: widget.tarea?.estaCompletada ?? false,
      );

      if (widget.tarea == null) {
        await FirestoreService().addTarea(nuevaTarea);
      } else {
        await FirestoreService().updateTarea(widget.tarea!.id!, nuevaTarea);
      }
      
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tarea == null ? "Nueva Tarea" : "Editar Tarea")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: "Título"),
                validator: (v) => v!.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: "Descripción"),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _prioridad,
                items: ['alta', 'media', 'baja'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _prioridad = v!),
                decoration: const InputDecoration(labelText: "Prioridad"),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text("Fecha Límite: ${DateFormat('dd/MM/yyyy').format(_fechaLimite)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _fechaLimite,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _fechaLimite = picked);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text("Guardar Tarea")),
            ],
          ),
        ),
      ),
    );
  }
}
