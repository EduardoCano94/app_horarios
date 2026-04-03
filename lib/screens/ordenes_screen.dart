import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/orden_corte.dart';

class OrdenesScreen extends StatefulWidget {
  const OrdenesScreen({super.key});

  @override
  State<OrdenesScreen> createState() => _OrdenesScreenState();
}

class _OrdenesScreenState extends State<OrdenesScreen> {
  List<OrdenCorte> _ordenes = [];

  final _numeroOCCtrl = TextEditingController();
  final _estiloCtrl = TextEditingController();
  final _totalPiezasCtrl = TextEditingController();
  final _semanaCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
  }

  Future<void> _cargarOrdenes() async {
    final ordenes = await DatabaseHelper.instance.obtenerOrdenes();
    setState(() => _ordenes = ordenes);
  }

  Future<void> _mostrarDialogoAgregar() async {
    _numeroOCCtrl.clear();
    _estiloCtrl.clear();
    _totalPiezasCtrl.clear();
    _semanaCtrl.clear();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Nueva Orden de Corte',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(_numeroOCCtrl, 'Número O/C', TextInputType.text),
              const SizedBox(height: 10),
              _campo(_estiloCtrl, 'Estilo', TextInputType.text),
              const SizedBox(height: 10),
              _campo(_totalPiezasCtrl, 'Total de piezas', TextInputType.number),
              const SizedBox(height: 10),
              _campo(
                _semanaCtrl,
                'Semana (ej: 18-24 Marzo)',
                TextInputType.text,
              ),
            ],
          ),
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
            onPressed: () async {
              if (_numeroOCCtrl.text.isEmpty ||
                  _estiloCtrl.text.isEmpty ||
                  _totalPiezasCtrl.text.isEmpty ||
                  _semanaCtrl.text.isEmpty) {
                return;
              }
              final orden = OrdenCorte(
                numeroOC: _numeroOCCtrl.text.trim(),
                estilo: _estiloCtrl.text.trim(),
                totalPiezas: int.tryParse(_totalPiezasCtrl.text) ?? 0,
                semana: _semanaCtrl.text.trim(),
              );
              await DatabaseHelper.instance.insertarOrden(orden);
              if (ctx.mounted) Navigator.pop(ctx);
              await _cargarOrdenes();
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarOrden(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '¿Eliminar orden?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Esta acción no se puede deshacer.',
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await DatabaseHelper.instance.eliminarOrden(id);
      await _cargarOrdenes();
    }
  }

  Widget _campo(TextEditingController ctrl, String label, TextInputType tipo) {
    return TextField(
      controller: ctrl,
      keyboardType: tipo,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0F3460),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _numeroOCCtrl.dispose();
    _estiloCtrl.dispose();
    _totalPiezasCtrl.dispose();
    _semanaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Órdenes de Corte',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF533483),
        onPressed: _mostrarDialogoAgregar,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _ordenes.isEmpty
          ? const Center(
              child: Text(
                'No hay órdenes registradas',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _ordenes.length,
              itemBuilder: (ctx, i) {
                final oc = _ordenes[i];
                return FutureBuilder<int>(
                  future: DatabaseHelper.instance.piezasCapturadas(oc.id!),
                  builder: (context, snapshot) {
                    final capturadas = snapshot.data ?? 0;
                    final disponibles = oc.totalPiezas - capturadas;
                    final porcentaje = oc.totalPiezas > 0
                        ? capturadas / oc.totalPiezas
                        : 0.0;

                    return Card(
                      color: const Color(0xFF16213E),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'O/C: ${oc.numeroOC}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _eliminarOrden(oc.id!),
                                ),
                              ],
                            ),
                            Text(
                              oc.estilo,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Semana: ${oc.semana}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ${oc.totalPiezas} pzas',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Capturadas: $capturadas',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  'Disponibles: $disponibles',
                                  style: TextStyle(
                                    color: disponibles <= 0
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: porcentaje.clamp(0.0, 1.0),
                                minHeight: 8,
                                backgroundColor: const Color(0xFF0F3460),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  porcentaje >= 1.0
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
