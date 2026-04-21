import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/operario.dart';
import '../models/orden_corte.dart';
import '../models/registro.dart';

class CapturaScreen extends StatefulWidget {
  const CapturaScreen({super.key});

  @override
  State<CapturaScreen> createState() => _CapturaScreenState();
}

class _CapturaScreenState extends State<CapturaScreen> {
  final List<Map<String, dynamic>> _horario = [
    {'hora': '9:30', 'inicio': 9, 'minInicio': 0, 'fin': 10, 'minFin': 30},
    {'hora': '10:30', 'inicio': 10, 'minInicio': 30, 'fin': 11, 'minFin': 30},
    {'hora': '11:30', 'inicio': 11, 'minInicio': 30, 'fin': 12, 'minFin': 30},
    {'hora': '12:30', 'inicio': 12, 'minInicio': 30, 'fin': 14, 'minFin': 0},
    {'hora': '2:30', 'inicio': 14, 'minInicio': 0, 'fin': 15, 'minFin': 30},
    {'hora': '3:30', 'inicio': 15, 'minInicio': 30, 'fin': 16, 'minFin': 30},
    {'hora': '4:30', 'inicio': 16, 'minInicio': 30, 'fin': 17, 'minFin': 30},
    {'hora': '5:30', 'inicio': 17, 'minInicio': 30, 'fin': 18, 'minFin': 30},
    {'hora': '6:30', 'inicio': 18, 'minInicio': 30, 'fin': 19, 'minFin': 30},
  ];

  final Map<String, List<String>> _operacionesPorArea = {
    'DELANTERO': [
      'PEGAR OJALERA',
      'PEGAR BOTONERA',
      'S/C OJALERA',
      'S/COSER OJALERA',
      'S/C BOTONERA',
      'PEGAR FORRO',
      'DISEÑO J',
      'ENTRADA DE BOLSA',
      'S/COSER FORRO NORMAL',
      'APUNTAR BOLSA',
      'ENGRAPAR',
      'ENCUARTAR NORMAL',
      'PEGAR ETIQUETA (2) MONARCH',
      'PRESILLAR SECRETA',
      'PEGAR ETQ. MONACH',
      'PARES',
      'DESHEBRAR DEL',
    ],
    'ENSAMBLE': [
      'CERRAR ENTREPIERNA',
      'CERRAR COSTADOS',
      'S/C ENTREPIERNA',
      'MARCAR COSTADOS',
      'S/C COSTADOS',
      'VALENCIANA 1/2", 3/8", 5/8"',
      '2DA DE PRETINA',
      'HABILITAR PRETINA',
      'PEGAR PRETINA NORMAL 2 AGUJAS',
      'HACER CUADRO',
      'PRECILLAR COSTADOS',
      'PEGAR TRABA',
      'PEGAR TRABA (5)',
      'OJAL',
      'HACER VALENCIANA',
    ],
  };

