import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late WebSocketChannel _channel;
  bool _isConnected = false;
  bool _isLoading = true;

  // WebSocket configuration
  static const String WS_BASE_URL = 'ws://your-spring-boot-server:8080';
  static const String CHAT_WS_ENDPOINT = '$WS_BASE_URL/ws/chat-support';

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
    
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hi! I'm your virtual assistant. How can I help you today?",
      isUser: false,
      time: _getCurrentTime(),
    ));
  }

  Future<void> _connectToWebSocket() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      
      // For now, use a mock connection since we don't have the actual server
      // In production, replace with actual WebSocket connection:
      // _channel = IOWebSocketChannel.connect('$CHAT_WS_ENDPOINT?token=$accessToken');
      
      // Simulate connection for demo purposes
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isConnected = true;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
      _showConnectionError('Failed to connect: $e');
    }
  }

  void _handleIncomingMessage(String message) {
    try {
      final data = json.decode(message);
      
      setState(() {
        _messages.add(ChatMessage(
          text: data['content'],
          isUser: false,
          time: _getCurrentTime(),
        ));
      });
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final messageText = _messageController.text.trim();
    
    // Add user message to UI immediately
    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        isUser: true,
        time: _getCurrentTime(),
      ));
      _messageController.clear();
    });

    // Simulate AI response (replace with actual WebSocket call)
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add(ChatMessage(
          text: "I understand your concern about '$messageText'. Let me help you with that.",
          isUser: false,
          time: _getCurrentTime(),
        ));
      });
    });
  }

  void _sendQuickOption(String option) {
    setState(() {
      _messages.add(ChatMessage(
        text: option,
        isUser: true,
        time: _getCurrentTime(),
      ));
    });

    // Simulate AI response for quick options
    Future.delayed(const Duration(seconds: 1), () {
      String response;
      switch (option) {
        case 'Technical Problems':
          response = "I can help with technical issues. Please describe the problem in detail.";
          break;
        case 'Passenger Issues':
          response = "For passenger-related concerns, please provide more details about the situation.";
          break;
        case 'Emergency Services':
          response = "This appears to be an emergency. I'm connecting you to our emergency support team.";
          break;
        case 'Route Information':
          response = "I can help with route information. Which route are you inquiring about?";
          break;
        case 'Payment Issues':
          response = "For payment issues, please provide your transaction ID or describe the problem.";
          break;
        case 'Account Help':
          response = "I can assist with account-related queries. What specific help do you need?";
          break;
        default:
          response = "Thank you for selecting '$option'. How can I assist you with this?";
      }
      
      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          time: _getCurrentTime(),
        ));
      });
    });
  }

  void _showConnectionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    // Close WebSocket connection if it exists
    try {
      _channel.sink.close();
    } catch (e) {
      // Ignore if channel is not initialized
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Support'),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.circle : Icons.offline_bolt,
              color: _isConnected ? Colors.green : Colors.red,
              size: 16,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: _isConnected ? Colors.green[50] : Colors.red[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.circle,
                  color: _isConnected ? Colors.green : Colors.red,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
          
          // Quick options
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Options',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    QuickOptionChip(text: 'Technical Problems', onTap: _sendQuickOption),
                    QuickOptionChip(text: 'Passenger Issues', onTap: _sendQuickOption),
                    QuickOptionChip(text: 'Emergency Services', onTap: _sendQuickOption),
                    QuickOptionChip(text: 'Route Information', onTap: _sendQuickOption),
                    QuickOptionChip(text: 'Payment Issues', onTap: _sendQuickOption),
                    QuickOptionChip(text: 'Account Help', onTap: _sendQuickOption),
                  ],
                ),
              ],
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isConnected ? Colors.blue : Colors.grey,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isConnected ? _sendMessage : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser) 
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.support_agent, size: 16, color: Colors.white),
            ),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: message.isUser 
                          ? const Radius.circular(16) 
                          : const Radius.circular(4),
                      bottomRight: message.isUser 
                          ? const Radius.circular(4) 
                          : const Radius.circular(16),
                    ),
                  ),
                  child: Text(message.text),
                ),
                const SizedBox(height: 4),
                Text(
                  message.time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser) 
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
        ],
      ),
    );
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class QuickOptionChip extends StatelessWidget {
  final String text;
  final Function(String) onTap;

  const QuickOptionChip({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: () => onTap(text),
      backgroundColor: Colors.blue[50],
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }
}