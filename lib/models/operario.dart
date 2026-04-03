class Operario {
  final int? id;
  final String nombre;
  final String area;

  Operario({this.id, required this.nombre, this.area = 'ENSAMBLE'});

  Map<String, dynamic> toMap() {
    return {'id': id, 'nombre': nombre, 'area': area};
  }

  factory Operario.fromMap(Map<String, dynamic> map) {
    return Operario(
      id: map['id'],
      nombre: map['nombre'],
      area: map['area'] ?? 'ENSAMBLE',
    );
  }
}
