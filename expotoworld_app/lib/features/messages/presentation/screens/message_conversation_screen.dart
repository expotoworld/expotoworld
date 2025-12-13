import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';

/// Message Conversation Screen - Chat interface for individual messages
class MessageConversationScreen extends ConsumerStatefulWidget {
  final String messageId;
  final String senderName;
  final String senderInitials;
  final Color avatarColor;
  final IconData? typeIcon;
  final bool canReply;

  const MessageConversationScreen({
    super.key,
    required this.messageId,
    required this.senderName,
    required this.senderInitials,
    required this.avatarColor,
    this.typeIcon,
    this.canReply = true,
  });

  @override
  ConsumerState<MessageConversationScreen> createState() =>
      _MessageConversationScreenState();
}

class _MessageConversationScreenState
    extends ConsumerState<MessageConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late List<_ConversationMessage> _messages;
  bool _hasText = false;
  bool _isInputExpanded = false;

  @override
  void initState() {
    super.initState();
    _messages = _getInitialMessages();
    _messageController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    final hasFocus = _focusNode.hasFocus;
    if (hasFocus != _isInputExpanded) {
      setState(() => _isInputExpanded = hasFocus);
    }
  }

  List<_ConversationMessage> _getInitialMessages() {
    // Sample conversation history
    return [
      _ConversationMessage(
        id: '1',
        content:
            'Hello! Thank you for reaching out. We\'re here to help you with any questions about your ${widget.senderName.contains('Order') ? 'order' : 'inquiry'}.',
        isFromSender: true,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ConversationMessage(
          id: DateTime.now().toString(),
          content: text,
          isFromSender: false,
          timestamp: DateTime.now(),
        ),
      );
    });
    _messageController.clear();
    _scrollToBottom();

    // Simulate response (in real app, this would be from backend/AI)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(
            _ConversationMessage(
              id: DateTime.now().toString(),
              content:
                  'Thank you for your message! We\'ll get back to you shortly.',
              isFromSender: true,
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

    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside the input area
        _focusNode.unfocus();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.neutralBlack : AppColors.neutralWhite,
        resizeToAvoidBottomInset: true, // Ensure input sticks to keyboard
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
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.avatarColor,
                    widget.avatarColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: widget.typeIcon != null
                    ? Icon(widget.typeIcon, color: Colors.white, size: 18)
                    : Text(
                        widget.senderInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.senderName,
                    style: AppTypography.bodyMedium().copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.neutralWhite
                          : AppColors.neutralBlack,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Active now',
                    style: AppTypography.caption().copyWith(
                      color: AppColors.green500,
                    ),
                  ),
                ],
              ),
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

          // Input area - only show if canReply is true
          if (widget.canReply) _buildInputArea(isDark),
        ],
      ),
      ),
    );
  }

  // Input area with staggered "lift and expand" animation using LayoutBuilder + Stack
  // Single TextField approach - animates position within a Stack
  // Layout:
  // - Collapsed: [+] [TextField] [Send] all visually on one row (buttons at edges, TextField between)
  // - Expanded: TextField lifts up to full width above buttons, [+] ---- [Send] stay below
  // Animation sequence:
  // - Expand: lift up FIRST (phase 1), THEN expand width (phase 2)
  // - Collapse: shrink width FIRST (phase 1), THEN lower down (phase 2)

  // Build plus button widget (reusable)
  Widget _buildPlusButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        // TODO: Open photo picker
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDark ? AppColors.neutralGray800 : AppColors.neutralGray100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.add_rounded,
          color: isDark ? AppColors.neutralGray400 : AppColors.neutralGray500,
          size: 20,
        ),
      ),
    );
  }

  // Build send button widget (reusable)
  Widget _buildSendButton(bool isDark) {
    return GestureDetector(
      onTap: _hasText ? _sendMessage : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _hasText
              ? AppColors.themeRed
              : (isDark ? AppColors.neutralGray700 : AppColors.neutralGray200),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_upward_rounded,
          color: _hasText
              ? Colors.white
              : (isDark ? AppColors.neutralGray500 : AppColors.neutralGray400),
          size: 18,
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    const double buttonSize = 32.0;
    final double buttonSpacing = AppSpacing.sm;
    
    // Animation timing - matched to native keyboard physics (~250ms with decelerate curve)
    const animationDuration = Duration(milliseconds: 250);
    const animationCurve = Curves.easeOutQuart; // Settles quickly like native keyboard
    
    return Container(
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              
              // Dimensions
              final collapsedTextFieldWidth = availableWidth - (buttonSize + buttonSpacing) * 2;
              final expandedTextFieldWidth = availableWidth;
              final collapsedTextFieldLeft = buttonSize + buttonSpacing;
              const expandedTextFieldLeft = 0.0;
              const collapsedHeight = buttonSize;
              const expandedTextFieldHeight = 60.0;
              const gapBetween = 4.0;
              final expandedHeight = expandedTextFieldHeight + gapBetween + buttonSize;
              
              return AnimatedContainer(
                duration: animationDuration,
                curve: animationCurve,
                height: _isInputExpanded ? expandedHeight : collapsedHeight,
                // Anchor to bottom - container grows UPWARD, bottom edge stays locked to keyboard
                alignment: Alignment.bottomCenter,
                child: Stack(
                  children: [
                    // TextField - animates position and width, lifts away from buttons
                    AnimatedPositioned(
                      duration: animationDuration,
                      curve: animationCurve,
                      top: 0,
                      left: _isInputExpanded ? expandedTextFieldLeft : collapsedTextFieldLeft,
                      width: _isInputExpanded ? expandedTextFieldWidth : collapsedTextFieldWidth,
                      bottom: _isInputExpanded ? (buttonSize + gapBetween) : 0,
                      child: GestureDetector(
                        onTap: () => _focusNode.requestFocus(),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          style: AppTypography.bodyMedium(
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: _isInputExpanded ? 4 : 1,
                          minLines: 1,
                          cursorColor: AppColors.themeRed,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
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
                              vertical: _isInputExpanded ? AppSpacing.sm : 6,
                            ),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    // Plus button - anchored to bottom left, stays with keyboard
                    Positioned(
                      left: 0,
                      bottom: 0,
                      width: buttonSize,
                      height: buttonSize,
                      child: _buildPlusButton(isDark),
                    ),
                    // Send button - anchored to bottom right, stays with keyboard
                    Positioned(
                      right: 0,
                      bottom: 0,
                      width: buttonSize,
                      height: buttonSize,
                      child: _buildSendButton(isDark),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ConversationMessage message, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: message.isFromSender
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isFromSender) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.avatarColor,
                    widget.avatarColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Center(
                child: widget.typeIcon != null
                    ? Icon(widget.typeIcon, color: Colors.white, size: 14)
                    : Text(
                        widget.senderInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: message.isFromSender
                    ? (isDark
                          ? AppColors.neutralGray800
                          : AppColors.neutralGray100)
                    : widget.avatarColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppSpacing.radiusMd),
                  topRight: Radius.circular(AppSpacing.radiusMd),
                  bottomLeft: Radius.circular(
                    message.isFromSender ? 4 : AppSpacing.radiusMd,
                  ),
                  bottomRight: Radius.circular(
                    message.isFromSender ? AppSpacing.radiusMd : 4,
                  ),
                ),
              ),
              child: Text(
                message.content,
                style: AppTypography.bodyMedium().copyWith(
                  color: message.isFromSender
                      ? (isDark
                            ? AppColors.neutralWhite
                            : AppColors.neutralBlack)
                      : Colors.white,
                ),
              ),
            ),
          ),
          if (!message.isFromSender) ...[SizedBox(width: AppSpacing.sm)],
        ],
      ),
    );
  }
}

/// Conversation message model
class _ConversationMessage {
  final String id;
  final String content;
  final bool isFromSender;
  final DateTime timestamp;

  _ConversationMessage({
    required this.id,
    required this.content,
    required this.isFromSender,
    required this.timestamp,
  });
}
