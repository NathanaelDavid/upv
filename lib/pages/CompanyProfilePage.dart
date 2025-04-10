import 'package:flutter/material.dart';
import '../widgets/currency_widget.dart';

class CompanyProfilePage extends StatelessWidget {
  final List<String> bannerImages = [
    'gambar/image_1.jpg',
    'gambar/image_2.jpg',
    'gambar/image_3.jpg',
    'gambar/image_4.jpg',
  ];

  CompanyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 244, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 48, 37, 201),
        title: const Text('Profil Perusahaan',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 200.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bannerImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: Image.asset(
                          bannerImages[index],
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.8,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
              LayoutBuilder(
                builder: (context, constraints) {
                  return constraints.maxWidth > 600
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _buildCompanyInfo(),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              flex: 2,
                              child: CurrencyWidget(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCompanyInfo(),
                            const SizedBox(height: 16.0),
                            CurrencyWidget(),
                          ],
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.account_balance,
            size: 50,
            color: Color.fromARGB(255, 48, 37, 201),
          ),
        ),
        const SizedBox(height: 16.0),
        const Text(
          'Untung Prima Valasindo',
          style: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 39, 39, 39),
          ),
        ),
        const SizedBox(height: 8.0),
        const Text(
          'Solusi Terbaik untuk transaksi mata uang asing',
          style: TextStyle(
            fontSize: 16.0,
            color: Color.fromARGB(255, 39, 39, 39),
          ),
        ),
        const SizedBox(height: 20.0),
        Card(
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Tentang Kami',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 48, 37, 201),
                  ),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Kami adalah perusahaan yang bergerak di bidang valuta asing, menyediakan layanan terbaik untuk kebutuhan transaksi mata uang Anda.',
                  style: TextStyle(
                      fontSize: 16.0, color: Color.fromARGB(255, 39, 39, 39)),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Visi:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 48, 37, 201),
                  ),
                ),
                Text(
                  'Menjadi penyedia layanan valuta asing terkemuka di Indonesia.',
                  style: TextStyle(
                      fontSize: 16.0, color: Color.fromARGB(255, 39, 39, 39)),
                ),
                SizedBox(height: 16.0),
                Text(
                  'Misi:',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 48, 37, 201),
                  ),
                ),
                Text(
                  '1. Memberikan layanan terbaik kepada pelanggan.\n'
                  '2. Menyediakan informasi terkini mengenai kurs mata uang.\n'
                  '3. Membangun kepercayaan dan hubungan jangka panjang dengan pelanggan.',
                  style: TextStyle(
                      fontSize: 16.0, color: Color.fromARGB(255, 39, 39, 39)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
