import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/chat/chat_provider.dart';
import 'assistants_screen.dart';
import 'chat_screen.dart';
import '../../navigation/app_navigator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:shimmer/shimmer.dart';
import '../../ads/remote_config_service.dart';
import '../../ads/ad_manager.dart';
import '../../main.dart'; // To access global routeObserver

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> with RouteAware {
  final ChatProvider _chatProvider = ChatProvider();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;
  
  bool _showAd = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _initBannerAd();
  }

  Future<void> _initBannerAd() async {
    final adId = RemoteConfigService.getCollapsiveBannerAdId();

    // 🛡️ GATEKEEPER: Centralized control
    if (!RemoteConfigService.shouldShowAdsGlobally() || !RemoteConfigService.shouldShowAd(adId)) {
      setState(() {
        _showAd = false;
      });
      return;
    }

    setState(() {
      _showAd = true;
    });

    // Fresh load every time we enter the screen via initState
    AdsManager.instance.refreshCollapsibleBannerAd();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // When returning to this screen from another screen
    debugPrint("🔄 Returning to ChatHistoryScreen: Refreshing ad...");
    AdsManager.instance.refreshCollapsibleBannerAd();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final sessions = await _chatProvider.getChatHistorySessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSession(String assistantId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete History?'),
        content: Text('Are you sure you want to delete all messages for $assistantId?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatProvider.clearChat(assistantId);
      _loadSessions(); // Refresh list
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chat History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _sessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        itemBuilder: (context, index) {
                          final session = _sessions[index];
                          final assistantId = session['assistant_id'] as String;
                          final lastMsg = session['content'] as String;
                          final timestamp = DateTime.parse(session['timestamp'] as String);
                          
                          return _buildSessionTile(assistantId, lastMsg, timestamp);
                        },
                      ),
          ),
          if (_showAd)
            ValueListenableBuilder<BannerAd?>(
              valueListenable: AdsManager.instance.collapsibleBannerAd,
              builder: (context, banner, _) {
                final height = (banner != null) 
                    ? banner.size.height.toDouble() 
                    : 60.0;
                
                return SizedBox(
                  height: height,
                  width: double.infinity,
                  child: banner != null 
                      ? AdWidget(ad: banner) 
                      : _buildAdShimmer(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 60, // Smashed up to 60 for safe adaptive height placeholder
        width: double.infinity,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No chat history yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(String assistantId, String lastMsg, DateTime timestamp) {
    String? imageUrl;
    try {
      imageUrl = AssistantsScreen.assistants.firstWhere((a) => a.name == assistantId).imageUrl;
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[100],
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
        ),
        title: Text(
          assistantId,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, hh:mm a').format(timestamp),
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.red[300], size: 22),
          onPressed: () => _deleteSession(assistantId),
          tooltip: 'Delete conversation',
        ),
        onTap: () {
          try {
            final assistant = AssistantsScreen.assistants.firstWhere(
              (a) => a.name == assistantId,
            );
            AppNavigator.push(context, ChatScreen(assistant: assistant));
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Assistant profile not found.')),
            );
          }
        },
      ),
    );
  }
}
