import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/operario.dart';

class OperariosScreen extends StatefulWidget {
  const OperariosScreen({super.key});

  @override
  State<OperariosScreen> createState() => _OperariosScreenState();
}

class _OperariosScreenState extends State<OperariosScreen> {
  List<Operario> _operarios = [];
  String _areaBusqueda = 'TODAS';

  final List<String> _areas = [
    'TODAS',
    'TERMINADO',
    'ENSAMBLE',
    'DELANTERO',
    'TRASERO',
    'PARTES CHICAS',
    'JOGGER QUIRURGICO',
    'CHAMARRA',
  ];

  final Map<String, Color> _coloresArea = {
    'TERMINADO': const Color(0xFF0F3460),
    'ENSAMBLE': const Color(0xFF533483),
    'DELANTERO': const Color(0xFF1B4332),
    'TRASERO': const Color(0xFF7B2D8B),
    'PARTES CHICAS': const Color(0xFF8B0000),
    'JOGGER QUIRURGICO': const Color(0xFF2C5F2E),
    'CHAMARRA': const Color(0xFF4A4A00),
  };

  @override
  void initState() {
    super.initState();
    _cargarOperarios();
  }

  Future<void> _cargarOperarios() async {
    final operarios = await DatabaseHelper.instance.obtenerOperarios();
    setState(() => _operarios = operarios);
  }

  List<Operario> get _operariosFiltrados {
    if (_areaBusqueda == 'TODAS') return _operarios;
    return _operarios.where((o) => o.area == _areaBusqueda).toList();
  }

  Future<void> _mostrarDialogo({Operario? operario}) async {
    final nombreCtrl = TextEditingController(text: operario?.nombre ?? '');
    String areaSeleccionada = operario?.area ?? 'ENSAMBLE';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            operario == null ? 'Nuevo Operario' : 'Editar Operario',
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
                  labelText: 'Nombre completo',
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
                  labelText: 'Área',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0F3460),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _areas
                    .where((a) => a != 'TODAS')
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (val) =>
                    setStateDialog(() => areaSeleccionada = val!),
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
                if (operario == null) {
                  await DatabaseHelper.instance.insertarOperario(
                    Operario(
                      nombre: nombreCtrl.text.trim(),
                      area: areaSeleccionada,
                    ),
                  );
                } else {
                  await DatabaseHelper.instance.actualizarOperario(
                    Operario(
                      id: operario.id,
                      nombre: nombreCtrl.text.trim(),
                      area: areaSeleccionada,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
                await _cargarOperarios();
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

  Future<void> _eliminarOperario(int id, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '¿Eliminar operario?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se eliminará a "$nombre" permanentemente.',
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
    if (confirmar == true) {
      await DatabaseHelper.instance.eliminarOperario(id);
      await _cargarOperarios();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _operariosFiltrados;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Operarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF533483),
        onPressed: () => _mostrarDialogo(),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filtro por área
          Container(
            color: const Color(0xFF16213E),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _areas.length,
              itemBuilder: (ctx, i) {
                final area = _areas[i];
                final seleccionada = area == _areaBusqueda;
                return GestureDetector(
                  onTap: () => setState(() => _areaBusqueda = area),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: seleccionada
                          ? (_coloresArea[area] ?? const Color(0xFF533483))
                          : const Color(0xFF0F3460),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        area,
                        style: TextStyle(
                          color: seleccionada ? Colors.white : Colors.white54,
                          fontSize: 12,
                          fontWeight: seleccionada
                              ? FontWeight.bold
                              : FontWeight.normal,
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
              '${filtrados.length} operarios',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),

          // Lista
          Expanded(
            child: filtrados.isEmpty
                ? const Center(
                    child: Text(
                      'No hay operarios en esta área',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtrados.length,
                    itemBuilder: (ctx, i) {
                      final op = filtrados[i];
                      final color =
                          _coloresArea[op.area] ?? const Color(0xFF533483);
                      return Card(
                        color: const Color(0xFF16213E),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: Text(
                              op.nombre[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            op.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              op.area,
                              style: TextStyle(color: color, fontSize: 11),
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
                                onPressed: () => _mostrarDialogo(operario: op),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _eliminarOperario(op.id!, op.nombre),
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
