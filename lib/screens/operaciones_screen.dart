import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class OperacionesScreen extends StatefulWidget {
  const OperacionesScreen({super.key});

  @override
  State<OperacionesScreen> createState() => _OperacionesScreenState();
}

class _OperacionesScreenState extends State<OperacionesScreen> {
  List<Map<String, dynamic>> _operaciones = [];
  String _areaFiltro = 'TODAS';

  final List<String> _areas = ['TODAS', 'DELANTERO', 'ENSAMBLE', 'AMBAS'];
  final Map<String, Color> _colores = {
    'DELANTERO': const Color(0xFF1B4332),
    'ENSAMBLE': const Color(0xFF533483),
    'AMBAS': const Color(0xFF0F3460),
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final ops = await DatabaseHelper.instance.obtenerOperaciones();
    setState(() => _operaciones = ops);
  }

  List<Map<String, dynamic>> get _filtradas {
    if (_areaFiltro == 'TODAS') return _operaciones;
    return _operaciones.where((o) => o['area'] == _areaFiltro).toList();
  }

  Future<void> _mostrarDialogo({Map<String, dynamic>? op}) async {
    final nombreCtrl = TextEditingController(text: op?['nombre'] ?? '');
    String areaSeleccionada = op?['area'] ?? 'DELANTERO';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            op == null ? 'Nueva Operacion' : 'Editar Operacion',
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                style: const TextStyle(color: Colors.white),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Nombre de la operacion',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF16213E),
                style: const TextStyle(color: Colors.white),
                value: areaSeleccionada,
                decoration: InputDecoration(
                  labelText: 'Area',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: ['DELANTERO', 'ENSAMBLE', 'AMBAS']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (val) => setD(() => areaSeleccionada = val!),
              ),
            ],
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
                if (nombreCtrl.text.trim().isEmpty) return;
                if (op == null) {
                  await DatabaseHelper.instance.insertarOperacion(
                    nombreCtrl.text.trim(),
                    areaSeleccionada,
                  );
                } else {
                  await DatabaseHelper.instance.actualizarOperacion(
                    op['id'],
                    nombreCtrl.text.trim(),
                    areaSeleccionada,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _cargar();
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _eliminar(int id, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '¿Eliminar operacion?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se eliminara "$nombre".',
          style: const TextStyle(color: Colors.white70),
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
    if (ok == true) {
      await DatabaseHelper.instance.eliminarOperacion(id);
      await _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtradas = _filtradas;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Operaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF533483),
        onPressed: () => _mostrarDialogo(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filtro tabs
          Container(
            color: const Color(0xFF16213E),
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _areas.length,
              itemBuilder: (ctx, i) {
                final area = _areas[i];
                final sel = area == _areaFiltro;
                return GestureDetector(
                  onTap: () => setState(() => _areaFiltro = area),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: sel
                          ? (_colores[area] ?? const Color(0xFF533483))
                          : const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        area,
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Contador
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: const Color(0xFF0F3460),
            child: Text(
              '${filtradas.length} operaciones',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          // Lista
          Expanded(
            child: filtradas.isEmpty
                ? const Center(
                    child: Text(
                      'No hay operaciones en esta area',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtradas.length,
                    itemBuilder: (ctx, i) {
                      final op = filtradas[i];
                      final color =
                          _colores[op['area']] ?? const Color(0xFF533483);
                      return Card(
                        color: const Color(0xFF16213E),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(
                            op['nombre'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              op['area'],
                              style: TextStyle(color: color, fontSize: 10),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () => _mostrarDialogo(op: op),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _eliminar(op['id'], op['nombre']),
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
