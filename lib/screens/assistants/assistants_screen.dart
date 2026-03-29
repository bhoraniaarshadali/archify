import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../navigation/app_navigator.dart';
import '../../widgets/daily_credit_badge.dart';
import 'chat_screen.dart';
import 'history_screen.dart';

class Assistant {
  final String name;
  final String description;
  final String imageUrl;
  final String welcomeMessage;
  final List<String> suggestions;

  Assistant({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.welcomeMessage,
    required this.suggestions,
  });
}

class AssistantsScreen extends StatefulWidget {
  const AssistantsScreen({super.key});

  /// Dedicated global expert for "Ask Anything" flow
  static final Assistant generalExpert = Assistant(
    name: 'AI Home Decor Expert',
    description: 'Your universal design and decor assistant',
    imageUrl: 'https://images.unsplash.com/photo-1675426513962-1db7e4c707c3?q=80&w=256&h=256&fit=crop',
    welcomeMessage: "Hi! I'm your AI Home Decor Expert. I can help with any design questions you have.",
    suggestions: ['Latest decor trends?', 'Modern lighting ideas?'],
  );

  static final List<Assistant> assistants = [
    generalExpert,
    Assistant(
      name: 'House Designer',
      description: 'Generate suitable home decoration plans',
      imageUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=256&h=256&fit=crop',
      welcomeMessage: "I'm your dedicated AI house design assistant. I provide cost-effective design ideas that balance aesthetics and practicality, helping you avoid common renovation pitfalls.",
      suggestions: [
        'How to maintain a minimalist home?',
        'What home styles are timeless?',
      ],
    ),
    Assistant(
      name: 'Gardener',
      description: 'Specializes in landscape design',
      imageUrl: 'https://images.unsplash.com/photo-1595152772835-219674b2a8a6?q=80&w=256&h=256&fit=crop',
      welcomeMessage: "I'm your dedicated Gardening AI Assistant. I help with all your gardening needs—from beginner basics to advanced care tips.",
      suggestions: [
        '10 potted plants for beginners?',
        'How to design a vertical garden?',
      ],
    ),
    Assistant(
      name: 'Outdoor Space Designer',
      description: 'Specialized in building facade design',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=256&h=256&fit=crop',
      welcomeMessage: "I'm your Outdoor Space Designer. I can help you revamp your building's exterior and create stunning landscapes.",
      suggestions: [
        'Best materials for a modern facade?',
        'Urban garden design tips?',
      ],
    ),
    Assistant(
      name: 'Pet Care Partner',
      description: 'Helps avoid common pitfalls in pet care',
      imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=256&h=256&fit=crop',
      welcomeMessage: "Hi! I'm your Pet Care Partner. I'm here to help you provide the best care for your furry friends.",
      suggestions: [
        'What to feed a new puppy?',
        'How to keep pets cool in summer?',
      ],
    ),
    Assistant(
      name: 'Renovation Craftsman',
      description: 'Learn basic construction knowledge',
      imageUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=256&h=256&fit=crop',
      welcomeMessage: "I'm the Renovation Craftsman. Ask me anything about construction techniques, materials, or DIY repairs.",
      suggestions: [
        'Painting tools for beginners?',
        'How to fix a leaking faucet?',
      ],
    ),
  ];

  @override
  State<AssistantsScreen> createState() => _AssistantsScreenState();
}

class _AssistantsScreenState extends State<AssistantsScreen> {
  final TextEditingController _questionController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;
    
    debugPrint('AssistantsScreen: Submitting question: $text');
    
    _questionController.clear();
    try {
      AppNavigator.push(
        context, 
        ChatScreen(
          assistant: AssistantsScreen.generalExpert,
          initialMessage: text,
        ),
      );
    } catch (e) {
      debugPrint('AssistantsScreen: Error in _submitQuestion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.history, color: Colors.black),
          onPressed: () => AppNavigator.push(context, const ChatHistoryScreen()),
        ),
        centerTitle: true,
        title: const Text(
          'Assistants',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          const Center(child: DailyCreditBadge(themeColor: Colors.black)),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'AI Chatbot',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildAskAnythingBar(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Assistants',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 32,
                childAspectRatio: 0.75,
              ),
              itemCount: AssistantsScreen.assistants.length - 1,
              itemBuilder: (context, index) {
                // Skip the first assistant (General Expert) in the grid as it has its own search bar
                return _buildAssistantCard(AssistantsScreen.assistants[index + 1]);
              },
            ),
            const SizedBox(height: 120), // Bottom nav space
          ],
        ),
      ),
    );
  }

  Widget _buildAskAnythingBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 8),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              onSubmitted: (_) => _submitQuestion(),
              decoration: const InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D33),
              borderRadius: BorderRadius.circular(22),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _submitQuestion,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantCard(Assistant assistant) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 45, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assistant.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  assistant.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    AppNavigator.push(context, ChatScreen(assistant: assistant));
                  },
                  icon: const Icon(CupertinoIcons.chat_bubble_fill, size: 16),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D33),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -25,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(assistant.imageUrl),
              backgroundColor: Colors.grey[200],
            ),
          ),
        ),
      ],
    );
  }
}
