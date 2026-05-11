import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../db/database_helper.dart';
import '../models/orden_corte.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _imagen;
  bool _procesando = false;
  bool _escaneado = false;
  List<_OrdenDetectada> _ordenesDetectadas = [];
  final Set<int> _seleccionadas = {};

  // ── Tomar o seleccionar foto ─────────────────────────
  Future<void> _tomarFoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;

    setState(() {
      _imagen = File(picked.path);
      _procesando = true;
      _escaneado = false;
      _ordenesDetectadas = [];
      _seleccionadas.clear();
    });

    await _escanear(File(picked.path));
  }

  // ── OCR y parseo ─────────────────────────────────────
  Future<void> _escanear(File imagen) async {
    final inputImage = InputImage.fromFile(imagen);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);
      final lineas = result.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      final ordenes = _parsearOrdenes(lineas);

      setState(() {
        _ordenesDetectadas = ordenes;
        _seleccionadas.addAll(List.generate(ordenes.length, (i) => i));
        _procesando = false;
        _escaneado = true;
      });
    } catch (e) {
      setState(() => _procesando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al escanear: $e')));
      }
    } finally {
      recognizer.close();
    }
  }

  // ── Parser de texto OCR ───────────────────────────────
  List<_OrdenDetectada> _parsearOrdenes(List<String> lineas) {
    final ordenes = <_OrdenDetectada>[];
    // Patron: linea con numero de 6 digitos (O/P o O/C) y cantidad
    // Ejemplos reales del documento:
    // "260138  44736  VAXTER SPRING INK  OGGI  891  CABALLERO"
    // "260211  44805  IRON COPPEL SKY CARBON  OGGI  2966  CABALLERO"

    for (final linea in lineas) {
      // Buscar numeros de 5-6 digitos (O/P y O/C)
      final nums = RegExp(r'\b(\d{5,6})\b').allMatches(linea).toList();
      if (nums.length < 2) continue;

      final op = nums[0].group(1) ?? '';
      final oc = nums[1].group(1) ?? '';

      // Buscar cantidad: numero de 2-4 digitos al final o cerca
      final cantMatch = RegExp(r'\b(\d{2,4})\b').allMatches(linea).toList();
      if (cantMatch.isEmpty) continue;

      // La cantidad suele ser el ultimo numero de 2-4 digitos
      // que no sea parte de O/P u O/C
      String cantStr = '';
      for (final m in cantMatch.reversed) {
        final val = m.group(1) ?? '';
        if (val != op && val != oc && val.length <= 4) {
          cantStr = val;
          break;
        }
      }
      if (cantStr.isEmpty) continue;
      final cantidad = int.tryParse(cantStr) ?? 0;
      if (cantidad < 10 || cantidad > 9999) continue;

      // Detectar cliente: OGGI, FRAME, NYDJ, etc.
      String cliente = 'OGGI';
      for (final c in ['OGGI', 'FRAME', 'NYDJ', 'LAST BRAND', 'LEVIS']) {
        if (linea.toUpperCase().contains(c)) {
          cliente = c;
          break;
        }
      }

      // Estilo: texto entre OC y cliente (limpiar)
      String estilo = linea
          .replaceAll(RegExp(r'\b\d{5,6}\b'), '')
          .replaceAll(RegExp(r'\b\d{1,4}\b'), '')
          .replaceAll(
            RegExp(
              r'CABALLERO|DAMA|OGGI|FRAME|NYDJ|LAST BRAND',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      if (estilo.length > 50) estilo = estilo.substring(0, 50);
      if (estilo.isEmpty) estilo = 'SIN ESTILO';

      ordenes.add(
        _OrdenDetectada(
          op: op,
          oc: oc,
          estilo: estilo,
          cliente: cliente,
          cantidad: cantidad,
        ),
      );
    }

    // Eliminar duplicados por O/C
    final vistos = <String>{};
    return ordenes.where((o) => vistos.add(o.oc)).toList();
  }

  // ── Guardar seleccionadas ─────────────────────────────
  Future<void> _guardar() async {
    if (_seleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una orden')),
      );
      return;
    }

    int guardadas = 0;
    for (final i in _seleccionadas) {
      final o = _ordenesDetectadas[i];
      await DatabaseHelper.instance.insertarOrden(
        OrdenCorte(
          numeroOC: o.oc,
          estilo: o.cliente,
          totalPiezas: o.cantidad,
          semana: '',
        ),
      );
      guardadas++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ $guardadas ordenes guardadas correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Escanear Programa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_escaneado && _seleccionadas.isNotEmpty)
            TextButton.icon(
              onPressed: _guardar,
              icon: const Icon(Icons.save, color: Colors.greenAccent),
              label: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Botones camara y galeria
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF533483),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Tomar foto',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _tomarFoto(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3460),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library, color: Colors.white),
                    label: const Text(
                      'Galeria',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => _tomarFoto(ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Imagen tomada
            if (_imagen != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imagen!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            // Procesando
            if (_procesando)
              const Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF533483)),
                  SizedBox(height: 12),
                  Text(
                    'Leyendo documento...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),

            // Resultados
            if (_escaneado) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_ordenesDetectadas.length} ordenes detectadas',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_seleccionadas.length} seleccionadas',
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (_ordenesDetectadas.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16213E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.search_off, color: Colors.white54, size: 40),
                      SizedBox(height: 8),
                      Text(
                        'No se detectaron ordenes.\nIntenta con mejor iluminacion\no acerca mas la camara.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Revisa y corrige los datos antes de guardar:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),

                // Seleccionar/deseleccionar todo
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _seleccionadas.addAll(
                          List.generate(_ordenesDetectadas.length, (i) => i),
                        );
                      }),
                      child: const Text(
                        'Seleccionar todo',
                        style: TextStyle(color: Color(0xFF533483)),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _seleccionadas.clear()),
                      child: const Text(
                        'Deseleccionar todo',
                        style: TextStyle(color: Colors.white38),
                      ),
                    ),
                  ],
                ),

                // Lista de ordenes detectadas
                ...List.generate(_ordenesDetectadas.length, (i) {
                  final o = _ordenesDetectadas[i];
                  final sel = _seleccionadas.contains(i);
                  return _TarjetaOrdenEditable(
                    orden: o,
                    seleccionada: sel,
                    onToggle: () => setState(() {
                      if (sel) {
                        _seleccionadas.remove(i);
                      } else {
                        _seleccionadas.add(i);
                      }
                    }),
                    onChanged: (nueva) {
                      setState(() => _ordenesDetectadas[i] = nueva);
                    },
                  );
                }),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4332),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: Text(
                      'Guardar ${_seleccionadas.length} ordenes',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: _guardar,
                  ),
                ),
              ],
            ],

            // Instrucciones si no hay nada
            if (!_procesando && !_escaneado && _imagen == null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.document_scanner,
                      color: Color(0xFF533483),
                      size: 60,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Como usar el escaner:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _Instruccion(
                      '1',
                      'Toma una foto del programa de produccion',
                    ),
                    _Instruccion(
                      '2',
                      'La app detecta O/P, O/C, cliente y cantidad',
                    ),
                    _Instruccion('3', 'Revisa y corrige los datos detectados'),
                    _Instruccion('4', 'Guarda las ordenes que necesites'),
                    SizedBox(height: 12),
                    Text(
                      'Consejo: buena iluminacion y foto derecha\ndan mejores resultados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
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

// ── Tarjeta editable por orden ────────────────────────────────────────────
class _TarjetaOrdenEditable extends StatefulWidget {
  final _OrdenDetectada orden;
  final bool seleccionada;
  final VoidCallback onToggle;
  final ValueChanged<_OrdenDetectada> onChanged;

  const _TarjetaOrdenEditable({
    required this.orden,
    required this.seleccionada,
    required this.onToggle,
    required this.onChanged,
  });

  @override
  State<_TarjetaOrdenEditable> createState() => _TarjetaOrdenEditableState();
}

class _TarjetaOrdenEditableState extends State<_TarjetaOrdenEditable> {
  late TextEditingController _opCtrl;
  late TextEditingController _ocCtrl;
  late TextEditingController _estiloCtrl;
  late TextEditingController _clienteCtrl;
  late TextEditingController _cantCtrl;
  bool _editando = false;

  @override
  void initState() {
    super.initState();
    _opCtrl = TextEditingController(text: widget.orden.op);
    _ocCtrl = TextEditingController(text: widget.orden.oc);
    _estiloCtrl = TextEditingController(text: widget.orden.estilo);
    _clienteCtrl = TextEditingController(text: widget.orden.cliente);
    _cantCtrl = TextEditingController(text: widget.orden.cantidad.toString());
  }

  @override
  void dispose() {
    _opCtrl.dispose();
    _ocCtrl.dispose();
    _estiloCtrl.dispose();
    _clienteCtrl.dispose();
    _cantCtrl.dispose();
    super.dispose();
  }

  void _guardarEdicion() {
    widget.onChanged(
      _OrdenDetectada(
        op: _opCtrl.text.trim(),
        oc: _ocCtrl.text.trim(),
        estilo: _estiloCtrl.text.trim(),
        cliente: _clienteCtrl.text.trim(),
        cantidad: int.tryParse(_cantCtrl.text) ?? 0,
      ),
    );
    setState(() => _editando = false);
  }

  Widget _fieldEdit(
    TextEditingController ctrl,
    String label, {
    TextInputType tipo = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        keyboardType: tipo,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
          filled: true,
          fillColor: const Color(0xFF0F3460),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.seleccionada
              ? const Color(0xFF533483)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Cabecera
          ListTile(
            leading: Checkbox(
              value: widget.seleccionada,
              onChanged: (_) => widget.onToggle(),
              fillColor: WidgetStateProperty.all(
                widget.seleccionada
                    ? const Color(0xFF533483)
                    : Colors.transparent,
              ),
              side: const BorderSide(color: Colors.white38),
            ),
            title: Text(
              'O/C: ${widget.orden.oc}  —  ${widget.orden.cliente}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            subtitle: Text(
              '${widget.orden.cantidad} pzas  ·  O/P: ${widget.orden.op}',
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            trailing: IconButton(
              icon: Icon(
                _editando ? Icons.check_circle : Icons.edit,
                color: _editando ? Colors.greenAccent : Colors.white38,
                size: 20,
              ),
              onPressed: () {
                if (_editando) {
                  _guardarEdicion();
                } else {
                  setState(() => _editando = true);
                }
              },
            ),
          ),

          // Campos editables
          if (_editando)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _fieldEdit(
                          _opCtrl,
                          'O/P',
                          tipo: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _fieldEdit(
                          _ocCtrl,
                          'O/C',
                          tipo: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  _fieldEdit(_clienteCtrl, 'Cliente (OGGI, FRAME...)'),
                  _fieldEdit(
                    _cantCtrl,
                    'Cantidad de piezas',
                    tipo: TextInputType.number,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Modelo temporal ───────────────────────────────────────────────────────
class _OrdenDetectada {
  final String op;
  final String oc;
  final String estilo;
  final String cliente;
  final int cantidad;

  _OrdenDetectada({
    required this.op,
    required this.oc,
    required this.estilo,
    required this.cliente,
    required this.cantidad,
  });
}

// ── Widget instruccion ────────────────────────────────────────────────────
class _Instruccion extends StatelessWidget {
  final String num;
  final String texto;
  const _Instruccion(this.num, this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF533483),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                num,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
