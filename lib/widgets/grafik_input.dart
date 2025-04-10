// import 'package:flutter/material.dart';
// import '../util/grafik_service.dart';

// class GrafikInputWidget extends StatefulWidget {
//   final Map<String, dynamic>?
//       grafikData; // Data grafik untuk edit (null jika tambah baru)

//   GrafikInputWidget({this.grafikData});

//   @override
//   _GrafikInputWidgetState createState() => _GrafikInputWidgetState();
// }

// class _GrafikInputWidgetState extends State<GrafikInputWidget> {
//   final GrafikService _grafikService = GrafikService();

//   final TextEditingController _judulController = TextEditingController();
//   final TextEditingController _deskripsiController = TextEditingController();
//   final TextEditingController _nilaiController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     if (widget.grafikData != null) {
//       _judulController.text = widget.grafikData!['judul'] ?? '';
//       _deskripsiController.text = widget.grafikData!['deskripsi'] ?? '';
//       _nilaiController.text = widget.grafikData!['nilai'].toString();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title:
//             Text(widget.grafikData == null ? 'Tambah Grafik' : 'Edit Grafik'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _judulController,
//               decoration: InputDecoration(labelText: 'Judul Grafik'),
//             ),
//             SizedBox(height: 10),
//             TextField(
//               controller: _deskripsiController,
//               decoration: InputDecoration(labelText: 'Deskripsi Grafik'),
//             ),
//             SizedBox(height: 10),
//             TextField(
//               controller: _nilaiController,
//               decoration: InputDecoration(labelText: 'Nilai Grafik'),
//               keyboardType: TextInputType.number,
//             ),
//             SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 ElevatedButton(
//                   onPressed: () => Navigator.of(context).pop(),
//                   child: Text('Batal'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     if (_judulController.text.isEmpty ||
//                         _deskripsiController.text.isEmpty ||
//                         _nilaiController.text.isEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Semua field harus diisi!')),
//                       );
//                       return;
//                     }

//                     final data = {
//                       'judul': _judulController.text,
//                       'deskripsi': _deskripsiController.text,
//                       'nilai': double.tryParse(_nilaiController.text) ?? 0,
//                     };

//                     if (widget.grafikData == null) {
//                       // Tambah data baru
//                       await _grafikService.createGrafik(data);
//                     } else {
//                       // Update data yang ada
//                       await _grafikService.updateGrafik(
//                         widget.grafikData!['id'].toString(),
//                         data,
//                       );
//                     }

//                     Navigator.of(context)
//                         .pop(true); // Kembali ke halaman sebelumnya
//                   },
//                   child: Text(widget.grafikData == null ? 'Tambah' : 'Update'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
