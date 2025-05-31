// lib/widgets/daftar_transaksi_invoice.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaksi_models.dart'; // Sesuaikan path jika perlu

class DaftarTransaksiInvoice extends StatelessWidget {
  final List<TransaksiPublic> transaksiList;
  final Function(TransaksiPublic transaksi, bool isSelected) onSelect;
  final Set<String> selectedTransaksiIds;

  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: "id_ID", symbol: 'Rp ', decimalDigits: 0);
  final NumberFormat _numberFormatter = NumberFormat.decimalPattern('id_ID');

  DaftarTransaksiInvoice({
    // Ubah nama konstruktor agar sesuai dengan nama kelas
    super.key,
    required this.transaksiList,
    required this.onSelect,
    required this.selectedTransaksiIds,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
          child: Text(
            'Pilih Transaksi (${selectedTransaksiIds.length} dipilih)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
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
                        const Icon(Icons.list_alt_outlined,
                            size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text('Tidak ada transaksi yang sesuai untuk dipilih.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  key: const ValueKey('daftarTransaksiInvoiceListView'),
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(
                      bottom: 70.0, // Padding untuk FAB
                      left: 8,
                      right: 8),
                  itemCount: transaksiList.length,
                  itemBuilder: (context, index) {
                    final transaksi = transaksiList[index];
                    // final bool isBeli = transaksi.kodeTransaksi.toLowerCase() == 'beli'; // Tidak digunakan di UI ListTile ini
                    final bool isSelected =
                        selectedTransaksiIds.contains(transaksi.id);

                    return Card(
                      elevation: 1.5,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        leading: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            onSelect(transaksi, value ?? false);
                          },
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        title: Text(
                          '${transaksi.kodeTransaksi.toUpperCase()} ${transaksi.kodeMataUang.toUpperCase()}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                                'Tgl: ${DateFormat('dd MMM yy, HH:mm', 'id_ID').format(transaksi.timestamp.toDate())}',
                                style: const TextStyle(fontSize: 12.5)),
                            Text(
                                'Jml: ${_numberFormatter.format(transaksi.jumlahBarang)} ${transaksi.kodeMataUang.toUpperCase()} @ ${_currencyFormatter.format(transaksi.harga)}',
                                style: const TextStyle(fontSize: 12.5)),
                            Text(
                                'Total: ${_currencyFormatter.format(transaksi.totalNominal)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13)),
                          ],
                        ),
                        onTap: () {
                          onSelect(transaksi, !isSelected);
                        },
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
