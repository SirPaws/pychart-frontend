import 'package:flutter/material.dart';
import 'package:tabbed_view/tabbed_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';

class ThemeProvider implements Data {
    static ThemeProvider? _singleton;
    static ThemeProvider getProvider() {
        _singleton ??= ThemeProvider();
        return _singleton!;
    }
    static ThemeProvider get provider => getProvider();
    bool isDarkMode = false;


    @override
    void init(SharedPreferences prefs) {
        isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    }
    
    @override
    void save(SharedPreferences prefs) {
        prefs.setBool('is_dark_mode', isDarkMode);
    }

    void toggle() { 
        isDarkMode = !isDarkMode; 
    }

    ThemeData get material             => isDarkMode ? Themes.materialDark   : Themes.materialLight;
    TabbedViewThemeData get tabbedView => isDarkMode ? Themes.tabbedViewDark : Themes.tabbedViewLight; 
    CodeTheme get code                 => isDarkMode ? Themes.codeDracula    : Themes.codeLight;
}

class CodeTheme {
    Color keyword;
    Color types;
    Color comments;
    Color foreground;
    Color background;
    Color string;
    Color stringEscape;
    CodeTheme({
        Color? keyword   ,
        Color? types     ,
        Color? comments  ,
        Color? foreground,
        Color? background,
        Color? string    ,
        Color? stringEscape
        })  
        :
        keyword      = keyword      ?? const Color(0xFF000000),
        types        = types        ?? const Color(0xFF000000),
        comments     = comments     ?? const Color(0xFF000000),
        foreground   = foreground   ?? const Color(0xFF000000),
        background   = background   ?? const Color(0xFF000000),
        string       = string       ?? const Color(0xFF000000),
        stringEscape = stringEscape ?? const Color(0xFF000000);
}

class Themes {
    //TODO(jpm): actually match colourschemes everywhere
    static final materialDark  = ThemeData.dark();
    static final materialLight = ThemeData.light();
    
    static final tabbedViewLight = TabbedViewThemeData.mobile();

    static final tabbedViewDark  = TabbedViewThemeData.mobile(colorSet: themeToMaterialColor(codeDracula));

    static final codeDracula = CodeTheme(
        keyword     : const Color(0xFFFF79C6),
        types       : const Color(0xFF8be9fd),
        comments    : const Color(0xFF6272A4),
        foreground  : const Color(0xFFF8F8F2),
        background  : const Color(0xFF282A36),
        string      : const Color(0xFFF1FA8C),
        stringEscape: const Color(0xFFFF5555)
    );
    
    static final codeLight = CodeTheme(
        keyword     : const Color(0xFFFF79C6),
        types       : const Color(0xFF8B7DFD),
        comments    : const Color(0xFF49567A),
        foreground  : const Color(0xFFF8F8F2),
        background  : const Color(0xFF282A36),
        string      : const Color(0xFF53B061),
        stringEscape: const Color(0xFFFF5555)
    );

    static MaterialColor themeToMaterialColor(CodeTheme theme) {
        // Color borderColor = colorSet[500]!;
        // Color foregroundColor = colorSet[900]!;
        // Color backgroundColor = colorSet[50]!;
        // Color menuColor = colorSet[100]!;
        // Color menuHoverColor = colorSet[300]!;
        // Color normalButtonColor = colorSet[700]!;
        // Color disabledButtonColor = colorSet[300]!;
        // Color hoverButtonColor = colorSet[900]!;
        // Color highlightedColor = colorSet[300]!
        return MaterialColor(0, {
            500: theme.comments,
            900: theme.foreground,
            50 : theme.background,
            100: const Color(0xFF000000),
            300: const Color(0xFF6D6D6D),
            700: const Color(0xFF888888),
        });
    }
}
