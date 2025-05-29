import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../utils/constants/app_colors.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../schedules/controllers/schedule_controller.dart';
import '../screens/chatbot_screen.dart'; // Fixed import path

class ChatbotController extends GetxController {
  // Controllers
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
  String _apiKey = 'AIzaSyB4tY43FYA7HNkGpi5va9cJgWAmv-KwIks';

  // Observable states
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isTyping = false.obs;
  final RxBool isOnline = true.obs;
  final RxString currentContext = ''.obs;

  // Dependencies
  DashboardController? _dashboardController;
  ScheduleController? _scheduleController;
  bool _hasControllers = false;

  // Context data
  final RxMap<String, dynamic> userContext = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _updateUserContext();
    _sendWelcomeMessage(); // Send welcome message immediately
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  // FIXED: Initialize controllers safely
  void _initializeControllers() {
    try {
      if (Get.isRegistered<DashboardController>()) {
        _dashboardController = Get.find<DashboardController>();
      }

      if (Get.isRegistered<ScheduleController>()) {
        _scheduleController = Get.find<ScheduleController>();
      }

      _hasControllers =
          _dashboardController != null || _scheduleController != null;
      print(
          'ChatbotController: Controllers initialized - Dashboard: ${_dashboardController != null}, Schedule: ${_scheduleController != null}');
    } catch (e) {
      print('ChatbotController: Error initializing controllers: $e');
      _hasControllers = false;
    }
  }

  // FIXED: Update user context safely
  void _updateUserContext() {
    try {
      if (_dashboardController != null) {
        final dashboardStats = _dashboardController!.getScheduleStatistics();
        final savedTime = _dashboardController!
            .formatDuration(_dashboardController!.savedTimeToday.value);
        final unblockCount = _dashboardController!.unblockCount.value;

        userContext.value = {
          'userName': _dashboardController!.userName.value,
          'totalSchedules': dashboardStats['totalSchedules'] ?? 0,
          'activeSchedules': dashboardStats['activeSchedules'] ?? 0,
          'todaySchedules': dashboardStats['todaySchedules'] ?? 0,
          'savedTimeToday': savedTime,
          'unblockCount': unblockCount,
          'currentlyActive': dashboardStats['currentlyActive'] ?? false,
          'hasSchedules': dashboardStats['hasSchedules'] ?? false,
          'isAuthenticated': _dashboardController!.isAuthenticated.value,
        };
      } else {
        // Fallback context when controllers not available
        userContext.value = {
          'userName': 'User',
          'totalSchedules': 0,
          'activeSchedules': 0,
          'todaySchedules': 0,
          'savedTimeToday': '0m',
          'unblockCount': 0,
          'currentlyActive': false,
          'hasSchedules': false,
          'isAuthenticated': false,
        };
      }

      print('ChatbotController: User context updated: ${userContext.value}');
    } catch (e) {
      print('ChatbotController: Error updating user context: $e');
      // Set default context on error
      userContext.value = {
        'userName': 'User',
        'totalSchedules': 0,
        'activeSchedules': 0,
        'todaySchedules': 0,
        'savedTimeToday': '0m',
        'unblockCount': 0,
        'currentlyActive': false,
        'hasSchedules': false,
        'isAuthenticated': false,
      };
    }
  }

  // FIXED: Send welcome message without API key dialog
  void _sendWelcomeMessage() {
    _updateUserContext();
    final userName = userContext['userName'] ?? 'there';

    final welcomeText = '''
Hello $userName! 👋 I'm your AI productivity assistant.

I can see you have ${userContext['totalSchedules']} schedule(s) set up, with ${userContext['activeSchedules']} currently active. Today you've saved ${userContext['savedTimeToday']} of focused time!

How can I help you today?
''';

    final suggestions = [
      'Analyze my productivity',
      'Create a new schedule',
      'Optimize my current schedules',
      'Give me focus tips'
    ];

    messages.add(ChatMessage(
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
      suggestions: suggestions,
    ));

    _scrollToBottom();
  }

  // Send message
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    textController.clear();
    _scrollToBottom();

