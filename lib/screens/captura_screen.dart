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

  final List<String> _operaciones = [
    'PEGAR OJALERA',
    'PEGAR BOTONERA',
    'S/COSER OJALERA',
    'S/C BOTONERA',
    'S/C FORRO',
    'DISEÑO J',
    'PEGAR FORRO',
    'ENTRADA DE BOLSA',
    'S/COSER FORRO NORMAL',
    'APUNTAR BOLSA',
    'ENGRAPAR',
    'ENCUARTAR NORMAL',
    'PEGAR ETIQUETA MONARCH',
    'PRECILLAR SECRETA (2)',
    'PARES',
    'REVISAR DELANTERO',
    'CERRAR ENTREPIERNA',
    'CERRAR COSTADOS',
    'S/C ENTREPIERNA',
    'CERRAR COSTADOS',
    'MARCAR COSTADOS',
    'S/C COSTADOS',
    'CERRAR COSTADOS',
    'HABILITAR PRETINA',
    'PRESILLAR ENTREPIERNA',
    'PEGAR PRETINA NORMAL',
    'PEGAR PRETINA NORMAL 2 AGUAS',
    'HACER CUADRO',
    'PRESILLAR COSTADOS Y ENTRADA DE BOLSA',
    'PRESILLAR ENTRE BOLSA Y COSTADO',
    'PEGAR TRABA',
    'PRESILLAR ENTRE BOLSA Y COSTADO',
    'PEGAR TRABA (5)',
    'OJAL',
    'HACER VALENCIANA',
  ];

  List<Operario> _operarios = [];
  List<OrdenCorte> _ordenes = [];
  Operario? _operarioSeleccionado;
  OrdenCorte? _ordenSeleccionada;
  String? _operacionSeleccionada;
  String _fechaHoy = '';
  final Map<String, TextEditingController> _controladoresPiezas = {};

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

    final capturadas = await DatabaseHelper.instance.piezasCapturadas(
      _ordenSeleccionada!.id!,
    );
    final disponibles = _ordenSeleccionada!.totalPiezas - capturadas;

    if (totalIngresado > disponibles) {
      _mostrarMensaje(
        '🚫 Excede el límite. Solo quedan $disponibles piezas disponibles',
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
              items: _operarios.map((op) {
                return DropdownMenuItem(value: op, child: Text(op.nombre));
              }).toList(),
              onChanged: (val) => setState(() => _operarioSeleccionado = val),
            ),
            const SizedBox(height: 16),

            // Operación
            const Text(
              'Operación',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 6),
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
              hint: const Text(
                'Selecciona operación',
                style: TextStyle(color: Colors.white54),
              ),
              value: _operacionSeleccionada,
              items: _operaciones.map((op) {
                return DropdownMenuItem(value: op, child: Text(op));
              }).toList(),
              onChanged: (val) => setState(() => _operacionSeleccionada = val),
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
                  child: Text('${oc.numeroOC} — ${oc.estilo}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _ordenSeleccionada = val),
            ),

            // Piezas disponibles
            if (_ordenSeleccionada != null)
              FutureBuilder<int>(
                future: DatabaseHelper.instance.piezasCapturadas(
                  _ordenSeleccionada!.id!,
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
                    child: Row(
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
