import 'package:cloud_firestore/cloud_firestore.dart';

class Tarea {
  String? id;
  String uid; // ID del usuario dueño de la tarea
  String titulo;
  String descripcion;
  String prioridad; // 'Alta', 'Media', 'Baja'
  DateTime fechaLimite;
  bool completada;

  Tarea({
    this.id,
    required this.uid,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    required this.fechaLimite,
    this.completada = false,
  });

  // Convertir de Documento Firestore a Objeto
  factory Tarea.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tarea(
      id: doc.id,
      uid: data['uid'] ?? '',
      titulo: data['titulo'] ?? '',
      descripcion: data['descripcion'] ?? '',
      prioridad: data['prioridad'] ?? 'Media',
      fechaLimite: (data['fechaLimite'] as Timestamp).toDate(),
      completada: data['completada'] ?? false,
    );
  }

  // Convertir de Objeto a Mapa para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'fechaLimite': Timestamp.fromDate(fechaLimite),
      'completada': completada,
    };
  }
}