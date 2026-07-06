import 'package:flutter/material.dart';

/// Visual styling for the default [StoryReplyBar] look.
///
/// Every value has a sensible minimalist default. Override only what you need,
/// or replace whole sections with the builder hooks on [StoryReplyBar]
/// ([StoryReplyBar.inputBuilder], [StoryReplyBar.sendButtonBuilder],
/// [StoryReplyBar.reactionBuilder]) for full control.
@immutable
class StoryReplyBarStyle {
  /// Creates a reply bar style.
  const StoryReplyBarStyle({
    this.fillColor = const Color(0x1FFFFFFF),
    this.borderColor = const Color(0x3DFFFFFF),
    this.borderWidth = 1,
    this.borderRadius = 26,
    this.textColor = Colors.white,
    this.hintColor = const Color(0xB3FFFFFF),
    this.fontSize = 15,
    this.cursorColor = Colors.white,
    this.accentColor = Colors.white,
    this.sendIcon = Icons.send_rounded,
    this.sendIconColor,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 12, 8, 12),
    this.reactionSize = 30,
    this.reactionSpacing = 8,
  });

  /// A light-theme preset: dark text over a subtle light pill.
  const StoryReplyBarStyle.light()
      : fillColor = const Color(0x0A000000),
        borderColor = const Color(0x1F000000),
        borderWidth = 1,
        borderRadius = 26,
        textColor = const Color(0xFF1A1A1A),
        hintColor = const Color(0x99000000),
        fontSize = 15,
        cursorColor = const Color(0xFF1A1A1A),
        accentColor = const Color(0xFF1A1A1A),
        sendIcon = Icons.send_rounded,
        sendIconColor = null,
        contentPadding = const EdgeInsets.fromLTRB(18, 12, 8, 12),
        reactionSize = 30,
        reactionSpacing = 8;

  /// Fill color of the input pill.
  final Color fillColor;

  /// Border color of the input pill.
  final Color borderColor;

  /// Border thickness of the input pill. Set to `0` to remove the border.
  final double borderWidth;

  /// Corner radius of the input pill.
  final double borderRadius;

  /// Color of the typed text.
  final Color textColor;

  /// Color of the placeholder/hint text.
  final Color hintColor;

  /// Font size for the input text and hint.
  final double fontSize;

  /// Color of the text cursor.
  final Color cursorColor;

  /// Accent color used for the send affordance.
  final Color accentColor;

  /// Icon shown on the send button.
  final IconData sendIcon;

  /// Color of the send icon. Defaults to [accentColor].
  final Color? sendIconColor;

  /// Padding inside the input pill, around the text and trailing send button.
  final EdgeInsets contentPadding;

  /// Font size of the quick reaction emojis.
  final double reactionSize;

  /// Horizontal gap between reaction emojis.
  final double reactionSpacing;

  /// Returns a copy with the given fields replaced.
  StoryReplyBarStyle copyWith({
    Color? fillColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Color? textColor,
    Color? hintColor,
    double? fontSize,
    Color? cursorColor,
    Color? accentColor,
    IconData? sendIcon,
    Color? sendIconColor,
    EdgeInsets? contentPadding,
    double? reactionSize,
    double? reactionSpacing,
  }) {
    return StoryReplyBarStyle(
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      textColor: textColor ?? this.textColor,
      hintColor: hintColor ?? this.hintColor,
      fontSize: fontSize ?? this.fontSize,
      cursorColor: cursorColor ?? this.cursorColor,
      accentColor: accentColor ?? this.accentColor,
      sendIcon: sendIcon ?? this.sendIcon,
      sendIconColor: sendIconColor ?? this.sendIconColor,
      contentPadding: contentPadding ?? this.contentPadding,
      reactionSize: reactionSize ?? this.reactionSize,
      reactionSpacing: reactionSpacing ?? this.reactionSpacing,
    );
  }
}

/// Builds a fully custom input area for [StoryReplyBar].
///
/// [controller] and [focusNode] are owned by the bar; wire them into your own
/// widget. Call [submit] to send the current text (it trims, clears and
/// unfocuses automatically).
typedef StoryReplyInputBuilder = Widget Function(
  BuildContext context,
  TextEditingController controller,
  FocusNode focusNode,
  VoidCallback submit,
);

/// Builds a custom send affordance. [hasText] indicates whether the field has
/// non-empty content; call [submit] to send.
typedef StoryReplySendBuilder = Widget Function(
  BuildContext context,
  bool hasText,
  VoidCallback submit,
);

/// Builds a custom widget for a single quick reaction [emoji].
typedef StoryReactionBuilder = Widget Function(
  BuildContext context,
  String emoji,
  VoidCallback onTap,
);

