import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:basalmetabolism/app_localizations.dart';
import 'package:basalmetabolism/app_settings.dart';
import 'package:basalmetabolism/ad_manager.dart';
import 'package:basalmetabolism/ad_banner_widget.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.settings});

  final AppSettings settings;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeChoice _themeChoice;
  String? _languageCode;
  late bool _showBackgroundImage;
  late AdManager _adManager;
  final _inAppReview = InAppReview.instance;

  @override
  void initState() {
    super.initState();
    _adManager = AdManager();
    _themeChoice = widget.settings.themeChoice;
    _languageCode = widget.settings.locale?.languageCode;
    _showBackgroundImage = widget.settings.showBackgroundImage;
  }

  @override
  void dispose() {
    _adManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final overlayStyle = (brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent);
    final backgroundAsset = brightness == Brightness.dark
        ? 'assets/image/back_dark.png'
        : 'assets/image/back.png';
    final decorationImage = _showBackgroundImage
        ? DecorationImage(
            image: AssetImage(backgroundAsset),
            repeat: ImageRepeat.repeat,
          )
        : null;
    final backgroundColor =
        !_showBackgroundImage && brightness == Brightness.light
            ? Colors.white
            : Colors.transparent;

    final TextTheme t = Theme.of(context).textTheme;
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
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ListTile(
                title: Text(l.languageLabel),
                trailing: DropdownButton<String?>(
                  value: _languageCode,
                  hint: Text(l.systemDefault),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l.systemDefault),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'en',
                      child: Text(l.languageEnglish),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'ja',
                      child: Text(l.languageJapanese),
                    ),
                  ],
                  onChanged: (value) async {
                    setState(() => _languageCode = value);
                    await widget.settings.updateLocale(value);
                  },
                ),
              ),
              ListTile(
                title: Text(l.themeLabel),
                trailing: DropdownButton<ThemeChoice>(
                  value: _themeChoice,
                  items: [
                    DropdownMenuItem(
                      value: ThemeChoice.system,
                      child: Text(l.themeSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemeChoice.light,
                      child: Text(l.themeLight),
                    ),
                    DropdownMenuItem(
                      value: ThemeChoice.dark,
                      child: Text(l.themeDark),
                    ),
                  ],
                  onChanged: (choice) async {
                    if (choice == null) {
                      return;
                    }
                    setState(() => _themeChoice = choice);
                    await widget.settings.updateTheme(choice);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l.showBackgroundLabel),
                value: _showBackgroundImage,
                onChanged: (value) async {
                  setState(() => _showBackgroundImage = value);
                  await widget.settings.updateShowBackgroundImage(value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l.reviewApp),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: Icon(Icons.open_in_new, size: 16),
                    label: Text(l.reviewStore, style: t.bodySmall),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      await _inAppReview.openStoreListing(
                        appStoreId: 'YOUR_APP_STORE_ID',
                      );
                    },
                  )
                ]
              ),
            ],
          ),
        ),
        bottomNavigationBar: AdBannerWidget(adManager: _adManager),
      ),
    );
  }
}
