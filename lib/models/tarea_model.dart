class Tarea {
  String? id;
  String titulo;
  String descripcion;
  String prioridad; // 'alta', 'media', 'baja'
  DateTime fechaLimite;
  bool estaCompletada;
  String uid; // Para seguridad por usuario

  Tarea({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    required this.fechaLimite,
    this.estaCompletada = false,
    required this.uid,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'fechaLimite': fechaLimite.toIso8601String(),
      'estaCompletada': estaCompletada,
      'uid': uid,
    };
  }

  // Crear objeto desde Firestore
  factory Tarea.fromMap(Map<String, dynamic> map, String id) {
    return Tarea(
      id: id,
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      prioridad: map['prioridad'] ?? 'media',
      fechaLimite: DateTime.parse(map['fechaLimite']),
      estaCompletada: map['estaCompletada'] ?? false,
      uid: map['uid'] ?? '',
    );
  }
}
