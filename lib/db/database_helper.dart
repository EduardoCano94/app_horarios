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

    // ── Operarios iniciales ──────────────────────────────
    final operariosIniciales = [
      {'nombre': 'ERICKA HILARIO', 'area': 'TERMINADO'},
      {'nombre': 'ESTHELA HERNANDEZ', 'area': 'TERMINADO'},
      {'nombre': 'JESUS GASPAR', 'area': 'TERMINADO'},
      {'nombre': 'MA. CARMEN BONILLA', 'area': 'TERMINADO'},
      {'nombre': 'ADRIANA MENDEZ MENDEZ', 'area': 'TERMINADO'},
      {'nombre': 'MAGALI TOMAS MARCOS', 'area': 'TERMINADO'},
      {'nombre': 'ALEJANDRO LUIS', 'area': 'TERMINADO'},
      {'nombre': 'JUAN PABLO OCHOA', 'area': 'TERMINADO'},
      {'nombre': 'ROSA ISELA PERDOMO', 'area': 'TERMINADO'},
      {'nombre': 'FIDELIA GUZMAN', 'area': 'TERMINADO'},
      {'nombre': 'OSCAR DEL ROQUE', 'area': 'ENSAMBLE'},
      {'nombre': 'JOSE LUIS AQUINO', 'area': 'ENSAMBLE'},
      {'nombre': 'HERMELINDA CIPRIANO', 'area': 'ENSAMBLE'},
      {'nombre': 'ANA LOZANO', 'area': 'ENSAMBLE'},
      {'nombre': 'ANUBIS CORDOVA', 'area': 'ENSAMBLE'},
      {'nombre': 'MANUEL REYES HDEZ.', 'area': 'ENSAMBLE'},
      {'nombre': 'MONSERRAT DEL ROQUE ALBINO', 'area': 'ENSAMBLE'},
      {'nombre': 'ELEAZAR BARRIENTOS BAUTISTA', 'area': 'ENSAMBLE'},
      {'nombre': 'CARLOS ALBERTO JAIMES', 'area': 'ENSAMBLE'},
      {'nombre': 'FABIOLA MARTIN', 'area': 'ENSAMBLE'},
      {'nombre': 'ERASMO MORALES', 'area': 'ENSAMBLE'},
      {'nombre': 'OSCAR SIMON BALTASAR', 'area': 'ENSAMBLE'},
      {'nombre': 'ROBERTO PEREZ', 'area': 'ENSAMBLE'},
      {'nombre': 'KARLA SANTIAGO', 'area': 'ENSAMBLE'},
      {'nombre': 'VICENTE MARCOS', 'area': 'ENSAMBLE'},
      {'nombre': 'ALEJANDRO MARTINEZ', 'area': 'ENSAMBLE'},
      {'nombre': 'JESSICA PERDOMO', 'area': 'ENSAMBLE'},
      {'nombre': 'ANGELA SANTOS', 'area': 'ENSAMBLE'},
      {'nombre': 'TERESA PRESA', 'area': 'ENSAMBLE'},
      {'nombre': 'BLANCA ESTHELA', 'area': 'ENSAMBLE'},
      {'nombre': 'MAURICIO OCHOA', 'area': 'ENSAMBLE'},
      {'nombre': 'PERLA MORALES', 'area': 'ENSAMBLE'},
      {'nombre': 'ZENON CASIANO', 'area': 'ENSAMBLE'},
      {'nombre': 'FLORENCIO ANDRES', 'area': 'ENSAMBLE'},
      {'nombre': 'MANUEL REYES JR.', 'area': 'ENSAMBLE'},
      {'nombre': 'LILI GUZMAN BANDALA', 'area': 'ENSAMBLE'},
      {'nombre': 'SOFIA GASPAR', 'area': 'ENSAMBLE'},
      {'nombre': 'JHONATAN HERNADEZ', 'area': 'ENSAMBLE'},
      {'nombre': 'AMBROSIO TADEO', 'area': 'ENSAMBLE'},
      {'nombre': 'MONSERRAT BALTAZAR', 'area': 'DELANTERO'},
      {'nombre': 'LUIS ANTONIO CORDOVA', 'area': 'DELANTERO'},
      {'nombre': 'YONATHAN DE LA CRUZ', 'area': 'DELANTERO'},
      {'nombre': 'GUADALUPE PERDOMO', 'area': 'DELANTERO'},
      {'nombre': 'JORGE LUIS GUTIERREZ', 'area': 'DELANTERO'},
      {'nombre': 'CARMINA CANO', 'area': 'DELANTERO'},
      {'nombre': 'GLORIA GAMINO', 'area': 'DELANTERO'},
      {'nombre': 'RICARDO SIMON', 'area': 'DELANTERO'},
      {'nombre': 'ISABEL GONZALES', 'area': 'DELANTERO'},
      {'nombre': 'MIRIAM GAMINO GONZALEZ', 'area': 'DELANTERO'},
      {'nombre': 'ANDRES COSME', 'area': 'DELANTERO'},
      {'nombre': 'DANIELA SIMON LOPEZ', 'area': 'DELANTERO'},
      {'nombre': 'EMILIO LEAL', 'area': 'DELANTERO'},
      {'nombre': 'MICAELA MAURICIO', 'area': 'DELANTERO'},
      {'nombre': 'NANCI COSME', 'area': 'DELANTERO'},
      {'nombre': 'ITZEL VASQUEZ', 'area': 'DELANTERO'},
      {'nombre': 'PATRICIA ROSAS', 'area': 'DELANTERO'},
      {'nombre': 'ALIZBETH CANO', 'area': 'DELANTERO'},
      {'nombre': 'ARACELY PEREZ', 'area': 'DELANTERO'},
      {'nombre': 'ANDRES ANTONIO', 'area': 'DELANTERO'},
      {'nombre': 'BRENDA IVET HERRERA', 'area': 'DELANTERO'},
      {'nombre': 'ARTURO LOPEZ', 'area': 'DELANTERO'},
      {'nombre': 'LETICIA HERNADEZ', 'area': 'DELANTERO'},
      {'nombre': 'ANTONIA GAMINO', 'area': 'DELANTERO'},
      {'nombre': 'JUAN CARLOS ESPINOZA', 'area': 'DELANTERO'},
      {'nombre': 'RAMIRO SIMON BALTAZAR', 'area': 'DELANTERO'},
      {'nombre': 'VERONICA MORALES', 'area': 'DELANTERO'},
      {'nombre': 'JULIETA MAURICIO', 'area': 'TRASERO'},
      {'nombre': 'JUAN BALTAZAR', 'area': 'TRASERO'},
      {'nombre': 'MARIA DEL ROCIO SANTOS', 'area': 'TRASERO'},
      {'nombre': 'FLORIBERTO MURRIETA', 'area': 'TRASERO'},
      {'nombre': 'LUIS BRUNO', 'area': 'TRASERO'},
      {'nombre': 'ENRIQUE HILARIO', 'area': 'TRASERO'},
      {'nombre': 'BERNARDINO CHINO', 'area': 'TRASERO'},
      {'nombre': 'GABRIELA HERNANDEZ', 'area': 'TRASERO'},
      {'nombre': 'ESMERALDA DOROTEO', 'area': 'TRASERO'},
      {'nombre': 'ROSALBA MEJAREJO', 'area': 'TRASERO'},
      {'nombre': 'CESAR GAMINO', 'area': 'TRASERO'},
      {'nombre': 'VICENTE SIMON', 'area': 'TRASERO'},
      {'nombre': 'LILIBETH TADEO', 'area': 'TRASERO'},
      {'nombre': 'EMMANUEL GUZMAN', 'area': 'TRASERO'},
      {'nombre': 'YENEVITH MAYUVI', 'area': 'TRASERO'},
      {'nombre': 'GRACIELA AMARO', 'area': 'TRASERO'},
      {'nombre': 'JUAN MARTINEZ', 'area': 'TRASERO'},
      {'nombre': 'GENARO MARQUEZ', 'area': 'TRASERO'},
      {'nombre': 'JOSELIN MAURICIO', 'area': 'TRASERO'},
      {'nombre': 'CLEOTILDE GAMINO', 'area': 'TRASERO'},
      {'nombre': 'MA. LUCIA COSME ALFONSO', 'area': 'TRASERO'},
      {'nombre': 'GUADALUPE VIDAL', 'area': 'TRASERO'},
      {'nombre': 'MARITZA MARCOS AMARO', 'area': 'TRASERO'},
      {'nombre': 'ANGEL YAHIR HDEZ', 'area': 'TRASERO'},
      {'nombre': 'RUFINO CONTRERAS', 'area': 'PARTES CHICAS'},
      {'nombre': 'NABOR PEREZ', 'area': 'PARTES CHICAS'},
      {'nombre': 'VERONICA GUZMAN', 'area': 'PARTES CHICAS'},
      {'nombre': 'ARMANDO SANTIAGO', 'area': 'PARTES CHICAS'},
      {'nombre': 'PAOLA MELGAREJO', 'area': 'PARTES CHICAS'},
      {'nombre': 'PETRA CONTRERAS', 'area': 'PARTES CHICAS'},
      {'nombre': 'VICENTE DOROTEO', 'area': 'PARTES CHICAS'},
      {'nombre': 'DYLAN MURRIETA JUAREZ', 'area': 'PARTES CHICAS'},
      {'nombre': 'OSCAR RODRIGO CIPRIANO', 'area': 'PARTES CHICAS'},
      {'nombre': 'YAMILET ROSAS TADEO', 'area': 'PARTES CHICAS'},
      {'nombre': 'MARCO SERRANO', 'area': 'PARTES CHICAS'},
      {'nombre': 'GLADIS TETELANO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'OLGA LIDIA ESPINOZA', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'CRISTIAN J. CIPRIANO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'ALEJANDRO DE LA CRUZ', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'ESMERALDA SANTOS', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'ANDREA GUZMAN', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'LORENA GUADALUPE ALBERTO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'DULCE YANERI ANTONIO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'SALVADOR COLIO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'JOSE JUAREZ ESPINOZA', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'JUANA MENDEZ', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'MARITZA MARCOS AMARO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'MARISOL MARCOS LAZARO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'LETICIA HERNANDEZ', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'ROSA MAURICIO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'VIRIDIANA CAMACHO', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'ANTONIA DOMINGUEZ', 'area': 'JOGGER QUIRURGICO'},
      {'nombre': 'KARLA HERNANDEZ', 'area': 'CHAMARRA'},
      {'nombre': 'VICTOR REYES ATANACIO', 'area': 'CHAMARRA'},
      {'nombre': 'TIMOTEO ZAVALETA', 'area': 'CHAMARRA'},
      {'nombre': 'ERICK ZAVALETA', 'area': 'CHAMARRA'},
      {'nombre': 'JORGE CHINO', 'area': 'CHAMARRA'},
      {'nombre': 'VICTOR MANUEL TADEO', 'area': 'CHAMARRA'},
      {'nombre': 'DOMINGA ATANACIO', 'area': 'CHAMARRA'},
      {'nombre': 'JULI CIPRIANO', 'area': 'CHAMARRA'},
      {'nombre': 'ANAYELI CIPRIANO', 'area': 'CHAMARRA'},
      {'nombre': 'LAURA HERNANDEZ', 'area': 'CHAMARRA'},
      {'nombre': 'BRAYAN MARTINEZ', 'area': 'CHAMARRA'},
      {'nombre': 'JUAN DANIEL TADEO LUNA', 'area': 'CHAMARRA'},
      {'nombre': 'DULCE JOCELYN CIPRIANO', 'area': 'CHAMARRA'},
    ];

    for (final op in operariosIniciales) {
      await db.insert('operarios', op);
    }

    // ── Órdenes de corte iniciales ───────────────────────
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

    for (final orden in ordenesIniciales) {
      await db.insert('ordenes_corte', orden);
    }

    // ── Usuarios iniciales ───────────────────────────────
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

    for (final u in usuariosIniciales) {
      await db.insert('usuarios', u);
    }
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
