import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

class AppOtpInput extends StatefulWidget {
  const AppOtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  @override
  State<AppOtpInput> createState() => _AppOtpInputState();
}

class _AppOtpInputState extends State<AppOtpInput> {
  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  String _value = '';

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncFromField(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > widget.length ? digits.substring(0, widget.length) : digits;
    if (clipped == _value) return;
    setState(() {
      _value = clipped;
      if (_controller.text != _value) {
        _controller.value = TextEditingValue(
          text: _value,
          selection: TextSelection.collapsed(offset: _value.length),
        );
      }
    });
    widget.onChanged?.call(_value);
    if (_value.length == widget.length) {
      widget.onCompleted(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: List.generate(widget.length, (i) {
              final has = i < _value.length;
              final active = _focusNode.hasFocus && i == _value.length;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < widget.length - 1 ? 8 : 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: has || active ? AppColors.primary : Colors.transparent,
                        width: has || active ? 2 : 0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      has ? _value[i] : '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        Opacity(
          opacity: 0,
          child: SizedBox(
            height: 1,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: _syncFromField,
              decoration: const InputDecoration(counterText: ''),
            ),
          ),
        ),
      ],
    );
  }
}
