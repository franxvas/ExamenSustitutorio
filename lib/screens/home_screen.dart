import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/tarea_model.dart';
import '../services/firestore_service.dart';
import 'add_edit_tarea.dart'; // Debes crear esta pantalla

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _db = FirestoreService();
  String _filterEstado = 'todos'; // 'todos', 'pendiente', 'hecha'
  String _filterPrioridad = 'todas'; // 'todas', 'alta', 'media', 'baja'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditTaskScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildDashboard(), // Resumen
          _buildFilters(),   // Filtros y Buscador
          Expanded(child: _buildTaskList()), // Lista
        ],
      ),
    );
  }

  // Widget de Resumen (Contadores)
  Widget _buildDashboard() {
    return StreamBuilder<List<Tarea>>(
      stream: _db.getTareas(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        var tareas = snapshot.data!;
        int total = tareas.length;
        int hechas = tareas.where((t) => t.estaCompletada).length;
        int pendientes = total - hechas;
        // Vencidas: Pendientes Y Fecha límite anterior a hoy
        int vencidas = tareas.where((t) => !t.estaCompletada && t.fechaLimite.isBefore(DateTime.now())).length;

        return Card(
          margin: const EdgeInsets.all(8),
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _counterItem("Total", total),
                _counterItem("Pend.", pendientes),
                _counterItem("Hechas", hechas),
                _counterItem("Vencidas", vencidas, color: Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _counterItem(String label, int count, {Color? color}) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // Widget de Filtros
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por título...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _filterEstado,
                  isExpanded: true,
                  items: ['todos', 'pendiente', 'hecha'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _filterEstado = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<String>(
                  value: _filterPrioridad,
                  isExpanded: true,
                  items: ['todas', 'alta', 'media', 'baja'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                  onChanged: (v) => setState(() => _filterPrioridad = v!),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Lista de Tareas Filtrada
  Widget _buildTaskList() {
    return StreamBuilder<List<Tarea>>(
      stream: _db.getTareas(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var tareas = snapshot.data!;

        // Aplicar Filtros en Cliente (Lógica requerida por examen)
        var tareasFiltradas = tareas.where((t) {
          // Filtro Estado
          if (_filterEstado == 'pendiente' && t.estaCompletada) return false;
          if (_filterEstado == 'hecha' && !t.estaCompletada) return false;
          
          // Filtro Prioridad
          if (_filterPrioridad != 'todas' && t.prioridad != _filterPrioridad) return false;

          // Filtro Búsqueda
          if (_searchQuery.isNotEmpty && !t.titulo.toLowerCase().contains(_searchQuery.toLowerCase())) return false;

          return true;
        }).toList();

        return ListView.builder(
          itemCount: tareasFiltradas.length,
          itemBuilder: (context, index) {
            final tarea = tareasFiltradas[index];
            return Card(
              color: tarea.estaCompletada ? Colors.green.shade50 : Colors.white,
              child: ListTile(
                leading: Checkbox(
                  value: tarea.estaCompletada,
                  onChanged: (val) => _db.toggleEstado(tarea.id!, tarea.estaCompletada),
                ),
                title: Text(tarea.titulo, style: TextStyle(decoration: tarea.estaCompletada ? TextDecoration.lineThrough : null)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Prioridad: ${tarea.prioridad} - ${DateFormat('dd/MM/yyyy').format(tarea.fechaLimite)}"),
                    Text(tarea.descripcion, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(tarea.id!),
                ),
                onTap: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditTaskScreen(tarea: tarea)));
                },
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Tarea"),
        content: const Text("¿Estás seguro?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () {
            _db.deleteTarea(id);
            Navigator.pop(context);
          }, child: const Text("Eliminar")),
        ],
      ),
    );
  }
}
