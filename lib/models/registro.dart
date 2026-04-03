class Registro {
  final int? id;
  final int operarioId;
  final int ordenCorteId;
  final String operacion;
  final String fecha;
  final String hora;
  final int piezas;

  Registro({
    this.id,
    required this.operarioId,
    required this.ordenCorteId,
    required this.operacion,
    required this.fecha,
    required this.hora,
    required this.piezas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operario_id': operarioId,
      'orden_corte_id': ordenCorteId,
      'operacion': operacion,
      'fecha': fecha,
      'hora': hora,
      'piezas': piezas,
    };
  }

  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'],
      operarioId: map['operario_id'],
      ordenCorteId: map['orden_corte_id'],
      operacion: map['operacion'],
      fecha: map['fecha'],
      hora: map['hora'],
      piezas: map['piezas'],
    );
  }
}
