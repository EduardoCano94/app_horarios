import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/operario.dart';
import '../models/orden_corte.dart';
import '../models/registro.dart';
import '../models/usuario.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('horario_produccion.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE operarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        area TEXT NOT NULL DEFAULT 'ENSAMBLE'
      )
    ''');

    await db.execute('''
      CREATE TABLE ordenes_corte (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        numero_oc TEXT NOT NULL,
        estilo TEXT NOT NULL,
        total_piezas INTEGER NOT NULL,
        semana TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE registros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operario_id INTEGER NOT NULL,
        orden_corte_id INTEGER NOT NULL,
        operacion TEXT NOT NULL,
        fecha TEXT NOT NULL,
        hora TEXT NOT NULL,
        piezas INTEGER NOT NULL,
        FOREIGN KEY (operario_id) REFERENCES operarios(id),
        FOREIGN KEY (orden_corte_id) REFERENCES ordenes_corte(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        rol TEXT NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');
    final operariosIniciales = [
      // DELANTERO
      {'nombre': 'EMILIO', 'area': 'DELANTERO'},
      {'nombre': 'ANDRÉS ANTONIO', 'area': 'DELANTERO'},
      {'nombre': 'ALEXANDRA', 'area': 'DELANTERO'},
      {'nombre': 'ARACELY', 'area': 'DELANTERO'},
      {'nombre': 'NANCY', 'area': 'DELANTERO'},
      {'nombre': 'VICENTE', 'area': 'DELANTERO'},
      {'nombre': 'PATRICIA', 'area': 'DELANTERO'},
      {'nombre': 'ANTONIO', 'area': 'DELANTERO'},
      {'nombre': 'JONATHAN', 'area': 'DELANTERO'},
      {'nombre': 'MARGARITA', 'area': 'DELANTERO'},
      {'nombre': 'DANIELA', 'area': 'DELANTERO'},
      {'nombre': 'ANDRÉS', 'area': 'DELANTERO'},
      {'nombre': 'ARTURO', 'area': 'DELANTERO'},
      {'nombre': 'RICARDO', 'area': 'DELANTERO'},
      {'nombre': 'MONSERRAT', 'area': 'DELANTERO'},
      {'nombre': 'MICAELA', 'area': 'DELANTERO'},
      {'nombre': 'ALIZBETH', 'area': 'DELANTERO'},
      {'nombre': 'ITZEL', 'area': 'DELANTERO'},
      {'nombre': 'JORGE GUTIÉRREZ', 'area': 'DELANTERO'},
      {'nombre': 'LUIS ANTONIO', 'area': 'DELANTERO'},
      {'nombre': 'LETY', 'area': 'DELANTERO'},
      {'nombre': 'VANESSA', 'area': 'DELANTERO'},
      {'nombre': 'CARMINA', 'area': 'DELANTERO'},
      {'nombre': 'ÁNGEL', 'area': 'DELANTERO'},
      // ENSAMBLE
      {'nombre': 'FLORENCIO', 'area': 'ENSAMBLE'},
      {'nombre': 'OSCAR DEL ROQUE', 'area': 'ENSAMBLE'},
      {'nombre': 'JOSE LUIS AQUINO', 'area': 'ENSAMBLE'},
      {'nombre': 'JONATHAN', 'area': 'ENSAMBLE'},
      {'nombre': 'ZENON', 'area': 'ENSAMBLE'},
      {'nombre': 'MANUEL REYES', 'area': 'ENSAMBLE'},
      {'nombre': 'MONSERRAT DEL ROQUE', 'area': 'ENSAMBLE'},
      {'nombre': 'OLGA', 'area': 'ENSAMBLE'},
      {'nombre': 'CARLOS ALBERTO', 'area': 'ENSAMBLE'},
      {'nombre': 'TIMOTEO', 'area': 'ENSAMBLE'},
      {'nombre': 'DANIEL', 'area': 'ENSAMBLE'},
      {'nombre': 'ELEAZAR', 'area': 'ENSAMBLE'},
      {'nombre': 'ERASMO', 'area': 'ENSAMBLE'},
      {'nombre': 'VICTOR', 'area': 'ENSAMBLE'},
      {'nombre': 'VICENTE', 'area': 'ENSAMBLE'},
      {'nombre': 'FABIOLA MARTIN', 'area': 'ENSAMBLE'},
      {'nombre': 'JACQUELINE', 'area': 'ENSAMBLE'},
      {'nombre': 'AMBROSIO', 'area': 'ENSAMBLE'},
      {'nombre': 'ANNA LOZANO', 'area': 'ENSAMBLE'},
      {'nombre': 'OSCAR', 'area': 'ENSAMBLE'},
      {'nombre': 'ALEJANDRO', 'area': 'ENSAMBLE'},
      {'nombre': 'JESSICA', 'area': 'ENSAMBLE'},
    ];

    final ordenesIniciales = [
      {
        'numero_oc': '260261',
        'estilo': 'OGGI',
        'total_piezas': 828,
        'semana': '18-24 MARZO',
      },
      {
        'numero_oc': '260295',
        'estilo': 'OGGI',
        'total_piezas': 629,
        'semana': '18-24 MARZO',
      },
      {
        'numero_oc': '260247',
        'estilo': 'OGGI',
        'total_piezas': 1532,
        'semana': '18-24 MARZO',
      },
      {
        'numero_oc': '260294',
        'estilo': 'FRAME',
        'total_piezas': 1899,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260290',
        'estilo': 'FRAME',
        'total_piezas': 736,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260292',
        'estilo': 'FRAME',
        'total_piezas': 632,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260286',
        'estilo': 'FRAME',
        'total_piezas': 1420,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260259',
        'estilo': 'OGGI',
        'total_piezas': 789,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260260',
        'estilo': 'OGGI',
        'total_piezas': 596,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260332',
        'estilo': 'OGGI',
        'total_piezas': 1063,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260296',
        'estilo': 'OGGI',
        'total_piezas': 1461,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260297',
        'estilo': 'OGGI',
        'total_piezas': 844,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260298',
        'estilo': 'OGGI',
        'total_piezas': 848,
        'semana': '25-31 MARZO',
      },
      {
        'numero_oc': '260311',
        'estilo': 'OGGI',
        'total_piezas': 954,
        'semana': '25-31 MARZO',
      },
    ];

    final usuariosIniciales = [
      {
        'nombre': 'Dueño',
        'rol': 'DUEÑO',
        'password_hash': _hashPassword('dueno123'),
      },
      {
        'nombre': 'Gerente',
        'rol': 'GERENTE',
        'password_hash': _hashPassword('gerente123'),
      },
      {
        'nombre': 'Encargado',
        'rol': 'ENCARGADO',
        'password_hash': _hashPassword('encargado123'),
      },
    ];

    // ── Inserción en batch (mucho más rápido) ────────────
    await db.transaction((txn) async {
      for (final op in operariosIniciales) {
        await txn.insert('operarios', op);
      }
    });

    await db.transaction((txn) async {
      for (final orden in ordenesIniciales) {
        await txn.insert('ordenes_corte', orden);
      }
    });

    await db.transaction((txn) async {
      for (final u in usuariosIniciales) {
        await txn.insert('usuarios', u);
      }
    });
  }

  // ── USUARIOS ───────────────────────────────────────────
  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<Usuario?> login(String password) async {
    final db = await database;
    final hash = _hashPassword(password);
    final maps = await db.query(
      'usuarios',
      where: 'password_hash = ?',
      whereArgs: [hash],
    );
    if (maps.isEmpty) return null;
    return Usuario.fromMap(maps.first);
  }

  Future<int> cambiarPassword(int id, String nuevaPassword) async {
    final db = await database;
    return await db.update(
      'usuarios',
      {'password_hash': _hashPassword(nuevaPassword)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Usuario>> obtenerUsuarios() async {
    final db = await database;
    final maps = await db.query('usuarios');
    return maps.map((m) => Usuario.fromMap(m)).toList();
  }

  // ── OPERARIOS ──────────────────────────────────────────
  Future<int> insertarOperario(Operario operario) async {
    final db = await database;
    return await db.insert('operarios', operario.toMap());
  }

  Future<List<Operario>> obtenerOperarios() async {
    final db = await database;
    final maps = await db.query('operarios', orderBy: 'area ASC, nombre ASC');
    return maps.map((m) => Operario.fromMap(m)).toList();
  }

  Future<int> actualizarOperario(Operario operario) async {
    final db = await database;
    return await db.update(
      'operarios',
      operario.toMap(),
      where: 'id = ?',
      whereArgs: [operario.id],
    );
  }

  Future<int> eliminarOperario(int id) async {
    final db = await database;
    return await db.delete('operarios', where: 'id = ?', whereArgs: [id]);
  }

  // ── ÓRDENES DE CORTE ───────────────────────────────────
  Future<int> insertarOrden(OrdenCorte orden) async {
    final db = await database;
    return await db.insert('ordenes_corte', orden.toMap());
  }

  Future<List<OrdenCorte>> obtenerOrdenes() async {
    final db = await database;
    final maps = await db.query('ordenes_corte', orderBy: 'numero_oc ASC');
    return maps.map((m) => OrdenCorte.fromMap(m)).toList();
  }

  Future<int> eliminarOrden(int id) async {
    final db = await database;
    return await db.delete('ordenes_corte', where: 'id = ?', whereArgs: [id]);
  }

  // ── REGISTROS ──────────────────────────────────────────
  Future<int> insertarRegistro(Registro registro) async {
    final db = await database;
    return await db.insert('registros', registro.toMap());
  }

  Future<List<Registro>> obtenerRegistros() async {
    final db = await database;
    final maps = await db.query('registros', orderBy: 'fecha DESC, hora ASC');
    return maps.map((m) => Registro.fromMap(m)).toList();
  }

  Future<int> piezasCapturadas(int ordenCorteId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(piezas) as total FROM registros WHERE orden_corte_id = ?',
      [ordenCorteId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> piezasCapturadasPorOperacion(
    int ordenCorteId,
    String operacion,
  ) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(piezas) as total FROM registros WHERE orden_corte_id = ? AND operacion = ?',
      [ordenCorteId, operacion],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<int> eliminarRegistro(int id) async {
    final db = await database;
    return await db.delete('registros', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await database;
    db.close();
  }

  Future<int> insertarUsuario(Usuario usuario, String password) async {
    final db = await database;
    return await db.insert('usuarios', {
      'nombre': usuario.nombre,
      'rol': usuario.rol,
      'password_hash': _hashPassword(password),
    });
  }

  Future<int> eliminarUsuario(int id) async {
    final db = await database;
    return await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }
}
