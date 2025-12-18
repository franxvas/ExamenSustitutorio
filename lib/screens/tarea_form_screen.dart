import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../models/tarea.dart';
import '../services/firestore_service.dart';

class AddEditTareaScreen extends StatefulWidget {
  final Tarea? tarea; // Si es null, estamos creando. Si no, editando.

  const AddEditTareaScreen({super.key, this.tarea});

  @override
  State<AddEditTareaScreen> createState() => _AddEditTareaScreenState();
}

class _AddEditTareaScreenState extends State<AddEditTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  
  String _prioridad = 'Media';
  DateTime _fechaLimite = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Si estamos editando, rellenar los campos
    if (widget.tarea != null) {
      _tituloController.text = widget.tarea!.titulo;
      _descripcionController.text = widget.tarea!.descripcion;
      _prioridad = widget.tarea!.prioridad;
      _fechaLimite = widget.tarea!.fechaLimite;
    }
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaLimite,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaLimite) {
      setState(() {
        _fechaLimite = picked;
      });
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      if (widget.tarea == null) {
        // CREAR
        final nuevaTarea = Tarea(
          uid: uid,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          prioridad: _prioridad,
          fechaLimite: _fechaLimite,
        );
        await _firestoreService.agregarTarea(nuevaTarea);
      } else {
        // EDITAR
        final tareaEditada = Tarea(
          id: widget.tarea!.id,
          uid: widget.tarea!.uid,
          titulo: _tituloController.text,
          descripcion: _descripcionController.text,
          prioridad: _prioridad,
          fechaLimite: _fechaLimite,
          completada: widget.tarea!.completada,
        );
        await _firestoreService.actualizarTarea(tareaEditada);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tarea == null ? 'Nueva Tarea' : 'Editar Tarea'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _prioridad,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: ['Alta', 'Media', 'Baja']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => setState(() => _prioridad = val!),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: Text('Fecha Límite: ${DateFormat('dd/MM/yyyy').format(_fechaLimite)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _seleccionarFecha,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _guardar,
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}