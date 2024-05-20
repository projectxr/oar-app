import 'package:flutter/material.dart';
import 'package:app/utils/const.dart';

class TextInput extends StatelessWidget {
  final TextEditingController inputController;
  final TextInputType? keyboardType;
  final String fieldName;
  final bool obscureText;
  final IconData? icon;
  final Function()? onPressedIcon;
  final EdgeInsets fieldPadding;
  final bool enabled;
  const TextInput(
      {super.key,
      required this.inputController,
      this.keyboardType,
      required this.fieldName,
      this.obscureText = false,
      this.icon,
      this.onPressedIcon,
      required this.enabled,
      this.fieldPadding = FORM_PADDING});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppConstants().width * 0.1, 0, AppConstants().width * 0.1, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Text('Enter $fieldName'),
          const SizedBox(
            height: V_SMALL_PAD,
          ),
          Material(
            borderRadius: const BorderRadius.all(Radius.circular(TEXT_FIELD_BORDER_RADIUS)),
            elevation: TEXT_FIELD_ELEVATION,
            child: TextField(
              enabled: enabled,
              textInputAction: TextInputAction.go,
              onSubmitted: (value) {
                if (onPressedIcon != null && enabled) {
                  onPressedIcon!();
                }
              },
              cursorColor: TEXT_FIELD_CURSOR_COLOR,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  disabledBorder: InputBorder.none,
                  contentPadding: fieldPadding,
                  suffixIcon: icon != null
                      ? IconButton(
                          icon: Icon(icon, color: TEXT_FIELD_ICON_COLOR),
                          onPressed: () {
                            if (onPressedIcon != null) {
                              onPressedIcon!();
                            }
                          })
                      : null,
                  hintText: fieldName,
                  errorStyle: const TextStyle(height: 0),
                  fillColor: Colors.white),
              controller: inputController,
              keyboardType: keyboardType,
              obscureText: obscureText,
            ),
          )
        ],
      ),
    );
  }
}
