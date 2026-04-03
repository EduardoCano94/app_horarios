import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../db/database_helper.dart';
import '../models/operario.dart';
import '../models/orden_corte.dart';
import '../models/registro.dart';

class ExportarScreen extends StatefulWidget {
  const ExportarScreen({super.key});

  @override
  State<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  List<Operario> _operarios = [];
  List<OrdenCorte> _ordenes = [];
  List<Registro> _registros = [];
  bool _exportando = false;

  String? _fechaInicio;
  String? _fechaFin;

  final _inicioCtrl = TextEditingController();
  final _finCtrl = TextEditingController();

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

  String _estiloOC(int id) {
    try {
      return _ordenes.firstWhere((o) => o.id == id).estilo;
    } catch (_) {
      return '---';
    }
  }

  // Convierte dd/mm/aaaa a DateTime para comparar
  DateTime? _parseFecha(String fecha) {
    try {
      final partes = fecha.split('/');
      return DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );
    } catch (_) {
      return null;
    }
  }

  List<Registro> get _registrosFiltrados {
    if (_fechaInicio == null || _fechaFin == null) return _registros;
    final inicio = _parseFecha(_fechaInicio!);
    final fin = _parseFecha(_fechaFin!);
    if (inicio == null || fin == null) return _registros;
    return _registros.where((r) {
      final fecha = _parseFecha(r.fecha);
      if (fecha == null) return false;
      return !fecha.isBefore(inicio) && !fecha.isAfter(fin);
    }).toList();
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (fecha != null) {
      final formatted =
          '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';
      setState(() {
        if (esInicio) {
          _fechaInicio = formatted;
          _inicioCtrl.text = formatted;
        } else {
          _fechaFin = formatted;
          _finCtrl.text = formatted;
        }
      });
    }
  }

  Future<void> _exportarExcel() async {
    final registros = _registrosFiltrados;
    if (registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ No hay registros para exportar')),
      );
      return;
    }

    setState(() => _exportando = true);

    try {
      final excel = Excel.createExcel();

      // ── Hoja 1: Detalle de registros ──────────────────
      final hojaDetalle = excel['Registros'];
      excel.setDefaultSheet('Registros');

      // Encabezados
      final encabezados = [
        'Fecha',
        'Operario',
        'O/C',
        'Estilo',
        'Operación',
        'Hora',
        'Piezas',
      ];
      for (var i = 0; i < encabezados.length; i++) {
        final cell = hojaDetalle.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(encabezados[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#533483'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Datos
      for (var i = 0; i < registros.length; i++) {
        final r = registros[i];
        final fila = [
          r.fecha,
          _nombreOperario(r.operarioId),
          _numeroOC(r.ordenCorteId),
          _estiloOC(r.ordenCorteId),
          r.operacion,
          r.hora,
          r.piezas.toString(),
        ];
        for (var j = 0; j < fila.length; j++) {
          hojaDetalle
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = TextCellValue(
            fila[j],
          );
        }
      }

      // ── Hoja 2: Resumen por operario ──────────────────
      final hojaResumen = excel['Resumen por Operario'];
      final encResumen = ['Operario', 'Operación', 'O/C', 'Total Piezas'];
      for (var i = 0; i < encResumen.length; i++) {
        final cell = hojaResumen.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(encResumen[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#1B4332'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Agrupar por operario + operación + OC
      final Map<String, int> resumen = {};
      for (final r in registros) {
        final clave =
            '${_nombreOperario(r.operarioId)}|${r.operacion}|${_numeroOC(r.ordenCorteId)}';
        resumen[clave] = (resumen[clave] ?? 0) + r.piezas;
      }

      var fila = 1;
      resumen.forEach((clave, total) {
        final partes = clave.split('|');
        final datos = [partes[0], partes[1], partes[2], total.toString()];
        for (var j = 0; j < datos.length; j++) {
          hojaResumen
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: fila))
              .value = TextCellValue(
            datos[j],
          );
        }
        fila++;
      });

      // ── Hoja 3: Resumen por O/C ───────────────────────
      final hojaOC = excel['Resumen por O-C'];
      final encOC = [
        'O/C',
        'Estilo',
        'Operación',
        'Capturadas',
        'Total OC',
        'Disponibles',
      ];
      for (var i = 0; i < encOC.length; i++) {
        final cell = hojaOC.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(encOC[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#0F3460'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      final Map<String, int> resumenOC = {};
      for (final r in registros) {
        final clave =
            '${_numeroOC(r.ordenCorteId)}|${_estiloOC(r.ordenCorteId)}|${r.operacion}|${r.ordenCorteId}';
        resumenOC[clave] = (resumenOC[clave] ?? 0) + r.piezas;
      }

      var filaOC = 1;
      resumenOC.forEach((clave, capturadas) {
        final partes = clave.split('|');
        final ordenId = int.tryParse(partes[3]) ?? 0;
        final totalOC = _ordenes
            .firstWhere(
              (o) => o.id == ordenId,
              orElse: () => OrdenCorte(
                numeroOC: '',
                estilo: '',
                totalPiezas: 0,
                semana: '',
              ),
            )
            .totalPiezas;
        final disponibles = totalOC - capturadas;
        final datos = [
          partes[0],
          partes[1],
          partes[2],
          capturadas.toString(),
          totalOC.toString(),
          disponibles.toString(),
        ];
        for (var j = 0; j < datos.length; j++) {
          hojaOC
              .cell(
                CellIndex.indexByColumnRow(columnIndex: j, rowIndex: filaOC),
              )
              .value = TextCellValue(
            datos[j],
          );
        }
        filaOC++;
      });

      // ── Guardar y compartir ───────────────────────────
      final bytes = excel.encode()!;
      final dir = await getApplicationDocumentsDirectory();
      final ahora = DateTime.now();
      final nombreArchivo =
          'produccion_${ahora.day}-${ahora.month}-${ahora.year}.xlsx';
      final archivo = File('${dir.path}/$nombreArchivo');
      await archivo.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(archivo.path)],
        subject: 'Reporte de Producción Persatex',
        text: 'Reporte generado el ${ahora.day}/${ahora.month}/${ahora.year}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error al exportar: $e')));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  void dispose() {
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _registrosFiltrados;
    final totalPiezas = filtrados.fold(0, (sum, r) => sum + r.piezas);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Exportar a Excel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Filtro por rango de fechas ─────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rango de fechas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inicioCtrl,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Desde',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF0F3460),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: Colors.white54,
                              ),
                              onPressed: () => _seleccionarFecha(true),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _finCtrl,
                          readOnly: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Hasta',
                            labelStyle: const TextStyle(color: Colors.white54),
                            filled: true,
                            fillColor: const Color(0xFF0F3460),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.calendar_today,
                                color: Colors.white54,
                              ),
                              onPressed: () => _seleccionarFecha(false),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _fechaInicio = null;
                        _fechaFin = null;
                        _inicioCtrl.clear();
                        _finCtrl.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white54,
                      size: 16,
                    ),
                    label: const Text(
                      'Ver todos',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Resumen ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _resumenItem('Registros', '${filtrados.length}'),
                  _resumenItem('Total piezas', '$totalPiezas'),
                  _resumenItem(
                    'Operarios',
                    '${filtrados.map((r) => r.operarioId).toSet().length}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Info hojas ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'El archivo Excel incluye:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoHoja('📋', 'Hoja 1', 'Detalle completo de registros'),
                  _infoHoja('👤', 'Hoja 2', 'Resumen por operario y operación'),
                  _infoHoja('📦', 'Hoja 3', 'Avance por O/C y operación'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Botón exportar ────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4332),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _exportando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.file_download, color: Colors.white),
                label: Text(
                  _exportando ? 'Generando...' : 'Exportar y Compartir',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _exportando ? null : _exportarExcel,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _resumenItem(String label, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _infoHoja(String emoji, String hoja, String descripcion) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Text(
            '$hoja: ',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              descripcion,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
