import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/app_colors.dart';
import '../controllers/chatbot_controller.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatbotController controller = Get.put(ChatbotController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Obx(() => Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        controller.isOnline.value ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productivity Assistant',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      controller.isOnline.value ? 'Online' : 'Connecting...',
                      style: TextStyle(
                        color: controller.isOnline.value
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            )),
        actions: [
          IconButton(
            onPressed: controller.clearChat,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            tooltip: 'Clear Chat',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) => controller.handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Help'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'feedback',
                child: Row(
                  children: [
                    Icon(Icons.feedback, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text('Feedback'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Actions Bar
          _buildQuickActionsBar(controller),

          // Chat Messages
          Expanded(
            child: Obx(() => _buildChatList(controller)),
          ),

          // Typing Indicator
          Obx(() => controller.isTyping.value
              ? _buildTypingIndicator()
              : const SizedBox.shrink()),

          // Input Area
          _buildInputArea(controller),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar(ChatbotController controller) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildQuickActionChip(
            'My Schedules',
            Icons.schedule,
            Colors.blue,
            () => controller.askAboutSchedules(),
          ),
          _buildQuickActionChip(
            'Add Schedule',
            Icons.add_circle,
            Colors.green,
            () => controller.helpCreateSchedule(),
          ),
          _buildQuickActionChip(
            'Productivity Tips',
            Icons.lightbulb,
            Colors.orange,
            () => controller.getProductivityTips(),
          ),
          _buildQuickActionChip(
            'App Statistics',
            Icons.analytics,
            Colors.purple,
            () => controller.showAppStatistics(),
          ),
          _buildQuickActionChip(
            'Focus Mode',
            Icons.visibility_off,
            Colors.red,
            () => controller.helpWithFocusMode(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: onTap,
        backgroundColor: color.withOpacity(0.1),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildChatList(ChatbotController controller) {
    if (controller.messages.isEmpty) {
      return _buildWelcomeScreen(controller);
    }

    return ListView.builder(
      controller: controller.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final message = controller.messages[index];
        return _buildMessageBubble(message, controller);
      },
    );
  }

  Widget _buildWelcomeScreen(ChatbotController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.psychology,
              size: 80,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to your Productivity Assistant!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'I can help you manage your app schedules, provide productivity tips, and answer questions about your digital wellness journey.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildSuggestionCard(
                'How many schedules do I have?',
                Icons.schedule,
                Colors.blue,
                () => controller.sendMessage('How many schedules do I have?'),
              ),
              _buildSuggestionCard(
                'Give me productivity tips',
                Icons.lightbulb,
                Colors.orange,
                () => controller.sendMessage('Give me some productivity tips'),
              ),
              _buildSuggestionCard(
                'Help me create a schedule',
                Icons.add_circle,
                Colors.green,
                () => controller.sendMessage('Help me create a new schedule'),
              ),
              _buildSuggestionCard(
                'What apps am I blocking?',
                Icons.block,
                Colors.red,
                () => controller
                    .sendMessage('What apps am I currently blocking?'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, ChatbotController controller) {
    final isUser = message.isUser;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(false),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.suggestions.isNotEmpty && !isUser) ...[
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: message.suggestions.map((suggestion) {
                        return GestureDetector(
                          onTap: () => controller.sendMessage(suggestion),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ] else
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isUser ? Colors.blue : Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.psychology,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildAvatar(false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (value * 0.5),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(value),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(ChatbotController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderColor, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.textController,
                focusNode: controller.focusNode,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Ask me anything about your productivity...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    onPressed: controller.pickImage,
                    icon:
                        const Icon(Icons.image, color: AppColors.textSecondary),
                  ),
                ),
                onSubmitted: (text) => controller.sendMessage(text),
              ),
            ),
            const SizedBox(width: 8),
            Obx(() => FloatingActionButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.sendCurrentMessage(),
                  backgroundColor:
                      controller.isLoading.value ? Colors.grey : Colors.blue,
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

// ===== CHAT MESSAGE MODEL =====
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
  });
}
