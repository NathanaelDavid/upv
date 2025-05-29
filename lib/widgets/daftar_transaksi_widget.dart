// lib/widgets/daftar_transaksi_widget.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_models.dart'; // Sesuaikan path jika perlu

class DaftarTransaksiWidget extends StatelessWidget {
  final List<TransaksiPublic> transaksiList;
  final Function(TransaksiPublic transaksi) onEdit;
  final Function(String id, String deskripsi) onDelete;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: "id_ID", symbol: 'Rp ', decimalDigits: 0);
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

  DaftarTransaksiWidget({
    super.key,
    required this.transaksiList,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'Daftar Transaksi (${transaksiList.length})',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: transaksiList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Belum ada data transaksi.',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('daftarTransaksiListView'),
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding:
                      const EdgeInsets.only(bottom: 16.0, left: 8, right: 8),
                  itemCount: transaksiList.length,
                  itemBuilder: (context, index) {
                    final transaksi = transaksiList[index];
                    final bool isBeli =
                        transaksi.kodeTransaksi.toLowerCase() == 'beli';
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 6.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        leading: CircleAvatar(
                          backgroundColor: isBeli
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          child: Icon(
                            isBeli
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isBeli
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                        title: Text(
                          '${transaksi.kodeTransaksi.toUpperCase()} ${transaksi.kodeMataUang.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Tgl: ${DateFormat('dd MMM yy, HH:mm', 'id_ID').format(transaksi.timestamp.toDate())}'),
                            Text(
                                'Jumlah: ${_numberFormatter.format(transaksi.jumlahBarang)} ${transaksi.kodeMataUang.toUpperCase()} @ ${_currencyFormatter.format(transaksi.harga)}'),
                            Text(
                                'Nominal: ${_currencyFormatter.format(transaksi.totalNominal)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          tooltip: "Opsi Lain",
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit(transaksi);
                            } else if (value == 'delete') {
                              onDelete(transaksi.id,
                                  '${transaksi.kodeTransaksi.toUpperCase()} ${transaksi.kodeMataUang.toUpperCase()}');
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit_outlined),
                                title: Text('Edit'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete_sweep_outlined,
                                    color: Colors.redAccent),
                                title: Text('Hapus',
                                    style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => onEdit(transaksi),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
