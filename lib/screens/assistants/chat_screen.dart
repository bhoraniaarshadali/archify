import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'assistants_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../models/chat_message.dart';
import '../../services/chat/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final Assistant assistant;
  final String? initialMessage;

  const ChatScreen({
    super.key, 
    required this.assistant,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatProvider _chatProvider = ChatProvider();
  int? _activeMessageIndex;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _initAndSendInitial();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _initAndSendInitial() async {
    final assistantName = widget.assistant.name;
    debugPrint('[ChatScreen] Initializing for assistant: $assistantName');
    
    // 1. Initialize the chat session (load from DB or create new)
    await _chatProvider.initChat(widget.assistant);
    
    // Wait a tiny bit for the provider's internal state to settle
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (!mounted) return;
    _chatProvider.addListener(_onProviderUpdate);

    // 2. Auto-scroll to bottom immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(immediate: true);
    });

    // 3. Handle initial message from 'Ask anything'
    final initialMessage = widget.initialMessage;
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      debugPrint('[ChatScreen] Processing initial message: $initialMessage');
      
      // Safety check: ensure the provider actually has this assistant's list ready
      int retryCount = 0;
      while (_chatProvider.getMessages(assistantName).isEmpty && retryCount < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retryCount++;
        debugPrint('[ChatScreen] Waiting for provider list to ready (Attempt $retryCount)');
      }

      if (mounted) {
        debugPrint('[ChatScreen] Sending message now...');
        await _chatProvider.sendMessage(assistantName, initialMessage.trim());
        debugPrint('[ChatScreen] Message sent successfully.');
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _chatProvider.removeListener(_onProviderUpdate);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final bool show = _scrollController.position.pixels < 
                        (_scrollController.position.maxScrollExtent - 300);
      if (show != _showScrollToBottom) {
        setState(() => _showScrollToBottom = show);
      }
    }
  }

  void _onProviderUpdate() {
    if (mounted) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom({bool immediate = false}) {
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate || _chatProvider.isStreaming) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    _chatProvider.sendMessage(widget.assistant.name, text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.assistant.imageUrl),
            ),
            const SizedBox(width: 12),
            Text(
              widget.assistant.name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _confirmClearHistory(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _showScrollToBottom
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: SizedBox(
                width: 38,
                height: 38,
                child: FloatingActionButton(
                  onPressed: () => _scrollToBottom(),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF2D2D33),
                    size: 24,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListenableBuilder(
        listenable: _chatProvider,
        builder: (context, _) {
          final messages = _chatProvider.getMessages(widget.assistant.name)
              .where((m) => m.role != 'developer')
              .toList();

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message, index);
                  },
                ),
              ),
              if (_chatProvider.isStreaming)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                    ),
                  ),
                ),
              _buildSuggestionChips(),
              _buildInputArea(),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat?'),
        content: const Text('This will delete all messages for this assistant.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              _chatProvider.clearChat(widget.assistant.name);
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    if (message.isMe) {
      final bool isSelected = _activeMessageIndex == index;
      return Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _activeMessageIndex = isSelected ? null : index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2D33),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: InkWell(
                  onTap: () => _copyMessage(message.text),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Assistant message (ChatGPT style: No box, avatar on left)
    final messages = _chatProvider.getMessages(widget.assistant.name);
    final isLast = messages.isNotEmpty && messages.last == message;
    final isStreamingCurrently = isLast && _chatProvider.isStreaming;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFF2F3F7),
            backgroundImage: NetworkImage(widget.assistant.imageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((message.reasoning ?? '').isNotEmpty)
                  _buildReasoningBox(message.reasoning!),
                
                if (message.isThinking && message.text.isEmpty && (message.reasoning ?? '').isEmpty)
                  _buildThinkingIndicator()
                else if (message.text.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: message.text + (isStreamingCurrently ? ' ●' : ''),
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            height: 1.6, // Increased height for better readability
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 2),
                          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.8),
                          h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          code: TextStyle(
                            backgroundColor: Colors.grey[100],
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          listBullet: const TextStyle(color: Colors.black87),
                        ),
                      ),
                      if (!isStreamingCurrently)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              _buildActionButton(
                                icon: Icons.copy_rounded,
                                label: 'Copy',
                                onTap: () => _copyMessage(message.text),
                              ),
                              const SizedBox(width: 16),
                              _buildActionButton(
                                icon: Icons.share_rounded,
                                label: 'Share',
                                onTap: () => _shareMessage(message.text),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Text copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 1),
          width: 200,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _shareMessage(String text) {
    Share.share(text);
  }

  Widget _buildReasoningBox(String reasoning) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.withOpacity(0.3), width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THOUGHT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reasoning,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            'Thinking...',
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: widget.assistant.suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ActionChip(
              backgroundColor: const Color(0xFFF2F3F7),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              label: Text(
                widget.assistant.suggestions[index],
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
              onPressed: _chatProvider.isStreaming 
                ? null 
                : () => _chatProvider.sendMessage(widget.assistant.name, widget.assistant.suggestions[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                enabled: !_chatProvider.isStreaming,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: _chatProvider.isStreaming ? Colors.grey : const Color(0xFF2D2D33),
            child: IconButton(
              icon: Icon(
                _chatProvider.isStreaming ? Icons.hourglass_bottom : Icons.send,
                color: Colors.white,
                size: 18,
              ),
              onPressed: _chatProvider.isStreaming ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