  final Map<String, String> _operacionDefault = {
    'EMILIO': 'PEGAR OJALERA',
    'ANDRÉS ANTONIO': 'PEGAR BOTONERA',
    'ALEXANDRA': 'S/C OJALERA',
    'ARACELY': 'S/COSER OJALERA',
    'NANCY': 'S/COSER FORRO NORMAL',
    'VICENTE': 'PEGAR BOTONERA',
    'PATRICIA': 'S/C BOTONERA',
    'ANTONIO': 'PEGAR FORRO',
    'JONATHAN': 'DISEÑO J',
    'MARGARITA': 'PEGAR FORRO',
    'DANIELA': 'PEGAR FORRO',
    'ANDRÉS': 'ENTRADA DE BOLSA',
    'ARTURO': 'ENTRADA DE BOLSA',
    'RICARDO': 'S/COSER FORRO NORMAL',
    'MONSERRAT': 'S/COSER FORRO NORMAL',
    'MICAELA': 'APUNTAR BOLSA',
    'ALIZBETH': 'S/COSER FORRO NORMAL',
    'ITZEL': 'APUNTAR BOLSA',
    'JORGE GUTIÉRREZ': 'ENGRAPAR',
    'LUIS ANTONIO': 'ENCUARTAR NORMAL',
    'LETY': 'PEGAR ETIQUETA (2) MONARCH',
    'VANESSA': 'PRESILLAR SECRETA',
    'CARMINA': 'PEGAR ETQ. MONACH',
    'ÁNGEL': 'PARES',
    'FLORENCIO': 'CERRAR ENTREPIERNA',
    'OSCAR DEL ROQUE': 'CERRAR ENTREPIERNA',
    'JOSE LUIS AQUINO': 'S/C ENTREPIERNA',
    'JONATHAN (ENS)': 'CERRAR COSTADOS',
    'ZENON': 'CERRAR COSTADOS',
    'MANUEL REYES': 'MARCAR COSTADOS',
    'MONSERRAT DEL ROQUE': 'S/C COSTADOS',
    'OLGA': 'S/C COSTADOS',
    'CARLOS ALBERTO': 'VALENCIANA 1/2", 3/8", 5/8"',
    'TIMOTEO': '2DA DE PRETINA',
    'DANIEL': 'HABILITAR PRETINA',
    'ELEAZAR': 'HABILITAR PRETINA',
    'ERASMO': 'PEGAR PRETINA NORMAL 2 AGUJAS',
    'VICTOR': 'PEGAR PRETINA NORMAL 2 AGUJAS',
    'VICENTE (ENS)': 'HACER CUADRO',
    'FABIOLA MARTIN': 'PRECILLAR COSTADOS',
    'JACQUELINE': 'PRECILLAR COSTADOS',
    'AMBROSIO': 'PEGAR TRABA',
    'ANNA LOZANO': 'PEGAR TRABA (5)',
    'OSCAR': 'PEGAR TRABA (5)',
    'ALEJANDRO': 'OJAL',
    'JESSICA': 'HACER VALENCIANA',
  };

  List<Operario> _operarios = [];
  List<OrdenCorte> _ordenes = [];
  List<String> _operacionesExtra = [];
  Operario? _operarioSeleccionado;
  OrdenCorte? _ordenSeleccionada;
  String? _operacionSeleccionada;
  String _fechaHoy = '';
  int _horaActualIndex = 0;
  final _piezasCtrl = TextEditingController();
  bool _guardando = false;

  String get _horaActual => _horario[_horaActualIndex]['hora'];
  String? get _areaOperario => _operarioSeleccionado?.area;

  List<String> get _operacionesDisponibles {
    final base = _operacionesPorArea[_areaOperario] ?? [];
    return [...base, ..._operacionesExtra];
  }

  @override
  void initState() {
    super.initState();
    _setFechaHoy();
    _cargarDatos();
    _detectarHoraActual();
  }

