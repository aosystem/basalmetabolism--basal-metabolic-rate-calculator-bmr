import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:basalmetabolism/app_localizations.dart';
import 'package:basalmetabolism/app_settings.dart';
import 'package:basalmetabolism/settings_page.dart';
import 'package:basalmetabolism/ad_manager.dart';
import 'package:basalmetabolism/ad_banner_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  ));
  final settings = AppSettings();
  await settings.load();
  runApp(MyApp(settings: settings));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.settings,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Basal Metabolism',
          locale: widget.settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: widget.settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: HomePage(settings: widget.settings),
        );
      },
    );
  }
}

enum Gender { male, female }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AdManager _adManager;
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  Gender _gender = Gender.male;
  bool _restoring = false;
  BmrResultSet _resultSetA = BmrResultSet.zero;
  BmrResultSet _resultSetB = BmrResultSet.zero;

  static const _heightKey = 'valueHeight';
  static const _weightKey = 'valueWeight';
  static const _ageKey = 'valueAge';
  static const _genderKey = 'valueGender';

  @override
  void initState() {
    super.initState();
    _adManager = AdManager();
    _heightController.addListener(_onInputChanged);
    _weightController.addListener(_onInputChanged);
    _ageController.addListener(_onInputChanged);
    _restoreInputs();
  }

  @override
  void dispose() {
    _adManager.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _restoreInputs() {
    final prefs = widget.settings.prefs;
    _restoring = true;
    _heightController.text = prefs.getString(_heightKey) ?? '';
    _weightController.text = prefs.getString(_weightKey) ?? '';
    _ageController.text = prefs.getString(_ageKey) ?? '';
    final genderValue = prefs.getString(_genderKey) ?? '1';
    _gender = genderValue == '2' ? Gender.female : Gender.male;
    _restoring = false;
    _updateResults();
  }

  void _onInputChanged() {
    _updateResults();
  }

  void _onGenderChanged(Gender newGender) {
    if (newGender == _gender) {
      return;
    }
    setState(() {
      _gender = newGender;
    });
    _updateResults();
  }

  void _updateResults() {
    if (_restoring) {
      return;
    }
    final height = int.tryParse(_heightController.text) ?? 0;
    final weight = int.tryParse(_weightController.text) ?? 0;
    final age = int.tryParse(_ageController.text) ?? 0;

    final setA = BmrCalculator.calculateSetA(
      height: height,
      weight: weight,
      age: age,
      gender: _gender,
    );
    final setB = BmrCalculator.calculateSetB(
      height: height,
      weight: weight,
      age: age,
      gender: _gender,
    );

    setState(() {
      _resultSetA = setA;
      _resultSetB = setB;
    });

    unawaited(
      widget.settings.saveUserInputs(
        height: _heightController.text,
        weight: _weightController.text,
        age: _ageController.text,
        gender: _gender == Gender.male ? 1 : 2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final levelDescriptions = <String>[
      l.basalDefinition,
      l.calorieLevelADescription,
      l.calorieLevelBDescription,
      l.calorieLevelCDescription,
    ];

    final brightness = theme.brightness;
    final showBackgroundImage = widget.settings.showBackgroundImage;
    final backgroundAsset = brightness == Brightness.dark
        ? 'assets/image/back_dark.png'
        : 'assets/image/back.png';
    final decorationImage = showBackgroundImage
        ? DecorationImage(
            image: AssetImage(backgroundAsset),
            repeat: ImageRepeat.repeat,
          )
        : null;
    final backgroundColor =
        !showBackgroundImage && brightness == Brightness.light
            ? Colors.white
            : Colors.transparent;
    final overlayStyle = (brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent);
    const accentColor = Color(0x9800E1FF);
    final accentForeground =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
            ? Colors.white
            : Colors.black;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        image: decorationImage,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          systemOverlayStyle: overlayStyle,
          title: Text(l.appTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsPage(settings: widget.settings),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNumberField(
                    controller: _heightController,
                    label: l.heightLabel,
                    unit: l.heightUnit,
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField(
                    controller: _weightController,
                    label: l.weightLabel,
                    unit: l.weightUnit,
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField(
                    controller: _ageController,
                    label: l.ageLabel,
                    unit: l.ageUnit,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          l.genderLabel,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<Gender>(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return accentColor;
                              }
                              return null;
                            }),
                            foregroundColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return accentForeground;
                              }
                              return null;
                            }),
                            overlayColor:
                                WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.pressed)) {
                                return accentColor.withValues(alpha: 0.2);
                              }
                              return accentColor.withValues(alpha: 0.12);
                            }),
                            side: WidgetStateProperty.resolveWith((states) {
                              final color = states.contains(WidgetState.selected)
                                  ? accentColor
                                  : colorScheme.outline;
                              return BorderSide(color: color);
                            }),
                          ),
                          segments: [
                            ButtonSegment(
                                value: Gender.male, label: Text(l.male)),
                            ButtonSegment(
                              value: Gender.female,
                              label: Text(l.female),
                            ),
                          ],
                          selected: <Gender>{_gender},
                          onSelectionChanged: (selection) {
                            if (selection.isEmpty) {
                              return;
                            }
                            _onGenderChanged(selection.first);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildResultCard(
                    intro: l.setAIntro,
                    result: _resultSetA,
                    localization: l,
                    descriptions: levelDescriptions,
                    formulaNote: l.setAFormulaNote,
                  ),
                  const SizedBox(height: 16),
                  _buildResultCard(
                    intro: l.setBIntro,
                    result: _resultSetB,
                    localization: l,
                    descriptions: levelDescriptions,
                    formulaNote: l.setBFormulaNote,
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          )
        ),
        bottomNavigationBar: AdBannerWidget(adManager: _adManager),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String unit,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: textTheme.bodyLarge,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              suffixText: unit,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({
    required String intro,
    required BmrResultSet result,
    required AppLocalizations localization,
    required List<String> descriptions,
    required String formulaNote,
  }) {
    String descriptionAt(int index) =>
        index < descriptions.length ? descriptions[index] : '';

    final entries = <_ResultEntry>[
      _ResultEntry(
        label: localization.basalLabel,
        value: result.basal,
        description: descriptionAt(0),
      ),
      _ResultEntry(
        label: localization.level15Label,
        value: result.level15,
        description: descriptionAt(1),
      ),
      _ResultEntry(
        label: localization.level175Label,
        value: result.level175,
        description: descriptionAt(2),
      ),
      _ResultEntry(
        label: localization.level20Label,
        value: result.level20,
        description: descriptionAt(3),
      ),
    ];

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final cardColor = theme.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.8);

    return Card(
      color: cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(intro, style: textTheme.titleMedium),
            const SizedBox(height: 16),
            for (var i = 0; i < entries.length; i++) ...[
              _buildResultRow(
                entries[i].label,
                entries[i].value,
                localization,
                description: entries[i].description,
              ),
              if (i != entries.length - 1) const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Text(
              formulaNote,
              style: textTheme.bodySmall ?? textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    int value,
    AppLocalizations localization, {
    String? description,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final descriptionStyle = textTheme.bodySmall ?? textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: textTheme.titleMedium)),
            Text('${value.toString()} ${localization.kcalSuffix}',
                style: textTheme.titleMedium),
          ],
        ),
        if (description != null && description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(description, style: descriptionStyle),
          ),
      ],
    );
  }
}

