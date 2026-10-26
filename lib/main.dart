import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data.dart';
import 'widgets.dart';
import 'pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(const MaterialApp(home: ConfigurationPage()));
    return;
  }
  try {
    await Supabase.initialize(url: url, publishableKey: key);
    runApp(const BrasisApp());
  } catch (_) {
    runApp(const MaterialApp(home: ConfigurationPage()));
  }
}

class ConfigurationPage extends StatelessWidget {
  const ConfigurationPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RegionalArt(region: 2),
              const Text(
                'Seu embarque está quase pronto!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: forest,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Preencha SUPABASE_URL e SUPABASE_ANON_KEY no config.json e reinicie com --dart-define-from-file=config.json. O README explica o passo a passo.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AuthRefresh extends ChangeNotifier {
  late final StreamSubscription<AuthState> subscription;
  AuthRefresh() {
    subscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => notifyListeners(),
    );
  }
  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}

class BrasisApp extends StatefulWidget {
  const BrasisApp({super.key});
  @override
  State<BrasisApp> createState() => _BrasisAppState();
}

class _BrasisAppState extends State<BrasisApp> {
  late final AuthRefresh refresh;
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    refresh = AuthRefresh();
    router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: refresh,
      redirect: (context, state) {
        final logged = Supabase.instance.client.auth.currentSession != null;
        final path = state.uri.path;
        if (path == '/splash') return null;
        final access = path == '/login' || path == '/register';
        if (!logged && !access) return '/login';
        if (logged && access) return '/home';
        return null;
      },
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Este caminho não existe. Voltar à jornada'),
          ),
        ),
      ),
      routes: [
        GoRoute(path: '/splash', builder: (_, state) => const SplashPage()),
        GoRoute(path: '/login', builder: (_, state) => const AccessPage()),
        GoRoute(
          path: '/register',
          builder: (_, state) => const AccessPage(register: true),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(path: state.uri.path, child: child),
          routes: [
            GoRoute(path: '/home', builder: (_, state) => const HomePage()),
            GoRoute(
              path: '/region/:order',
              builder: (_, state) => RegionPage(
                order: int.tryParse(state.pathParameters['order'] ?? '') ?? 0,
              ),
            ),
            GoRoute(
              path: '/mission/:id',
              builder: (_, state) => MissionPage(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
            GoRoute(
              path: '/achievements',
              builder: (_, state) => const AchievementsPage(),
            ),
            GoRoute(
              path: '/ranking',
              builder: (_, state) => const RankingPage(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    router.dispose();
    refresh.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'BRASIS · Uma jornada de histórias e culturas',
    debugShowCheckedModeBanner: false,
    routerConfig: router,
    theme: brasisTheme,
  );
}

final brasisTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  fontFamily: 'Nunito',
  colorScheme: ColorScheme.fromSeed(
    seedColor: forest,
    primary: forest,
    secondary: sun,
    surface: paper,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: paper,
    foregroundColor: ink,
    scrolledUnderElevation: 0,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFCCD3BF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFCCD3BF), width: 1.5),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: forest,
      foregroundColor: cream,
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
    ),
  ),
  snackBarTheme: const SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    backgroundColor: ink,
  ),
);

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  late final AnimationController animation;
  @override
  void initState() {
    super.initState();
    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        context.go(
          Supabase.instance.client.auth.currentSession == null
              ? '/login'
              : '/home',
        );
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: cream,
    body: Center(
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 230,
              height: 230,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 22),
            const Sticker(
              'UM PAÍS. INFINITAS DESCOBERTAS.',
              color: sun,
              icon: Icons.explore_rounded,
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Uma jornada de histórias e culturas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: forest, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: forest, strokeWidth: 3),
            ),
          ],
        ),
      ),
    ),
  );
}