  void _setFechaHoy() {
    final now = DateTime.now();
    _fechaHoy =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  void _detectarHoraActual() {
    final now = DateTime.now();
    final ahoraMin = now.hour * 60 + now.minute;
    for (var i = 0; i < _horario.length; i++) {
      final h = _horario[i];
      final inicioMin = h['inicio'] * 60 + h['minInicio'];
      final finMin = h['fin'] * 60 + h['minFin'];
      if (ahoraMin >= inicioMin && ahoraMin < finMin) {
        setState(() => _horaActualIndex = i);
        return;
      }
    }
    setState(() => _horaActualIndex = 0);
  }

  Future<void> _cargarDatos() async {
    final operarios = await DatabaseHelper.instance.obtenerOperarios();
    final ordenes = await DatabaseHelper.instance.obtenerOrdenes();
    setState(() {
      _operarios = operarios;
      _ordenes = ordenes;
    });
  }

  void _seleccionarOperario(Operario? op) {
    if (op == null) return;
    setState(() {
      _operarioSeleccionado = op;
      _operacionesExtra = [];
      _operacionSeleccionada = _operacionDefault[op.nombre];
    });
    _piezasCtrl.clear();
  }

  void _mostrarAgregarOperacion() {
    showDialog(
      context: context,
      builder: (ctx) {
        String? opSeleccionada;
        final disponibles = _operacionesDisponibles
            .where((o) => o != _operacionSeleccionada)
            .toList();
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text(
              'Agregar operación',
              style: TextStyle(color: Colors.white),
            ),
            content: DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Selecciona operación',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0F3460),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: disponibles
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setStateDialog(() => opSeleccionada = val),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF533483),
                ),
                onPressed: () {
                  if (opSeleccionada == null) return;
                  setState(() {
                    if (!_operacionesExtra.contains(opSeleccionada)) {
                      _operacionesExtra.add(opSeleccionada!);
                    }
                    _operacionSeleccionada = opSeleccionada;
                  });
                  Navigator.pop(ctx);
                  _piezasCtrl.clear();
                },
                child: const Text(
                  'Usar esta operación',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarCalculadora() {
    final List<Map<String, TextEditingController>> filas = [
      {'cantidad': TextEditingController(), 'piezas': TextEditingController()},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateModal) {
          int calcularTotal() {
            int total = 0;
            for (final fila in filas) {
              final cantidad = int.tryParse(fila['cantidad']!.text) ?? 0;
              final piezas = int.tryParse(fila['piezas']!.text) ?? 0;
              total += cantidad * piezas;
            }
            return total;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '🧮 Calculadora de bultos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Cantidad',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pzas c/u',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Subtotal',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                const Divider(color: Colors.white24),
                ...List.generate(filas.length, (i) {
                  final fila = filas[i];
                  final cantidad = int.tryParse(fila['cantidad']!.text) ?? 0;
                  final piezas = int.tryParse(fila['piezas']!.text) ?? 0;
                  final subtotal = cantidad * piezas;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fila['cantidad'],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0F3460),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setStateModal(() {}),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '×',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: fila['piezas'],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0F3460),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                            ),
                            onChanged: (_) => setStateModal(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$subtotal',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: filas.length > 1
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                  onPressed: () => setStateModal(() {
                                    fila['cantidad']!.dispose();
                                    fila['piezas']!.dispose();
                                    filas.removeAt(i);
                                  }),
                                )
                              : const SizedBox(),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setStateModal(() {
                    filas.add({
                      'cantidad': TextEditingController(),
                      'piezas': TextEditingController(),
                    });
                  }),
                  icon: const Icon(Icons.add_circle, color: Color(0xFF533483)),
                  label: const Text(
                    'Agregar línea',
                    style: TextStyle(color: Color(0xFF533483)),
                  ),
                ),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${calcularTotal()} pzas',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF533483),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      'Usar ${calcularTotal()} piezas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      final total = calcularTotal();
                      if (total > 0) {
                        setState(() => _piezasCtrl.text = total.toString());
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _guardarYAvanzar() async {
    if (_operarioSeleccionado == null) {
      _mostrarMensaje('⚠️ Selecciona un operario');
      return;
    }
    if (_operacionSeleccionada == null) {
      _mostrarMensaje('⚠️ Selecciona una operación');
      return;
    }
    if (_ordenSeleccionada == null) {
      _mostrarMensaje('⚠️ Selecciona una orden de corte');
      return;
    }

    final piezas = int.tryParse(_piezasCtrl.text) ?? 0;

    if (piezas == 0) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            '¿Guardar 0 piezas?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Estás guardando 0 piezas. ¿Es correcto?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF533483),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Sí, guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    if (piezas > 0) {
      final capturadas = await DatabaseHelper.instance
          .piezasCapturadasPorOperacion(
            _ordenSeleccionada!.id!,
            _operacionSeleccionada!,
          );
      final disponibles = _ordenSeleccionada!.totalPiezas - capturadas;
      if (piezas > disponibles) {
        final exceso = piezas - disponibles;
        _mostrarMensaje(
          '🚫 Te estás pasando por $exceso piezas. Solo quedan $disponibles en "$_operacionSeleccionada".',
        );
        return;
      }
    }

    setState(() => _guardando = true);
    await DatabaseHelper.instance.insertarRegistro(
      Registro(
        operarioId: _operarioSeleccionado!.id!,
        ordenCorteId: _ordenSeleccionada!.id!,
        operacion: _operacionSeleccionada!,
        fecha: _fechaHoy,
        hora: _horaActual,
        piezas: piezas,
      ),
    );
    setState(() => _guardando = false);
    _piezasCtrl.clear();

    if (_horaActualIndex < _horario.length - 1) {
      setState(() => _horaActualIndex++);
      _mostrarMensaje(
        '✅ Guardado — ahora capturando ${_horario[_horaActualIndex]['hora']}',
      );
    } else {
      _mostrarMensaje('✅ Horario completo del día');
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  List<DropdownMenuItem<Operario>> _itemsOperarios() {
    final items = <DropdownMenuItem<Operario>>[];
    for (final area in ['DELANTERO', 'ENSAMBLE']) {
      final lista = _operarios.where((o) => o.area == area).toList();
      if (lista.isEmpty) continue;
      items.add(
        DropdownMenuItem(
          enabled: false,
          value: null,
          child: Text(
            '── $area ──',
            style: TextStyle(
              color: area == 'DELANTERO'
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFAB47BC),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      );
      for (final op in lista) {
        items.add(
          DropdownMenuItem(
            value: op,
            child: Text(op.nombre, style: const TextStyle(color: Colors.white)),
          ),
        );
      }
    }
    return items;
  }

  @override
  void dispose() {
    _piezasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Captura del día',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white54),
                  const SizedBox(width: 10),
                  Text(
                    'Fecha: $_fechaHoy',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Operario
            const Text(
              'Operario',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<Operario>(
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              hint: const Text(
                'Selecciona operario',
                style: TextStyle(color: Colors.white54),
              ),
              value: _operarioSeleccionado,
              items: _itemsOperarios(),
              onChanged: _seleccionarOperario,
            ),
            const SizedBox(height: 16),

            // Orden de Corte
            const Text(
              'Orden de Corte',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<OrdenCorte>(
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              hint: const Text(
                'Selecciona O/C',
                style: TextStyle(color: Colors.white54),
              ),
              value: _ordenSeleccionada,
              items: _ordenes
                  .map(
                    (oc) => DropdownMenuItem(
                      value: oc,
                      child: Text(
                        '${oc.numeroOC} — ${oc.estilo}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _ordenSeleccionada = val),
            ),
            const SizedBox(height: 16),

            // Operación + botón agregar
            if (_operarioSeleccionado != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Operación',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: _mostrarAgregarOperacion,
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF533483),
                      size: 18,
                    ),
                    label: const Text(
                      'Otra operación',
                      style: TextStyle(color: Color(0xFF533483), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF533483),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.work_outline,
                      color: Color(0xFF533483),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _operacionSeleccionada ?? 'Sin operación default',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Tarjeta hora actual
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF533483), width: 2),
              ),
              child: Column(
                children: [
                  // Barra de progreso de horas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_horario.length, (i) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 28,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i < _horaActualIndex
                              ? Colors.greenAccent
                              : i == _horaActualIndex
                              ? const Color(0xFF533483)
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hora ${_horaActualIndex + 1} de ${_horario.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _horaActual,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Botón calculadora ──────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _mostrarCalculadora,
                      icon: const Icon(
                        Icons.calculate,
                        color: Color(0xFF533483),
                        size: 20,
                      ),
                      label: const Text(
                        'Calcular bultos',
                        style: TextStyle(
                          color: Color(0xFF533483),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  // Campo piezas
                  TextField(
                    controller: _piezasCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        fontSize: 32,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1A1A2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixText: 'pzas',
                      suffixStyle: const TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Capturadas / Disponibles
                  if (_ordenSeleccionada != null &&
                      _operacionSeleccionada != null)
                    FutureBuilder<int>(
                      future: DatabaseHelper.instance
                          .piezasCapturadasPorOperacion(
                            _ordenSeleccionada!.id!,
                            _operacionSeleccionada!,
                          ),
                      builder: (context, snapshot) {
                        final capturadas = snapshot.data ?? 0;
                        final disponibles =
                            _ordenSeleccionada!.totalPiezas - capturadas;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$capturadas',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Capturadas',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '$disponibles',
                                  style: TextStyle(
                                    color: disponibles <= 0
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Disponibles',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 16),

                  // Botón guardar y avanzar
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF533483),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _guardando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                      label: Text(
                        _horaActualIndex < _horario.length - 1
                            ? 'Guardar y pasar a ${_horario[_horaActualIndex + 1]['hora']}'
                            : 'Guardar — Fin del día',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _guardando ? null : _guardarYAvanzar,
                    ),
                  ),

                  // Botón regresar hora
                  if (_horaActualIndex > 0)
                    TextButton.icon(
                      onPressed: () => setState(() => _horaActualIndex--),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white38,
                        size: 16,
                      ),
                      label: const Text(
                        'Regresar a hora anterior',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
