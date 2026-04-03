import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/operario.dart';
import '../models/orden_corte.dart';
import '../models/registro.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<Operario> _operarios = [];
  List<OrdenCorte> _ordenes = [];
  List<Registro> _registros = [];

  Operario? _operarioFiltro;
  OrdenCorte? _ordenFiltro;
  String? _fechaFiltro;

  final _fechaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final operarios = await DatabaseHelper.instance.obtenerOperarios();
    final ordenes = await DatabaseHelper.instance.obtenerOrdenes();
    final registros = await DatabaseHelper.instance.obtenerRegistros();
    setState(() {
      _operarios = operarios;
      _ordenes = ordenes;
      _registros = registros;
    });
  }

  List<Registro> get _registrosFiltrados {
    return _registros.where((r) {
      final porOperario =
          _operarioFiltro == null || r.operarioId == _operarioFiltro!.id;
      final porOrden =
          _ordenFiltro == null || r.ordenCorteId == _ordenFiltro!.id;
      final porFecha =
          _fechaFiltro == null ||
          _fechaFiltro!.isEmpty ||
          r.fecha == _fechaFiltro;
      return porOperario && porOrden && porFecha;
    }).toList();
  }

  int get _totalPiezasFiltradas =>
      _registrosFiltrados.fold(0, (sum, r) => sum + r.piezas);

  String _nombreOperario(int id) {
    try {
      return _operarios.firstWhere((o) => o.id == id).nombre;
    } catch (_) {
      return 'Desconocido';
    }
  }

  String _numeroOC(int id) {
    try {
      return _ordenes.firstWhere((o) => o.id == id).numeroOC;
    } catch (_) {
      return '---';
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _operarioFiltro = null;
      _ordenFiltro = null;
      _fechaFiltro = null;
      _fechaCtrl.clear();
    });
  }

  @override
  void dispose() {
    _fechaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _registrosFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Reportes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _limpiarFiltros,
            tooltip: 'Limpiar filtros',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filtros ──────────────────────────────────────
          Container(
            color: const Color(0xFF16213E),
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Filtro operario
                DropdownButtonFormField<Operario>(
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filtrar por operario',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F3460),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: _operarioFiltro,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Todos',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ..._operarios.map(
                      (op) =>
                          DropdownMenuItem(value: op, child: Text(op.nombre)),
                    ),
                  ],
                  onChanged: (val) => setState(() => _operarioFiltro = val),
                ),
                const SizedBox(height: 8),

                // Filtro orden
                DropdownButtonFormField<OrdenCorte>(
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filtrar por O/C',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F3460),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  value: _ordenFiltro,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Todas',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ..._ordenes.map(
                      (oc) => DropdownMenuItem(
                        value: oc,
                        child: Text('${oc.numeroOC} — ${oc.estilo}'),
                      ),
                    ),
                  ],
                  onChanged: (val) => setState(() => _ordenFiltro = val),
                ),
                const SizedBox(height: 8),

                // Filtro fecha
                TextField(
                  controller: _fechaCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filtrar por fecha (dd/mm/aaaa)',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F3460),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.white54,
                      ),
                      onPressed: () async {
                        final fecha = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) =>
                              Theme(data: ThemeData.dark(), child: child!),
                        );
                        if (fecha != null) {
                          final formatted =
                              '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
                          setState(() {
                            _fechaFiltro = formatted;
                            _fechaCtrl.text = formatted;
                          });
                        }
                      },
                    ),
                  ),
                  onChanged: (val) => setState(() => _fechaFiltro = val),
                ),
              ],
            ),
          ),

          // ── Total ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0F3460),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtrados.length} registros',
                  style: const TextStyle(color: Colors.white70),
                ),
                Text(
                  'Total: $_totalPiezasFiltradas pzas',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ─────────────────────────────────────────
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay registros con estos filtros',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtrados.length,
                    itemBuilder: (ctx, i) {
                      final r = filtrados[i];
                      return Card(
                        color: const Color(0xFF16213E),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Piezas destacadas
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF533483),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${r.piezas}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const Text(
                                      'pzas',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Datos
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _nombreOperario(r.operarioId),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      r.operacion,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.assignment,
                                          color: Colors.white38,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'O/C: ${_numeroOC(r.ordenCorteId)}',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.white38,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r.hora,
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Fecha
                              Text(
                                r.fecha,
                                style: const TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
