import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/usuario.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  List<Usuario> _usuarios = [];

  final _nombreCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  String _rolSeleccionado = 'ENCARGADO';
  bool _verPass = false;

  final List<String> _roles = ['DUEÑO', 'GERENTE', 'ENCARGADO'];

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final usuarios = await DatabaseHelper.instance.obtenerUsuarios();
    setState(() => _usuarios = usuarios);
  }

  Future<void> _mostrarDialogoAgregar() async {
    _nombreCtrl.clear();
    _passCtrl.clear();
    _confirmPassCtrl.clear();
    _rolSeleccionado = 'ENCARGADO';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text(
            'Nuevo Usuario',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _campo(_nombreCtrl, 'Nombre', false, setStateDialog),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF16213E),
                  style: const TextStyle(color: Colors.white),
                  value: _rolSeleccionado,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F3460),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: _roles
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => _rolSeleccionado = val!),
                ),
                const SizedBox(height: 10),
                _campo(_passCtrl, 'Contraseña', !_verPass, setStateDialog),
                const SizedBox(height: 10),
                _campo(
                  _confirmPassCtrl,
                  'Confirmar contraseña',
                  !_verPass,
                  setStateDialog,
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _verPass,
                      onChanged: (val) => setStateDialog(() => _verPass = val!),
                      fillColor: WidgetStateProperty.all(
                        const Color(0xFF533483),
                      ),
                    ),
                    const Text(
                      'Ver contraseña',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
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
                if (_nombreCtrl.text.trim().isEmpty ||
                    _passCtrl.text.trim().isEmpty) {
                  return;
                }
                if (_passCtrl.text != _confirmPassCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden'),
                    ),
                  );
                  return;
                }
                await DatabaseHelper.instance.insertarUsuario(
                  Usuario(
                    nombre: _nombreCtrl.text.trim(),
                    rol: _rolSeleccionado,
                    passwordHash: '',
                  ),
                  _passCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                await _cargarUsuarios();
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

  Future<void> _mostrarDialogoCambiarPass(Usuario usuario) async {
    _passCtrl.clear();
    _confirmPassCtrl.clear();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: Text(
            'Cambiar contraseña\n${usuario.nombre}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _campo(_passCtrl, 'Nueva contraseña', !_verPass, setStateDialog),
              const SizedBox(height: 10),
              _campo(_confirmPassCtrl, 'Confirmar', !_verPass, setStateDialog),
              Row(
                children: [
                  Checkbox(
                    value: _verPass,
                    onChanged: (val) => setStateDialog(() => _verPass = val!),
                    fillColor: WidgetStateProperty.all(const Color(0xFF533483)),
                  ),
                  const Text(
                    'Ver contraseña',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
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
                if (_passCtrl.text.isEmpty) return;
                if (_passCtrl.text != _confirmPassCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden'),
                    ),
                  );
                  return;
                }
                await DatabaseHelper.instance.cambiarPassword(
                  usuario.id!,
                  _passCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Contraseña actualizada')),
                );
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

  Future<void> _eliminarUsuario(Usuario usuario) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          '¿Eliminar usuario?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Se eliminará a "${usuario.nombre}" permanentemente.',
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
      await DatabaseHelper.instance.eliminarUsuario(usuario.id!);
      await _cargarUsuarios();
    }
  }

  Widget _campo(
    TextEditingController ctrl,
    String label,
    bool obscure,
    StateSetter setStateDialog,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
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

  Color _colorRol(String rol) {
    switch (rol) {
      case 'DUEÑO':
        return Colors.amber.shade800;
      case 'GERENTE':
        return const Color(0xFF0F3460);
      case 'ENCARGADO':
        return const Color(0xFF533483);
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Gestión de Usuarios',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF533483),
        onPressed: _mostrarDialogoAgregar,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _usuarios.isEmpty
          ? const Center(
              child: Text(
                'No hay usuarios registrados',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _usuarios.length,
              itemBuilder: (ctx, i) {
                final u = _usuarios[i];
                final color = _colorRol(u.rol);
                return Card(
                  color: const Color(0xFF16213E),
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Text(
                        u.nombre[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      u.nombre,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
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
                        u.rol,
                        style: TextStyle(color: color, fontSize: 11),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.lock_reset,
                            color: Colors.white54,
                            size: 20,
                          ),
                          onPressed: () => _mostrarDialogoCambiarPass(u),
                          tooltip: 'Cambiar contraseña',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _eliminarUsuario(u),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
