import 'package:flutter/material.dart';
import 'package:docking/docking.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main.dart';
import 'data.dart';
import 'highlighted_code.dart';
import 'themeprovider.dart';

class EditorData implements Data {
    HighlightCodeController? _controller;
    HighlightCodeController _getController() { 
        final theme = ThemeProvider.provider.code;
        final strings = {
            'if'  : HighlightData(TextStyle(color: theme.keyword)),
            'else': HighlightData(TextStyle(color: theme.keyword)),
            'let' : HighlightData(TextStyle(color: theme.types)),
        };

        final patterns = {
            // comments
            RegExp(r'//.*'): HighlightData(TextStyle(color: ThemeProvider.provider.code.comments)),
            // strings, with ansi escapes
            RegExp(r'".*"'): HighlightData((String str){
                List<TextSpan> children = [];
                // this regex is based of, of C's escape sequences
                // https://en.cppreference.com/w/c/language/escape
                final stringEscape = RegExp(r'\\(x[[:alnum:]]{1,2}|[0-7]{1,3}|u[[:alnum:]]{4}|U[[:alnum:]]{8}|.)');
                str.splitMapJoin(stringEscape,
                    onNonMatch: (String span) {
                        children.add(TextSpan(text: span, style: TextStyle(color: theme.string)));
                        return span.toString();
                    },
                    onMatch: (Match m) {
                        children.add(TextSpan(text: m[0], style: TextStyle(color: theme.stringEscape)));
                        return '';
                    }
                );
                return TextSpan(style: TextStyle(color: theme.string), children: children);
            }),
        };

        _controller ??= HighlightCodeController();
        _controller?.updateColors(theme: theme, strings: strings, patterns: patterns);

        return _controller!;
    }

    HighlightCodeController get controller => _getController();

    @override
    void init(SharedPreferences prefs) {
        String? data =prefs.getString('editor_text');
        if (data != null) {
            controller.text = data;
        }
    }
    @override
    void save(SharedPreferences prefs) {
        prefs.setString('editor_text', controller.text);
    }

    String? getSavedData(SharedPreferences prefs) {
        return prefs.getString('editor_text');
    }
}

class EditorWidget extends StatefulWidget {
    const EditorWidget({Key? key, required this.data}) : super(key: key);
    final EditorData data;

    @override
    State<EditorWidget> createState() => EditorState();
}

//TODO(jpm): move CallIntent and CallAction into their own file
class CallIntent extends Intent {
    final dynamic callable;
    const CallIntent(this.callable);
}

//TODO(jpm): move CallIntent and CallAction into their own file
class CallAction extends Action {
    @override
    Object invoke(covariant Intent intent) {
        if (intent is CallIntent) {
            CallIntent i = intent;
            i.callable();
        }
        return '';
    }
}

class EditorState extends State<EditorWidget> {
    final FocusNode node = FocusNode(skipTraversal: true);

    _max(a, b) { return a < b ? a : b; }

    @override
    Widget build(BuildContext context) {
        SharedPreferences.getInstance().then((value){
            var data = widget.data;
            String? saveString = data.getSavedData(value);
            String  text = data.controller.text;
            if (saveString == null || saveString.compareTo(text) != 0) {
                widget.data.save(value);
            }
        });
        return Actions(
            actions: { CallIntent: CallAction() },
            child: Shortcuts(
                shortcuts: { 
                    LogicalKeySet(LogicalKeyboardKey.tab):
                        CallIntent((){ 
                            final max = _max;
                            var controller = widget.data.controller;
                            String insert = "   ";
                            final int cursorPos = controller.selection.base.offset;
                            controller.value = controller.value.copyWith(
                                text: controller.text.replaceRange(max(cursorPos, 0), max(cursorPos, 0), insert),
                                selection: TextSelection.fromPosition(TextPosition(offset: max(cursorPos, 0) + insert.length))
                            );
                        })
                },
                child: TextField(
                    focusNode: node,
                    controller: widget.data.controller,
                    keyboardType: TextInputType.multiline,
                    autofocus: true,
                    expands: true,
                    maxLines: null,
                )
            )
        );
    }
}

class EditorWindow extends DockingItem {
    EditorWindow({EditorData? data, MyHomePage? widget}) : super(
        name: 'editor', 
        closable: false, 
        maximizable: true,
        widget: EditorWidget(data: data!)
    );
}
