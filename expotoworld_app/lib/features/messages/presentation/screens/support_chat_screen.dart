import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/theme.dart';

/// Support Chat Screen - AI-powered conversation interface
class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasText = false;
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      id: '1',
      content:
          'Hello! 👋 I\'m your EXPO to WORLD support assistant. How can I help you today?',
      isBot: true,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          id: DateTime.now().toString(),
          content: text,
          isBot: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate bot response (in real app, this would call AI service)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(
            _ChatMessage(
              id: DateTime.now().toString(),
              content:
                  'Thank you for your message! Our team is looking into this. Is there anything else I can help you with?',
              isBot: true,
              timestamp: DateTime.now(),
            ),
          );
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.neutralBlack
            : AppColors.neutralWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.neutralWhite : AppColors.neutralBlack,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.themeRed, AppColors.themeRedLight],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.supportTitle,
                  style: AppTypography.bodyMedium().copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.neutralWhite
                        : AppColors.neutralBlack,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.supportOnline,
                  style: AppTypography.caption().copyWith(
                    color: AppColors.green500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(AppSpacing.lg),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message, isDark);
              },
            ),
          ),

          // Input area - rounded top with shadow
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Plus button for photos/gallery
                    GestureDetector(
                      onTap: () {
                        // TODO: Open photo picker
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.neutralGray800
                              : AppColors.neutralGray100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: isDark
                              ? AppColors.neutralGray400
                              : AppColors.neutralGray500,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    // Text input - plain style with no borders
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: AppTypography.bodyMedium(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        maxLines: 4,
                        minLines: 1,
                        cursorColor: AppColors.themeRed,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.supportTypeMessage,
                          hintStyle: AppTypography.bodyMedium(
                            color: isDark
                                ? AppColors.neutralGray500
                                : AppColors.neutralGray400,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    // Send button - grey when empty, red when has text
                    GestureDetector(
                      onTap: _hasText ? _sendMessage : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _hasText
                              ? AppColors.themeRed
                              : (isDark
                                  ? AppColors.neutralGray700
                                  : AppColors.neutralGray200),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_upward_rounded,
                          color: _hasText
                              ? Colors.white
                              : (isDark
                                  ? AppColors.neutralGray500
                                  : AppColors.neutralGray400),
                          size: 18,
                        ),
                      ),
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

  Widget _buildMessageBubble(_ChatMessage message, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: message.isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.themeRed, AppColors.themeRedLight],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: message.isBot
                    ? (isDark
                          ? AppColors.neutralGray800
                          : AppColors.neutralGray100)
                    : AppColors.themeRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMd),
                  topRight: Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(
                    message.isBot ? 4 : AppSpacing.radiusMd,
                  ),
                  bottomRight: Radius.circular(
                    message.isBot ? AppSpacing.radiusMd : 4,
                  ),
                ),
              ),
              child: Text(
                message.content,
                style: AppTypography.bodyMedium().copyWith(
                  color: message.isBot
                      ? (isDark
                            ? AppColors.neutralWhite
                            : AppColors.neutralBlack)
                      : Colors.white,
                ),
              ),
            ),
          ),
          if (!message.isBot) ...[SizedBox(width: AppSpacing.sm)],
        ],
      ),
    );
  }
}

/// Chat message model
class _ChatMessage {
  final String id;
  final String content;
  final bool isBot;
  final DateTime timestamp;

  _ChatMessage({
    required this.id,
    required this.content,
    required this.isBot,
    required this.timestamp,
  });
}