class AccessPage extends StatefulWidget {
  final bool register;
  const AccessPage({super.key, this.register = false});
  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      nickname = TextEditingController();
  bool busy = false, hidden = true;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    nickname.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (widget.register) {
        final result = await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'nickname': nickname.text.trim()},
        );
        if (mounted && result.session == null) {
          setState(
            () => message = 'Seu embarque foi solicitado! Confirme o e-mail recebido e depois entre na sua conta.',
          );
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      if (mounted) setState(() => message = friendlyError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: paper,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 470),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(26, 18, 26, 30),
            child: AutofillGroup(
              child: Form(
                key: form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Image.asset('assets/logo.png', width: 65, height: 65),
                        const Spacer(),
                        const Sticker('BORA DESCOBRIR?', color: cream),
                      ],
                    ),
                    const RegionalArt(region: 2, height: 180),
                    Text(
                      widget.register
                          ? 'Seu passaporte\npara muitos Brasis.'
                          : 'O próximo destino?\nUma boa história.',
                      style: const TextStyle(
                        fontSize: 32,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: ink,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Viaje pelas regiões, complete missões e colecione descobertas.',
                      style: TextStyle(color: muted, height: 1.5),
                    ),
                    const SizedBox(height: 25),
                    if (widget.register) ...[
                      TextFormField(
                        controller: nickname,
                        maxLength: 40,
                        decoration: const InputDecoration(
                          labelText: 'Como quer ser chamado?',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) => (v?.trim().length ?? 0) < 2
                            ? 'Use pelo menos 2 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Seu e-mail',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Informe um e-mail válido.',
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: password,
                      obscureText: hidden,
                      autofillHints: [
                        widget.register
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Sua senha',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: hidden ? 'Mostrar senha' : 'Ocultar senha',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      onFieldSubmitted: (_) {
                        if (!busy) submit();
                      },
                      validator: (v) =>
                          (v?.length ?? 0) < (widget.register ? 8 : 1)
                          ? (widget.register
                                ? 'Use pelo menos 8 caracteres.'
                                : 'Informe sua senha.')
                          : null,
                    ),
                    const SizedBox(height: 25),
                    if (message != null) ...[
                      Text(
                        message!,
                        style: const TextStyle(color: forest, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],
                    GameButton(
                      label: widget.register
                          ? 'Criar meu passaporte'
                          : 'Bora viajar!',
                      onPressed: busy ? null : submit,
                      busy: busy,
                      icon: Icons.flight_takeoff_rounded,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => context.go(
                              widget.register ? '/login' : '/register',
                            ),
                      child: Text(
                        widget.register
                            ? 'Já tenho passaporte. Entrar'
                            : 'Primeira viagem? Criar uma conta',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatelessWidget {
  final String path;
  final Widget child;
  const AppShell({super.key, required this.path, required this.child});
  @override
  Widget build(BuildContext context) {
    final index = path.startsWith('/achievements')
        ? 1
        : path.startsWith('/ranking')
        ? 2
        : path.startsWith('/profile')
        ? 3
        : 0;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 43,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 9),
            const Text(
              'BRASIS',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: forest,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: IconButton.filledTonal(
              tooltip: 'Meu passaporte',
              style: IconButton.styleFrom(
                backgroundColor: cream,
                foregroundColor: forest,
              ),
              onPressed: () => context.go('/profile'),
              icon: const Icon(Icons.face_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE3E6D8), width: 1.5)),
        ),
        child: NavigationBar(
          height: 76,
          backgroundColor: paper,
          indicatorColor: sun,
          selectedIndex: index,
          onDestinationSelected: (i) =>
              context.go(['/home', '/achievements', '/ranking', '/profile'][i]),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore_rounded),
              label: 'Jornada',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Passaporte',
            ),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              selectedIcon: Icon(Icons.emoji_events_rounded),
              label: 'Ranking',
            ),
            NavigationDestination(
              icon: Icon(Icons.face_outlined),
              selectedIcon: Icon(Icons.face_rounded),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
