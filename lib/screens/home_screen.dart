import 'package:flutter/material.dart';
import 'operarios_screen.dart';
import 'captura_screen.dart';
import 'ordenes_screen.dart';
import 'reportes_screen.dart';
import 'exportar_screen.dart';
import 'login_screen.dart';
import 'usuarios_screen.dart';

class HomeScreen extends StatelessWidget {
  final String rol;
  const HomeScreen({super.key, required this.rol});

  bool get _esEncargado => rol == 'ENCARGADO';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Producción Persatex',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Chip de rol
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _colorRol(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                rol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.factory, size: 80, color: Color(0xFF0F3460)),
            const SizedBox(height: 16),
            const Text(
              'Jalacingo',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),

            // Captura — solo ENCARGADO
            if (_esEncargado) ...[
              _botonMenu(
                context,
                icono: Icons.edit_note,
                texto: 'Captura del día',
                subtexto: 'Registrar piezas por hora',
                color: const Color(0xFF533483),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CapturaScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Operarios — solo ENCARGADO
            if (_esEncargado) ...[
              _botonMenu(
                context,
                icono: Icons.people,
                texto: 'Operarios',
                subtexto: 'Agregar, editar y ver operarios',
                color: const Color(0xFF0F3460),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OperariosScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Órdenes — solo ENCARGADO
            if (_esEncargado) ...[
              _botonMenu(
                context,
                icono: Icons.assignment,
                texto: 'Órdenes de Corte',
                subtexto: 'Ver avance por O/C',
                color: const Color(0xFF1B4332),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OrdenesScreen()),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Solo DUEÑO
            if (rol == 'DUEÑO') ...[
              const SizedBox(height: 16),
              _botonMenu(
                context,
                icono: Icons.manage_accounts,
                texto: 'Usuarios',
                subtexto: 'Gestionar accesos y contraseñas',
                color: Colors.amber.shade800,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsuariosScreen()),
                ),
              ),
            ],

            // Reportes — todos
            _botonMenu(
              context,
              icono: Icons.bar_chart,
              texto: 'Reportes',
              subtexto: 'Ver producción por operario y O/C',
              color: const Color(0xFF7B2D8B),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportesScreen()),
              ),
            ),
            const SizedBox(height: 16),

            // Exportar — todos
            _botonMenu(
              context,
              icono: Icons.file_download,
              texto: 'Exportar a Excel',
              subtexto: 'Generar reporte semanal',
              color: const Color(0xFF1B4332),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportarScreen()),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _colorRol() {
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

  Widget _botonMenu(
    BuildContext context, {
    required IconData icono,
    required String texto,
    required String subtexto,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icono, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  texto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtexto,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}
