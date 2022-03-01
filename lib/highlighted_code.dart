import 'themeprovider.dart';
import 'package:flutter/material.dart';

import 'variant.dart';

typedef OnMatchFunc   = TextSpan Function(String); 
typedef HighlightData = Variant2<TextStyle, OnMatchFunc>;

/// highlighs the code after some simple syntax rules 
/// please note that this class does not know anything about the syntax of the given language
class HighlightCodeController extends TextEditingController {
    Color foreground;
    Color background;
    Map<String, HighlightData> stringMap;
    Map<RegExp, HighlightData> patternMap;

    HighlightCodeController({
        CodeTheme? theme,
        Map<String, HighlightData>? strings,
        Map<RegExp, HighlightData>? patterns
    }) : 
        foreground = theme == null ? const Color(0xFF000000)  : theme.foreground,
        background = theme == null ? const Color(0xFF000000)  : theme.background,
        stringMap  = strings  ?? {},
        patternMap = patterns ?? {},
        super();

    @override
    TextSpan buildTextSpan({
        required BuildContext context,
        TextStyle? style,
        required bool withComposing})
    {
        List<TextSpan> children = [];
        
        // we concatenate the two different maps into a single list of 'regexes'
        List<RegExp> strings =[];
        for (var p in patternMap.keys) {
            strings.add(p);
        }
        for (var s in stringMap.keys.map((e) => RegExp(r'\b' + e + r'\b'))) {
            strings.add(s);
        }

        // turn the list of regexes into a single regex
        final RegExp matchString = RegExp(strings.map((e) => e.pattern).join('|'));
        text.splitMapJoin(matchString, 
            onNonMatch: (String span) {
                children.add(TextSpan(text: span, style: style));
                return span.toString();
            },
            onMatch: (Match m) {
                RegExp? regexKey;
                for (final regex in patternMap.keys) {
                    if (regex.allMatches((m[0]!)).isNotEmpty) {
                        regexKey = regex;
                        break;
                    }
                }
                
                String? stringKey; 
                for (final string in stringMap.keys) {
                    if (string.allMatches(m[0]!).isNotEmpty) {
                        stringKey = string;
                        break;
                    }
                }

                assert(stringKey != null || regexKey != null);

                final handler = regexKey != null ? patternMap[regexKey] : stringMap[stringKey];
                if (handler == null) return '';
        
                if (handler.isType<TextStyle>()) {
                    final TextStyle style = handler.getValue<TextStyle>();
                    children.add(TextSpan(text: m[0], style: style));
                } else {
                    final OnMatchFunc onMatch = handler.getValue<OnMatchFunc>();
                    children.add(onMatch(m[0]!));
                }
                return '';
            }
        );
        return TextSpan(style: style, children: children);
    }

}