    // Process message
    await _processMessage(text);
  }

  // Send current message from text controller
  Future<void> sendCurrentMessage() async {
    await sendMessage(textController.text);
  }

  // FIXED: Process message with better error handling
  Future<void> _processMessage(String userMessage) async {
    if (_apiKey.isEmpty) {
      messages.add(ChatMessage(
        text:
            'Sorry, AI functionality is not available right now. Please try again later.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    isLoading.value = true;
    isTyping.value = true;
    _updateUserContext();

    try {
      // Build context-aware prompt
      final systemPrompt = _buildSystemPrompt();
      final contextualMessage = _buildContextualMessage(userMessage);

      final response = await _callGeminiAPI(systemPrompt + contextualMessage);

      // Add AI response
      messages.add(ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: _generateSuggestions(userMessage, response),
      ));
    } catch (e) {
      print('ChatbotController: Error processing message: $e');
      messages.add(ChatMessage(
        text:
            'Sorry, I encountered an error. Please check your internet connection and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      isLoading.value = false;
      isTyping.value = false;
      _scrollToBottom();
    }
  }

  // Build system prompt with user context
  String _buildSystemPrompt() {
    return '''
You are a helpful AI productivity assistant for a mobile app that helps users manage their digital wellness and app blocking schedules.

Current user context:
- User name: ${userContext['userName']}
- Total schedules: ${userContext['totalSchedules']}
- Active schedules: ${userContext['activeSchedules']}
- Today's applicable schedules: ${userContext['todaySchedules']}
- Time saved today: ${userContext['savedTimeToday']}
- App unblocks today: ${userContext['unblockCount']}
- Currently active schedule: ${userContext['currentlyActive'] ? 'Yes' : 'No'}
- Has any schedules: ${userContext['hasSchedules']}

Guidelines:
- Be helpful, friendly, and encouraging
- Provide specific, actionable advice about productivity and digital wellness
- Reference the user's actual data when relevant
- Keep responses concise but informative
- Offer practical tips for better focus and time management
- Help users understand and optimize their app blocking schedules
- Encourage healthy digital habits

If asked about creating schedules, guide them through the process step by step.
If asked about their current status, use the actual data provided.
Always be supportive and motivating in your responses.

User message: 
''';
  }

  // Build contextual message based on user input
  String _buildContextualMessage(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    // Add specific context based on message content
    if (lowerMessage.contains('schedule')) {
      final scheduleDetails = _getScheduleDetails();
      return '$userMessage\n\nMy current schedules: $scheduleDetails';
    }

    if (lowerMessage.contains('app') || lowerMessage.contains('block')) {
      final appDetails = _getBlockedAppsDetails();
      return '$userMessage\n\nCurrently blocked apps: $appDetails';
    }

    if (lowerMessage.contains('time') || lowerMessage.contains('save')) {
      return '$userMessage\n\nToday I\'ve saved ${userContext['savedTimeToday']} and unblocked apps ${userContext['unblockCount']} times.';
    }

    return userMessage;
  }

  // FIXED: Get schedule details safely
  String _getScheduleDetails() {
    if (_scheduleController == null) return 'No schedule data available';

    try {
      final schedules = _scheduleController!.schedules.toList();
      if (schedules.isEmpty) return 'No schedules created yet';

      final details = schedules.map((schedule) {
        final days = _scheduleController!.formatDays(schedule.days);
        final startTime =
            _scheduleController!.formatTimeOfDay(schedule.startTime);
        final endTime = _scheduleController!.formatTimeOfDay(schedule.endTime);
        final status = schedule.isActive ? 'Active' : 'Inactive';

        return '${schedule.title}: $days from $startTime to $endTime ($status)';
      }).join(', ');

      return details;
    } catch (e) {
      return 'Error loading schedule details';
    }
  }

  // FIXED: Get blocked apps details safely
  String _getBlockedAppsDetails() {
    if (_scheduleController == null) return 'No app data available';

    try {
      final schedules =
          _scheduleController!.schedules.where((s) => s.isActive).toList();
      if (schedules.isEmpty) return 'No active schedules';

      final Set<String> allBlockedApps = {};
      for (final schedule in schedules) {
        allBlockedApps.addAll(schedule.blockedApps);
      }

      if (allBlockedApps.isEmpty) return 'No apps currently blocked';

      return '${allBlockedApps.length} apps across ${schedules.length} active schedules';
    } catch (e) {
      return 'Error loading app details';
    }
  }

  // FIXED: Call Gemini API with better error handling
  Future<String> _callGeminiAPI(String prompt) async {
    final url = '$_baseUrl?key=$_apiKey';

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1000,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ],
    };

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List;
          if (parts.isNotEmpty) {
            return parts[0]['text'] ??
                'Sorry, I couldn\'t generate a response.';
          }
        }

        return 'Sorry, I couldn\'t generate a response.';
      } else {
        print(
            'ChatbotController: API Error: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 400) {
          return 'Sorry, there was an issue with the request. Please try rephrasing your question.';
        } else if (response.statusCode == 403) {
          return 'Sorry, the API key may be invalid or quota exceeded. Please try again later.';
        } else if (response.statusCode == 429) {
          return 'Sorry, too many requests. Please wait a moment and try again.';
        }

        throw Exception('Failed to get response from AI');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return 'Sorry, the request timed out. Please check your internet connection and try again.';
      }
      throw e;
    }
  }

  // Generate contextual suggestions
  List<String> _generateSuggestions(String userMessage, String aiResponse) {
    final lowerMessage = userMessage.toLowerCase();
    final lowerResponse = aiResponse.toLowerCase();

    List<String> suggestions = [];

    if (lowerMessage.contains('schedule') ||
        lowerResponse.contains('schedule')) {
      suggestions.addAll([
        'Create a new schedule',
        'Edit existing schedule',
        'Show schedule conflicts',
      ]);
    }

    if (lowerMessage.contains('tip') || lowerResponse.contains('tip')) {
      suggestions.addAll([
        'More productivity tips',
        'Focus techniques',
        'Break bad habits',
      ]);
    }

    if (lowerMessage.contains('app') || lowerResponse.contains('app')) {
      suggestions.addAll([
        'Which apps to block?',
        'App usage statistics',
        'Recommended restrictions',
      ]);
    }

    // Default suggestions if none match
    if (suggestions.isEmpty) {
      suggestions = [
        'Tell me more',
        'What\'s next?',
        'Any other tips?',
      ];
    }

    return suggestions.take(3).toList();
  }

  // Scroll to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Quick action methods
  void askAboutSchedules() {
    sendMessage('Tell me about my current schedules and their effectiveness');
  }

  void helpCreateSchedule() {
    sendMessage('Help me create a new app blocking schedule');
  }

  void getProductivityTips() {
    sendMessage('Give me personalized productivity tips based on my usage');
  }

  void showAppStatistics() {
    sendMessage('Show me my app usage statistics and patterns');
  }

  void helpWithFocusMode() {
    sendMessage('How can I improve my focus and reduce distractions?');
  }

  // Menu actions
  void handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showSettings();
        break;
      case 'help':
        _showHelp();
        break;
      case 'feedback':
        _showFeedback();
        break;
    }
  }

  void _showSettings() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Settings',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.blue),
              title: const Text('Refresh Context',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Get.back();
                _updateUserContext();
                Get.snackbar('Success', 'Context refreshed successfully',
                    backgroundColor: Colors.green, colorText: Colors.white);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Clear Chat History',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Get.back();
                clearChat();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    sendMessage('How do I use this AI assistant effectively?');
  }

  void _showFeedback() {
    Get.snackbar(
      'Feedback',
      'Thank you for using our AI assistant! Send us feedback at support@example.com',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }

  // Clear chat
  void clearChat() {
    messages.clear();
    _sendWelcomeMessage(); // Send welcome message again after clearing
    Get.snackbar(
      'Chat Cleared',
      'Your conversation history has been cleared',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // Pick image (for future image analysis feature)
  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        Get.snackbar(
          'Coming Soon',
          'Image analysis feature will be available in a future update!',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('ChatbotController: Error picking image: $e');
    }
  }
}
