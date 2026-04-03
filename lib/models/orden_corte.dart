class OrdenCorte {
  final int? id;
  final String numeroOC;
  final String estilo;
  final int totalPiezas;
  final String semana;

  OrdenCorte({
    this.id,
    required this.numeroOC,
    required this.estilo,
    required this.totalPiezas,
    required this.semana,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero_oc': numeroOC,
      'estilo': estilo,
      'total_piezas': totalPiezas,
      'semana': semana,
    };
  }

  factory OrdenCorte.fromMap(Map<String, dynamic> map) {
    return OrdenCorte(
      id: map['id'],
      numeroOC: map['numero_oc'],
      estilo: map['estilo'],
      totalPiezas: map['total_piezas'],
      semana: map['semana'],
    );
  }
}
