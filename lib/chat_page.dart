import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'services/api_config_service.dart'; // Import ApiConfigService

class ChatPage extends StatefulWidget {
  final String sessionKey;

  const ChatPage({super.key, required this.sessionKey});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late IOWebSocketChannel channel;
  List<String> chatUsers = [];
  String? selectedUser;
  List<Map<String, dynamic>> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Dynamic base URL
  String? _baseUrl;
  bool _isLoadingConfig = true;
  String? _configError;
  IOWebSocketChannel? _channel; // Make channel nullable

  @override
  void initState() {
    super.initState();
    _initializeWebSocket(); // Changed from direct connection
  }

  // Method to initialize WebSocket with dynamic base URL
  Future<void> _initializeWebSocket() async {
    try {
      final apiConfig = ApiConfigService();
      _baseUrl = await apiConfig.getBaseUrl();
      print('✅ ChatPage - Base URL loaded: $_baseUrl');
      
      // Clean URL for WebSocket connection (replace http:// with ws://)
      String wsUrl = _baseUrl!.replaceAll('http://', 'ws://');
      
      setState(() {
        _isLoadingConfig = false;
      });
      
      // Connect to WebSocket
      _connectWebSocket(wsUrl);
      
    } catch (e) {
      print('❌ ChatPage - Failed to load base URL: $e');
      setState(() {
        _configError = 'Failed to load server configuration: $e';
        _isLoadingConfig = false;
      });
    }
  }
  
  void _connectWebSocket(String wsUrl) {
    try {
      _channel = IOWebSocketChannel.connect(wsUrl);
      
      _channel!.sink.add(jsonEncode({"type": "auth", "key": widget.sessionKey}));
      
      _channel!.stream.listen((event) {
        final data = jsonDecode(event);

        switch (data['type']) {
          case 'chatList':
            if (mounted) {
              setState(() => chatUsers = List<String>.from(data['users']));
            }
            break;
          case 'chat':
            if (selectedUser == data['message']['from'] ||
                selectedUser == data['message']['to']) {
              if (mounted) {
                setState(() => messages.add(Map<String, dynamic>.from(data['message'])));
                _scrollToBottom();
              }
            }
            break;
          case 'messages':
            if (mounted) {
              setState(() => messages = List<Map<String, dynamic>>.from(data['messages']));
              _scrollToBottom();
            }
            break;
        }
      }, onError: (error) {
        print('WebSocket error: $error');
        if (mounted) {
          _showAlert("Connection Error", "WebSocket connection failed. Please try again.");
        }
      }, onDone: () {
        print('WebSocket connection closed');
      });
      
    } catch (e) {
      print('WebSocket connection error: $e');
      if (mounted) {
        setState(() {
          _configError = 'Failed to connect to WebSocket server: $e';
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _loadMessages(String user) {
    if (_channel == null) return;
    
    setState(() {
      selectedUser = user;
      messages.clear();
    });
    _channel!.sink.add(jsonEncode({
      "type": "getMessages",
      "with": user,
    }));
  }

  void _sendMessage() {
    if (_channel == null) {
      _showAlert("Connection Error", "Not connected to chat server.");
      return;
    }
    
    final msg = messageController.text.trim();
    if (msg.isEmpty || msg.length > 250 || selectedUser == null) return;

    _channel!.sink.add(jsonEncode({
      "type": "chat",
      "to": selectedUser,
      "message": msg,
    }));

    messageController.clear();
  }

  void _startNewChat() {
    String newUser = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("New Chat", style: TextStyle(color: Colors.white)),
        content: TextField(
          onChanged: (val) => newUser = val,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter username...",
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.purpleAccent)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text("Start", style: TextStyle(color: Colors.purpleAccent)),
            onPressed: () {
              Navigator.pop(context);
              if (newUser.isNotEmpty && mounted) {
                setState(() => selectedUser = newUser);
                messages.clear();
                if (_channel != null) {
                  _channel!.sink.add(jsonEncode({"type": "getMessages", "with": newUser}));
                }
              }
            },
          ),
        ],
      ),
    );
  }
  
  void _showAlert(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron')),
        content: Text(msg, style: const TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Colors.purpleAccent)),
          )
        ],
      ),
    );
  }

  Widget _chatBubble(Map msg) {
    final isMe = msg['fromMe'] == true;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
            colors: [Colors.purpleAccent, Colors.deepPurple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : const LinearGradient(
            colors: [Colors.grey, Colors.black54],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg['from'] ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ),
            Text(msg['message'],
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_channel != null) {
      _channel!.sink.close();
    }
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Loading config state
    if (_isLoadingConfig) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Colors.purpleAccent,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Loading chat configuration...",
                style: TextStyle(color: Colors.white70, fontFamily: 'ShareTechMono'),
              ),
              const SizedBox(height: 10),
              Text(
                "Fetching from GitHub Gist",
                style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'ShareTechMono'),
              ),
            ],
          ),
        ),
      );
    }

    // Error config state
    if (_configError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.purpleAccent.withOpacity(0.3)),
                ),
                child: Icon(Icons.error_outline, color: Colors.purpleAccent, size: 40),
              ),
              const SizedBox(height: 20),
              Text(
                "Configuration Error",
                style: TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron'
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _configError!,
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'ShareTechMono'),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoadingConfig = true;
                    _configError = null;
                  });
                  _initializeWebSocket();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text("RETRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: selectedUser == null ? _buildChatList() : _buildChatScreen(),
    );
  }

  // 🔹 List Chat View
  Widget _buildChatList() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            child: const Text(
              "💬 Chats",
              style: TextStyle(
                fontSize: 18,
                fontFamily: "Orbitron",
                fontWeight: FontWeight.bold,
                color: Colors.purpleAccent,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white, size: 16),
              label: const Text("New Chat", style: TextStyle(color: Colors.white)),
              onPressed: _startNewChat,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: chatUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white.withOpacity(0.3),
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No chats yet",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start a new conversation",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: chatUsers.length,
                    itemBuilder: (context, index) {
                      final user = chatUsers[index];
                      return Card(
                        color: Colors.white10,
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purpleAccent,
                            child: Text(user[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: Text(user,
                              style: const TextStyle(color: Colors.white, fontSize: 13)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: () => _loadMessages(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🔹 Chat Screen View
  Widget _buildChatScreen() {
    return Column(
      children: [
        // Header dengan tombol back
        Container(
          padding: const EdgeInsets.all(14),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.black, Colors.black],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.4), blurRadius: 6)
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    selectedUser = null;
                    messages.clear();
                  });
                },
              ),
              CircleAvatar(
                backgroundColor: Colors.purpleAccent,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Chatting with @$selectedUser",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            ],
          ),
        ),

        // Chat body
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.black],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white.withOpacity(0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No messages yet",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start the conversation",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 12,
                            fontFamily: 'ShareTechMono',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 300),
                        child: _chatBubble(msg),
                      );
                    },
                  ),
          ),
        ),

        // Input pesan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            border: const Border(top: BorderSide(color: Colors.purple, width: 0.4)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 250,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: "Type message...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.purpleAccent,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}