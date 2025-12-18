import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/tarea.dart';
import '../services/firestore_service.dart';
import 'add_edit_tarea_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Variables para filtros
  String _searchQuery = '';
  String _filtroEstado = 'Todos'; // Todos, Pendiente, Hecha
  String _filtroPrioridad = 'Todas'; // Todas, Alta, Media, Baja

  // Cerrar sesión
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (_) => const LoginScreen())
      );
    }
  }

  // Eliminar tarea con confirmación
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Tarea'),
        content: const Text('¿Estás seguro de eliminar esta tarea?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              _firestoreService.eliminarTarea(id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const LoginScreen();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app), onPressed: _logout)
        ],
      ),
      body: Column(
        children: [
          // SECCION 1: DASHBOARD / RESUMEN
          StreamBuilder<List<Tarea>>(
            stream: _firestoreService.obtenerTareas(user!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              
              final tareas = snapshot.data!;
              final total = tareas.length;
              final pendientes = tareas.where((t) => !t.completada).length;
              final hechas = tareas.where((t) => t.completada).length;
              final vencidas = tareas.where((t) => 
                  !t.completada && t.fechaLimite.isBefore(DateTime.now())).length;

              return Card(
                margin: const EdgeInsets.all(8),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _infoBadge('Total', total.toString(), Colors.blue),
                      _infoBadge('Pend.', pendientes.toString(), Colors.orange),
                      _infoBadge('Hechas', hechas.toString(), Colors.green),
                      _infoBadge('Vencidas', vencidas.toString(), Colors.red),
                    ],
                  ),
                ),
              );
            },
          ),

          // SECCION 2: FILTROS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por título...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10)
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        decoration: const InputDecoration(labelText: 'Estado', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                        items: ['Todos', 'Pendiente', 'Hecha'].map((e) => 
                          DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _filtroEstado = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroPrioridad,
                        decoration: const InputDecoration(labelText: 'Prioridad', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                        items: ['Todas', 'Alta', 'Media', 'Baja'].map((e) => 
                          DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _filtroPrioridad = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const Divider(),

          // SECCION 3: LISTA DE TAREAS
          Expanded(
            child: StreamBuilder<List<Tarea>>(
              stream: _firestoreService.obtenerTareas(user!.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text('Error al cargar'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var tareas = snapshot.data ?? [];

                // APLICAR FILTROS EN MEMORIA
                // 1. Búsqueda
                if (_searchQuery.isNotEmpty) {
                  tareas = tareas.where((t) => 
                    t.titulo.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }
                // 2. Estado
                if (_filtroEstado == 'Pendiente') {
                  tareas = tareas.where((t) => !t.completada).toList();
                } else if (_filtroEstado == 'Hecha') {
                  tareas = tareas.where((t) => t.completada).toList();
                }
                // 3. Prioridad
                if (_filtroPrioridad != 'Todas') {
                  tareas = tareas.where((t) => t.prioridad == _filtroPrioridad).toList();
                }

                if (tareas.isEmpty) {
                  return const Center(child: Text('No hay tareas que coincidan'));
                }

                return ListView.builder(
                  itemCount: tareas.length,
                  itemBuilder: (context, index) {
                    final tarea = tareas[index];
                    final esVencida = !tarea.completada && 
                        tarea.fechaLimite.isBefore(DateTime.now());

                    return Card(
                      color: esVencida ? Colors.red[50] : null,
                      child: ListTile(
                        leading: Checkbox(
                          value: tarea.completada,
                          onChanged: (bool? val) {
                            _firestoreService.cambiarEstadoTarea(tarea.id!, val!);
                          },
                        ),
                        title: Text(
                          tarea.titulo,
                          style: TextStyle(
                            decoration: tarea.completada 
                                ? TextDecoration.lineThrough 
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tarea.descripcion),
                            Text(
                              'Prioridad: ${tarea.prioridad} - Fecha: ${DateFormat('dd/MM/yyyy').format(tarea.fechaLimite)}',
                              style: TextStyle(
                                color: esVencida ? Colors.red : Colors.grey[700],
                                fontSize: 12
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => AddEditTareaScreen(tarea: tarea)
                                ));
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(tarea.id!),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const AddEditTareaScreen()
          ));
        },
      ),
    );
  }

  Widget _infoBadge(String label, String count, Color color) {
    return Column(
      children: [
        Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}