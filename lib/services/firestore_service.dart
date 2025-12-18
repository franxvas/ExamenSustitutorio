import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tarea.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Referencia a la colección
  CollectionReference get _tareasCollection => _db.collection('tareas');

  // CREAR (Create)
  Future<void> agregarTarea(Tarea tarea) async {
    await _tareasCollection.add(tarea.toMap());
  }

  // LEER (Read) - Stream filtrado por UID del usuario actual
  Stream<List<Tarea>> obtenerTareas(String uid) {
    return _tareasCollection
        .where('uid', isEqualTo: uid)
        .orderBy('fechaLimite') // Opcional: ordenar por fecha
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Tarea.fromFirestore(doc)).toList());
  }

  // ACTUALIZAR (Update) - Editar datos o cambiar estado
  Future<void> actualizarTarea(Tarea tarea) async {
    await _tareasCollection.doc(tarea.id).update(tarea.toMap());
  }
  
  // Cambiar solo el estado (útil para el checkbox rápido)
  Future<void> cambiarEstadoTarea(String id, bool completada) async {
    await _tareasCollection.doc(id).update({'completada': completada});
  }

  // ELIMINAR (Delete)
  Future<void> eliminarTarea(String id) async {
    await _tareasCollection.doc(id).delete();
  }
}