class Usuario {
  final int? id;
  final String nombre;
  final String rol;
  final String passwordHash;

  Usuario({
    this.id,
    required this.nombre,
    required this.rol,
    required this.passwordHash,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'rol': rol,
    'password_hash': passwordHash,
  };

  factory Usuario.fromMap(Map<String, dynamic> map) => Usuario(
    id: map['id'],
    nombre: map['nombre'],
    rol: map['rol'],
    passwordHash: map['password_hash'],
  );
}
