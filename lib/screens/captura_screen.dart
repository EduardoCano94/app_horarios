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
  final List<String> _horas = [
    '9:30',
    '10:30',
    '11:30',
    '12:30',
    '2:30',
    '3:30',
    '4:30',
    '5:30',
    '6:30',
  ];

  // Operaciones agrupadas por sección
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

  List<Operario> _operarios = [];
  List<OrdenCorte> _ordenes = [];
  Operario? _operarioSeleccionado;
  OrdenCorte? _ordenSeleccionada;
  String? _operacionSeleccionada;
  String _fechaHoy = '';
  final Map<String, TextEditingController> _controladoresPiezas = {};

  // Área del operario seleccionado
  String? get _areaOperario => _operarioSeleccionado?.area;

  // Operaciones filtradas según área del operario
  List<String> get _operacionesFiltradas {
    if (_areaOperario == null) return [];
    return _operacionesPorArea[_areaOperario] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _setFechaHoy();
    _cargarDatos();
    for (final hora in _horas) {
      _controladoresPiezas[hora] = TextEditingController();
    }
  }

  void _setFechaHoy() {
    final now = DateTime.now();
    _fechaHoy =
        '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  Future<void> _cargarDatos() async {
    final operarios = await DatabaseHelper.instance.obtenerOperarios();
    final ordenes = await DatabaseHelper.instance.obtenerOrdenes();
    setState(() {
      _operarios = operarios;
      _ordenes = ordenes;
    });
  }

  // Operarios agrupados por área para el dropdown
  List<DropdownMenuItem<Operario>> _itemsOperarios() {
    final items = <DropdownMenuItem<Operario>>[];
    final areas = ['DELANTERO', 'ENSAMBLE'];

    for (final area in areas) {
      final operariosArea = _operarios.where((o) => o.area == area).toList();
      if (operariosArea.isEmpty) continue;

      // Encabezado de área (no seleccionable)
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

      // Operarios del área
      for (final op in operariosArea) {
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

  // Operaciones agrupadas para el dropdown
  List<DropdownMenuItem<String>> _itemsOperaciones() {
    if (_areaOperario == null) return [];
    final operaciones = _operacionesFiltradas;
    return operaciones
        .map(
          (op) => DropdownMenuItem(
            value: op,
            child: Text(op, style: const TextStyle(color: Colors.white)),
          ),
        )
        .toList();
  }

  int _totalPiezasIngresadas() {
    int total = 0;
    for (final ctrl in _controladoresPiezas.values) {
      total += int.tryParse(ctrl.text) ?? 0;
    }
    return total;
  }

  Future<void> _guardarRegistros() async {
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

    final totalIngresado = _totalPiezasIngresadas();
    if (totalIngresado == 0) {
      _mostrarMensaje('⚠️ Ingresa al menos una cantidad de piezas');
      return;
    }

    final capturadasEnEstaOperacion = await DatabaseHelper.instance
        .piezasCapturadasPorOperacion(
          _ordenSeleccionada!.id!,
          _operacionSeleccionada!,
        );

    final disponibles =
        _ordenSeleccionada!.totalPiezas - capturadasEnEstaOperacion;

    if (totalIngresado > disponibles) {
      final exceso = totalIngresado - disponibles;
      _mostrarMensaje(
        '🚫 Te estás pasando por $exceso piezas en "$_operacionSeleccionada". '
        'Solo quedan $disponibles disponibles.',
      );
      return;
    }

    for (final hora in _horas) {
      final texto = _controladoresPiezas[hora]!.text;
      final piezas = int.tryParse(texto) ?? 0;
      if (piezas > 0) {
        final registro = Registro(
          operarioId: _operarioSeleccionado!.id!,
          ordenCorteId: _ordenSeleccionada!.id!,
          operacion: _operacionSeleccionada!,
          fecha: _fechaHoy,
          hora: hora,
          piezas: piezas,
        );
        await DatabaseHelper.instance.insertarRegistro(registro);
      }
    }

    _mostrarMensaje('✅ Registro guardado correctamente');
    _limpiarFormulario();
  }

  void _limpiarFormulario() {
    setState(() {
      _operarioSeleccionado = null;
      _operacionSeleccionada = null;
      _ordenSeleccionada = null;
    });
    for (final ctrl in _controladoresPiezas.values) {
      ctrl.clear();
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    for (final ctrl in _controladoresPiezas.values) {
      ctrl.dispose();
    }
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
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Operario agrupado por área
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
              onChanged: (val) => setState(() {
                _operarioSeleccionado = val;
                _operacionSeleccionada = null; // reset operación
              }),
            ),
            const SizedBox(height: 16),

            // Operación filtrada por área del operario
            const Text(
              'Operación',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
            if (_areaOperario != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: _areaOperario == 'DELANTERO'
                      ? const Color(0xFF1B4332)
                      : const Color(0xFF533483),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Área: $_areaOperario',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF16213E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF16213E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              hint: Text(
                _areaOperario == null
                    ? 'Primero selecciona un operario'
                    : 'Selecciona operación',
                style: const TextStyle(color: Colors.white54),
              ),
              value: _operacionSeleccionada,
              items: _itemsOperaciones(),
              onChanged: _areaOperario == null
                  ? null
                  : (val) => setState(() => _operacionSeleccionada = val),
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
              items: _ordenes.map((oc) {
                return DropdownMenuItem(
                  value: oc,
                  child: Text(
                    '${oc.numeroOC} — ${oc.estilo}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _ordenSeleccionada = val),
            ),

            // Piezas disponibles
            if (_ordenSeleccionada != null && _operacionSeleccionada != null)
              FutureBuilder<int>(
                future: DatabaseHelper.instance.piezasCapturadasPorOperacion(
                  _ordenSeleccionada!.id!,
                  _operacionSeleccionada!,
                ),
                builder: (context, snapshot) {
                  final capturadas = snapshot.data ?? 0;
                  final disponibles =
                      _ordenSeleccionada!.totalPiezas - capturadas;
                  return Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operación: $_operacionSeleccionada',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Capturadas: $capturadas',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Disponibles: $disponibles',
                              style: TextStyle(
                                color: disponibles <= 0
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _ordenSeleccionada!.totalPiezas > 0
                                ? (capturadas / _ordenSeleccionada!.totalPiezas)
                                      .clamp(0.0, 1.0)
                                : 0.0,
                            minHeight: 8,
                            backgroundColor: const Color(0xFF1A1A2E),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              disponibles <= 0
                                  ? Colors.redAccent
                                  : Colors.greenAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            // Piezas por hora
            const Text(
              'Piezas por hora',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _horas.map((hora) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            hora,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _controladoresPiezas[hora],
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: const Color(0xFF0F3460),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'pzas',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Botón guardar
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
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text(
                  'Guardar Registro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _guardarRegistros,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