/// A minimalist reply bar suitable for use inside [StoryView.footerBuilder].
///
/// Provides a clean pill text field plus optional quick reaction emojis. The
/// look is controlled by [style]; for deeper customization replace whole
/// sections via [inputBuilder], [sendButtonBuilder] or [reactionBuilder].
///
/// The host is responsible for pausing the viewer while the keyboard is open
/// (use [onFocusChanged] with a [StoryViewController]).
class StoryReplyBar extends StatefulWidget {
  /// Creates a reply bar.
  const StoryReplyBar({
    super.key,
    required this.onSubmitted,
    this.hintText = 'Send message',
    this.reactions = const <String>['❤️', '😮', '😂', '👏', '🔥'],
    this.onReaction,
    this.onFocusChanged,
    this.backgroundColor = Colors.transparent,
    this.enableReply = true,
    this.enableReactions = true,
    this.style = const StoryReplyBarStyle(),
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
    this.inputBuilder,
    this.sendButtonBuilder,
    this.reactionBuilder,
  });

  /// Called with the typed text when the user submits a reply.
  final ValueChanged<String> onSubmitted;

  /// Placeholder text for the input field.
  final String hintText;

  /// Quick reaction emojis shown above the input. Pass an empty list to hide.
  final List<String> reactions;

  /// Called when a quick reaction is tapped.
  final ValueChanged<String>? onReaction;

  /// Called when the input gains (`true`) or loses (`false`) focus. Use it to
  /// pause/resume the story while typing.
  final ValueChanged<bool>? onFocusChanged;

  /// Background color behind the bar.
  final Color backgroundColor;

  /// Whether the text reply input is shown. When `false` the message field and
  /// send button are hidden.
  final bool enableReply;

  /// Whether the quick reaction emojis are shown. When `false` the emoji row is
  /// hidden regardless of [reactions].
  final bool enableReactions;

  /// Visual styling for the default look.
  final StoryReplyBarStyle style;

  /// Outer padding around the whole bar.
  final EdgeInsets padding;

  /// Replaces the entire input area (pill + send button). When provided,
  /// [style] and [sendButtonBuilder] are ignored for the input.
  final StoryReplyInputBuilder? inputBuilder;

  /// Replaces only the trailing send affordance inside the default input pill.
  final StoryReplySendBuilder? sendButtonBuilder;

  /// Replaces the widget used for each quick reaction emoji.
  final StoryReactionBuilder? reactionBuilder;

  @override
  State<StoryReplyBar> createState() => _StoryReplyBarState();
}

class _StoryReplyBarState extends State<StoryReplyBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  void _onFocusChanged() => widget.onFocusChanged?.call(_focusNode.hasFocus);

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmitted(text);
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showReactions = widget.enableReactions && widget.reactions.isNotEmpty;
    // Lift the bar above the on-screen keyboard when it is open.
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: ColoredBox(
        color: widget.backgroundColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: widget.padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (showReactions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildReactions(context),
                  ),
                if (widget.enableReply)
                  widget.inputBuilder?.call(
                        context,
                        _controller,
                        _focusNode,
                        _submit,
                      ) ??
                      _buildInput(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    final style = widget.style;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        for (final emoji in widget.reactions)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: style.reactionSpacing),
            child: widget.reactionBuilder?.call(
                  context,
                  emoji,
                  () => widget.onReaction?.call(emoji),
                ) ??
                _ReactionButton(
                  emoji: emoji,
                  fontSize: style.reactionSize,
                  onTap: () => widget.onReaction?.call(emoji),
                ),
          ),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    final style = widget.style;
    return Container(
      decoration: BoxDecoration(
        color: style.fillColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: style.borderWidth > 0
            ? Border.all(color: style.borderColor, width: style.borderWidth)
            : null,
      ),
      padding: style.contentPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style:
                  TextStyle(color: style.textColor, fontSize: style.fontSize),
              cursorColor: style.cursorColor,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: widget.hintText,
                hintStyle:
                    TextStyle(color: style.hintColor, fontSize: style.fontSize),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(width: 8),
          widget.sendButtonBuilder?.call(context, _hasText, _submit) ??
              _DefaultSendButton(
                hasText: _hasText,
                style: style,
                onTap: _submit,
              ),
        ],
      ),
    );
  }
}

/// A single emoji reaction with a gentle bounce-on-tap animation.
class _ReactionButton extends StatefulWidget {
  const _ReactionButton({
    required this.emoji,
    required this.fontSize,
    this.onTap,
  });

  final String emoji;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton> {
  double _scale = 1;

  void _bounce() {
    setState(() => _scale = 1.35);
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _scale = 1);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _bounce,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Text(widget.emoji, style: TextStyle(fontSize: widget.fontSize)),
      ),
    );
  }
}

/// The default minimalist send affordance: a fading, sliding send glyph that
/// only appears once the user has typed something.
class _DefaultSendButton extends StatelessWidget {
  const _DefaultSendButton({
    required this.hasText,
    required this.style,
    required this.onTap,
  });

  final bool hasText;
  final StoryReplyBarStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(
          axis: Axis.horizontal,
          sizeFactor: animation,
          axisAlignment: -1,
          child: child,
        ),
      ),
      child: hasText
          ? GestureDetector(
              key: const ValueKey<String>('send'),
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  style.sendIcon,
                  color: style.sendIconColor ?? style.accentColor,
                  size: 22,
                ),
              ),
            )
          : const SizedBox(key: ValueKey<String>('empty'), width: 0, height: 0),
    );
  }
}
