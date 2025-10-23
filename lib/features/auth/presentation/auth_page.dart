import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:locally/common/providers/auth_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLogin = true; // toggle between login and signup

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> _submit() async {
    final authService = ref.read(authServiceProvider);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return;
    }

    final result = isLogin
        ? await authService.signIn(email: email, password: password)
        : await authService.signUp(email: email, password: password);

    result.match(
      (error) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $error'))),
      (user) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isLogin
                ? 'Logged in as ${user.email}'
                : 'Signed up as ${user.email}',
          ),
        ),
      ),
    );
  }

  void _loginDefault() {
    emailController.text = "bhsudhanva@gmail.com";
    passwordController.text = "Test@123";
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: _loginDefault, icon: Icon(Icons.login)),
        ],
        title: Text(isLogin ? 'Login' : 'Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              child: Text(isLogin ? 'Login' : 'Sign Up'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _toggleMode,
              child: Text(
                isLogin
                    ? 'Don\'t have an account? Sign Up'
                    : 'Already have an account? Login',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
