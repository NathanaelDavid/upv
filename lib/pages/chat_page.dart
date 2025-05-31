import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/chat_widget.dart'; // Pastikan path import ini benar
import '../util/chat_service.dart'; // Pastikan path import ini benar
import '../models/chat_models.dart'; // Pastikan path import ini benar

class ChatPage extends StatefulWidget {
  final String? userRole;

  const ChatPage({super.key, required this.userRole});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatService _chatService;
  List<ChatPublic> _chats = [];
  ChatPublic? _selectedChat;
  Timer? _pollingTimer;
  bool _isLoadingChats = true; // Untuk loading awal daftar chat
  String? _errorMessage;

  // Breakpoint untuk beralih antara layout satu kolom dan dua kolom
  static const double _breakpoint = 720.0;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(widget.userRole);
    _loadChats();

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        // Hanya muat ulang jika widget masih ada di tree
        _loadChats(isPolling: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChats({bool isPolling = false}) async {
    if (!isPolling && mounted) {
      // Hanya set isLoadingChats jika bukan polling atau jika ini load pertama
      setState(() {
        _isLoadingChats = true;
        _errorMessage = null;
      });
    }
    try {
      final chats = await _chatService.getChats();
      if (!mounted) return;

      setState(() {
        _chats = chats;
        // Update _selectedChat dengan instance baru dari daftar chats yang diperbarui
        // atau set ke null jika chat yang dipilih sudah tidak ada.
        if (_selectedChat != null) {
          final currentSelectedId = _selectedChat!.id;
          try {
            _selectedChat =
                chats.firstWhere((chat) => chat.id == currentSelectedId);
          } catch (e) {
            _selectedChat = null; // Chat tidak ditemukan, mungkin sudah dihapus
          }
        }
        _isLoadingChats = false; // Selesai loading
      });
    } catch (e) {
      print("Error memuat chats: $e");
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat daftar chat.";
          _isLoadingChats = false;
        });
      }
    }
  }

  void _handleChatTap(ChatPublic chat) {
    setState(() {
      _selectedChat = chat;
    });
  }

  Future<void> _sendMessage(String message) async {
    if (_selectedChat != null) {
      // Optimistic update (opsional, bisa langsung _loadChats)
      // final newMessage = Message(id: 'temp', text: message, sender: widget.userRole ?? 'user', timestamp: Timestamp.now());
      // setState(() {
      //   _selectedChat!.messages.add(newMessage);
      // });
      try {
        await _chatService.sendMessage(_selectedChat!.id, message);
        await _loadChats(
            isPolling: true); // Muat ulang chat setelah mengirim pesan
      } catch (e) {
        print("Error mengirim pesan: $e");
        // Handle error, mungkin tampilkan snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    "Gagal mengirim pesan: ${e.toString().substring(0, 30)}..."),
                backgroundColor: Colors.red),
          );
          // Revert optimistic update jika ada
          // _loadChats();
        }
      }
    }
  }

  Widget _buildChatList() {
    if (_isLoadingChats && _chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null && _chats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 8),
              ElevatedButton(
                  onPressed: () => _loadChats(), child: const Text("Coba Lagi"))
            ],
          ),
        ),
      );
    }
    if (_chats.isEmpty) {
      return const Center(child: Text('Tidak ada percakapan tersedia.'));
    }

    return Container(
      color:
          const Color.fromARGB(255, 245, 244, 255), // Warna latar daftar chat
      child: ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          final isSelected = _selectedChat?.id == chat.id;
          final lastMessage =
              chat.messages.isNotEmpty ? chat.messages.last : null;

          return ListTile(
            selected: isSelected,
            selectedTileColor: Theme.of(context)
                .primaryColor
                .withOpacity(0.15), // Warna item terpilih
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_outline), // Ikon lebih generik
            ),
            title: Text(chat.name,
                style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(
              lastMessage?.text ?? 'Belum ada pesan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: lastMessage != null
                ? Text(
                    // Format waktu pesan terakhir (opsional)
                    // DateFormat.Hm().format(lastMessage.timestamp.toDate()),
                    '', // Atau biarkan kosong jika tidak perlu timestamp di list
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  )
                : null,
            onTap: () => _handleChatTap(chat),
          );
        },
      ),
    );
  }

  Widget _buildChatDetail(ChatPublic chat) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white, // Warna latar detail chat
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul chat detail tidak lagi diperlukan di sini karena sudah ada di AppBar
          // Text(
          //   'Chat dengan ${chat.name}',
          //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: 10),
          Expanded(
            child: ChatWidget(
              // Asumsi ChatWidget sudah ada dan berfungsi
              chat: chat,
              // `username` di sini sepertinya merujuk pada nama partner chat, bukan user saat ini.
              // Jika `ChatWidget` perlu tahu siapa user saat ini, Anda mungkin perlu meneruskan `widget.userRole`
              // atau ID user saat ini.
              username: chat.name,
              onSendMessage: (message) async {
                await _sendMessage(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(bool isNarrowScreen) {
    if (isNarrowScreen) {
      return _selectedChat == null ? 'Daftar Chat' : _selectedChat!.name;
    } else {
      // Untuk layar lebar, judul bisa lebih umum karena kedua panel terlihat
      return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah layar sempit berdasarkan breakpoint
    final bool isNarrowScreen = MediaQuery.of(context).size.width < _breakpoint;
    // Tentukan apakah sebuah chat dipilih DAN layar sempit (untuk tombol kembali)
    final bool showBackButtonOnNarrow = isNarrowScreen && _selectedChat != null;

    return Scaffold(
      appBar: AppBar(
        leading: showBackButtonOnNarrow
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedChat = null; // Kembali ke daftar chat
                  });
                },
              )
            : null, // Tidak ada tombol leading jika di layar lebar atau di daftar chat layar sempit
        title: Text(_getAppBarTitle(isNarrowScreen)),
        centerTitle: true,
        // Warna AppBar akan mengikuti tema global aplikasi Anda
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > _breakpoint) {
            // Layout Layar Lebar: Dua kolom (Daftar Chat + Detail Chat)
            return Row(
              children: [
                Expanded(
                  flex: 2, // Lebar relatif untuk daftar chat
                  child: _buildChatList(),
                ),
                const VerticalDivider(width: 1, thickness: 1), // Pemisah visual
                Expanded(
                  flex: 3, // Lebar relatif untuk detail chat
                  child: _selectedChat == null
                      ? const Center(
                          child: Text(
                            'Pilih chat untuk memulai percakapan',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : _buildChatDetail(_selectedChat!),
                ),
              ],
            );
          } else {
            // Layout Layar Sempit: Satu kolom (Daftar Chat ATAU Detail Chat)
            if (_selectedChat == null) {
              return _buildChatList(); // Tampilkan daftar chat jika tidak ada yang dipilih
            } else {
              return _buildChatDetail(
                  _selectedChat!); // Tampilkan detail chat jika ada yang dipilih
            }
          }
        },
      ),
    );
  }
}