class _ResultEntry {
  const _ResultEntry({
    required this.label,
    required this.value,
    required this.description,
  });

  final String label;
  final int value;
  final String description;
}

class BmrResultSet {
  const BmrResultSet({
    required this.basal,
    required this.level15,
    required this.level175,
    required this.level20,
  });

  final int basal;
  final int level15;
  final int level175;
  final int level20;

  static const BmrResultSet zero = BmrResultSet(
    basal: 0,
    level15: 0,
    level175: 0,
    level20: 0,
  );
}

class BmrCalculator {
  static BmrResultSet calculateSetA({
    required int height,
    required int weight,
    required int age,
    required Gender gender,
  }) {
    final double rawBase = gender == Gender.male
        ? 66.4730 + (13.7516 * weight) + (5.0033 * height) - (6.7550 * age)
        : 655.0955 + (9.5634 * weight) + (1.8496 * height) - (4.6756 * age);
    final int base = rawBase.toInt();
    final int level15 = (base * 1.5).toInt();
    final int level175 = (base * 1.75).toInt();
    final int level20 = (base * 2).toInt();
    return BmrResultSet(
      basal: base,
      level15: level15,
      level175: level175,
      level20: level20,
    );
  }

  static BmrResultSet calculateSetB({
    required int height,
    required int weight,
    required int age,
    required Gender gender,
  }) {
    final double baseTerm =
        0.1238 + (0.0481 * weight) + (0.0234 * height) - (0.0138 * age);
    final double rawBase = gender == Gender.male
        ? ((baseTerm - 0.5473) * 1000) / 4.186
        : ((baseTerm - (0.5473 * 2)) * 1000) / 4.186;
    final int base = rawBase.toInt();
    final int level15 = (base * 1.5).toInt();
    final int level175 = (base * 1.75).toInt();
    final int level20 = (base * 2).toInt();
    return BmrResultSet(
      basal: base,
      level15: level15,
      level175: level175,
      level20: level20,
    );
  }
}
