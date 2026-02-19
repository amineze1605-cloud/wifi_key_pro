import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const WifiKeyPro());
}

class WifiKeyPro extends StatelessWidget {
  const WifiKeyPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WiFi Key Pro',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
      ),
      home: const GeneratorPage(),
    );
  }
}

enum BoxFormat { classic, livebox, sfr, freebox, numeric }

class GeneratorPage extends StatefulWidget {
  const GeneratorPage({super.key});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  String password = '';
  double length = 12;
  bool includeLowercase = false;
  bool includeSymbols = false;
  String prefix = '';
  BoxFormat format = BoxFormat.classic;
  List<String> history = [];

  final upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  final lower = 'abcdefghijklmnopqrstuvwxyz';
  final numbers = '0123456789';
  final symbols = '!@#\$%&*';

  @override
  void initState() {
    super.initState();
    loadHistory();
    generate();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    history = prefs.getStringList('history') ?? [];
    setState(() {});
  }

  Future<void> saveHistory(String value) async {
    final prefs = await SharedPreferences.getInstance();
    history.insert(0, value);
    if (history.length > 20) history.removeLast();
    await prefs.setStringList('history', history);
  }

  String applyFormat(String raw) {
    switch (format) {
      case BoxFormat.livebox:
        return 'Livebox_$raw';
      case BoxFormat.sfr:
        return raw.replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m.group(0)}-')
            .replaceAll(RegExp(r'-$'), '');
      case BoxFormat.freebox:
        return raw.replaceAllMapped(RegExp(r'.{1,2}'), (m) => '${m.group(0)}:')
            .replaceAll(RegExp(r':$'), '');
      case BoxFormat.numeric:
        return raw;
      default:
        return raw.replaceAllMapped(RegExp(r'.{1,4}'), (m) => '${m.group(0)}-')
            .replaceAll(RegExp(r'-$'), '');
    }
  }

  String generatePassword(int len) {
    final random = Random.secure();
    String chars = upper + numbers;

    if (includeLowercase) chars += lower;
    if (includeSymbols) chars += symbols;
    if (format == BoxFormat.numeric) chars = numbers;

    String raw = List.generate(
      len,
      (index) => chars[random.nextInt(chars.length)],
    ).join();

    return prefix + applyFormat(raw);
  }

  void generate() {
    setState(() {
      password = generatePassword(length.toInt());
      saveHistory(password);
    });
  }

  int strengthScore() {
    int score = 0;
    if (password.length >= 12) score++;
    if (includeLowercase) score++;
    if (includeSymbols) score++;
    if (password.length >= 16) score++;
    return score;
  }

  String strengthLabel() {
    switch (strengthScore()) {
      case 4:
        return "Très fort 🔥";
      case 3:
        return "Fort 💪";
      case 2:
        return "Moyen ⚖️";
      default:
        return "Faible ⚠️";
    }
  }

  Color strengthColor() {
    switch (strengthScore()) {
      case 4:
        return Colors.green;
      case 3:
        return Colors.lightGreen;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  void copyPassword() {
    Clipboard.setData(ClipboardData(text: password));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [

            Text("WiFi Key Pro",
                style: theme.textTheme.headlineMedium),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  SelectableText(
                    password,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: strengthScore() / 4,
                    color: strengthColor(),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 6),
                  Text(strengthLabel())
                ],
              ),
            ),

            const SizedBox(height: 25),

            Center(
              child: QrImageView(
                data: "WIFI:T:WPA;S:MonWiFi;P:$password;;",
                size: 180,
              ),
            ),

            const SizedBox(height: 25),

            Text("Longueur : ${length.toInt()}"),
            Slider(
              value: length,
              min: 8,
              max: 32,
              divisions: 24,
              onChanged: (v) => setState(() => length = v),
            ),

            SwitchListTile(
              title: const Text("Inclure minuscules"),
              value: includeLowercase,
              onChanged: (v) => setState(() => includeLowercase = v),
            ),

            SwitchListTile(
              title: const Text("Inclure symboles"),
              value: includeSymbols,
              onChanged: (v) => setState(() => includeSymbols = v),
            ),

            DropdownButton<BoxFormat>(
              value: format,
              onChanged: (v) => setState(() => format = v!),
              items: const [
                DropdownMenuItem(
                    value: BoxFormat.classic,
                    child: Text("Classique (XXXX-XXXX)")),
                DropdownMenuItem(
                    value: BoxFormat.livebox,
                    child: Text("Livebox_XXXX")),
                DropdownMenuItem(
                    value: BoxFormat.sfr,
                    child: Text("SFR XXXX-XXXX")),
                DropdownMenuItem(
                    value: BoxFormat.freebox,
                    child: Text("Freebox XX:XX:XX")),
                DropdownMenuItem(
                    value: BoxFormat.numeric,
                    child: Text("100% Numérique")),
              ],
            ),

            TextField(
              decoration: const InputDecoration(
                  labelText: "Préfixe personnalisé"),
              onChanged: (v) => prefix = v,
            ),

            const SizedBox(height: 15),

            FilledButton(
              onPressed: generate,
              child: const Text("Générer"),
            ),

            const SizedBox(height: 10),

            OutlinedButton(
              onPressed: copyPassword,
              child: const Text("Copier"),
            ),

            const SizedBox(height: 30),

            Text("Historique récent",
                style: theme.textTheme.titleMedium),

            ...history.take(5).map((e) => Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4),
                  child: Text(e),
                )),
          ],
        ),
      ),
    );
  }
}
