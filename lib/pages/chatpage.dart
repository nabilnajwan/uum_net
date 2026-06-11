import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, String>> messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // 1. Securely load the API key from your .env file
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('API key is missing!');
    }

    // 2. Initialize the Gemini AI model
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey ?? '',
      // This gives your AI its specific personality for your FYP!
      systemInstruction: Content.system(
        "You are an expert AI assistant built directly into the UUM Network Monitor app. "
        "Your job is to help UUM students understand their internet connection. "
        "Explain things like Ping, Download Speed, Upload Speed, and Signal Strength (dBm) in simple terms. "
        "Keep your answers helpful, friendly, and concise."
      ),
    );
    
    _chatSession = _model.startChat();
    
    // Add an initial greeting from the bot
    messages.add({
      "role": "model",
      "text": "Hello! I am your UUM Network Assistant. Do you have any questions about your network speeds or signal strength?"
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add the user's message to the screen
    setState(() {
      messages.add({"role": "user", "text": text});
      _isLoading = true;
    });
    
    _textController.clear();
    _scrollToBottom();

    try {
      // Send the message to Google Gemini
      final response = await _chatSession.sendMessage(Content.text(text));
      final responseText = response.text;

      if (responseText != null) {
        setState(() {
          messages.add({"role": "model", "text": responseText});
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"role": "model", "text": "Sorry, I couldn't connect to the AI server right now. Error: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Lighter modern background
      appBar: AppBar(
        title: const Text(
          "Network AI Assist", 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Chat bubbles area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isUser = msg["role"] == "user";
                return _buildMessageBubble(msg["text"]!, isUser);
              },
            ),
          ),
          
          // Modern Loading indicator (AI is typing...)
          if (_isLoading)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
                    ]
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.deepPurple),
                      ),
                      const SizedBox(width: 10),
                      Text("AI is typing...", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            
          // Floating Text Input Box
          _buildMessageInput(),
        ],
      ),
    );
  }

  // UI for the individual chat bubbles
  Widget _buildMessageBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // AI Avatar next to model messages
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ]
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Icon(Icons.smart_toy_rounded, size: 20, color: Colors.deepPurple.shade600),
              ),
            ),
          ],
          
          // The Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          
          // Padding to ensure user bubbles don't stretch all the way left
          if (isUser) const SizedBox(width: 40), 
          if (!isUser) const SizedBox(width: 40), 
        ],
      ),
    );
  }

  // UI for the typing area at the bottom
  Widget _buildMessageInput() {
    return Container(
      // Floating margins
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: _textController,
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: "Ask UUM Network AI...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                border: InputBorder.none, // Removes the standard input line
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}