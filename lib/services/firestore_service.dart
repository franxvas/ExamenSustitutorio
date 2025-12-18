import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tarea_model.dart';

class FirestoreService {
  final CollectionReference _tareasRef = FirebaseFirestore.instance.collection('tareas');
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // Agregar
  Future<void> addTarea(Tarea tarea) async {
    if (_uid == null) return;
    await _tareasRef.add(tarea.toMap());
  }

  // Editar
  Future<void> updateTarea(String id, Tarea tarea) async {
    await _tareasRef.doc(id).update(tarea.toMap());
  }
  
  // Cambiar estado (Pendiente <-> Hecha)
  Future<void> toggleEstado(String id, bool actualState) async {
    await _tareasRef.doc(id).update({'estaCompletada': !actualState});
  }

  // Eliminar
  Future<void> deleteTarea(String id) async {
    await _tareasRef.doc(id).delete();
  }

  // Obtener Stream de tareas (Solo del usuario actual)
  Stream<List<Tarea>> getTareas() {
    if (_uid == null) return Stream.value([]);
    
    return _tareasRef
        .where('uid', isEqualTo: _uid) // Seguridad por UID
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tarea.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
