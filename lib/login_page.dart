import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  static const Color _primaryColor = Color(0xFF153E75);
  static const Color _fieldColor = Color(0xFFF3F5F8);

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty ||
    (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar( 
        content: Text(
          !_isLogin && name.isEmpty
            ? 'กรุณากรอกชื่อผู้ใช้งาน'
            : 'กรุณากรอกอีเมลและรหัสผ่าน',
        ),
      ),
    );
    return;
  }
    setState(() => _isLoading = true);

    
  
  try {
    if (_isLogin) {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } else {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
    }
  } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'รูปแบบอีเมลไม่ถูกต้อง';
          break;
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          message = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
          break;
        case 'email-already-in-use':
          message = 'อีเมลนี้ถูกใช้งานแล้ว';
          break;
        case 'weak-password':
          message = 'รหัสผ่านควรมีอย่างน้อย 6 ตัวอักษร';
          break;
        default:
          message = 'ดำเนินการไม่สำเร็จ กรุณาลองใหม่ (${e.code})';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9AA3AF),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF7D8795),
        size: 21,
      ),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 150,
                      height: 120,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.travel_explore,
                          size: 90,
                          color: _primaryColor,
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    _isLogin ? 'เข้าสู่ระบบ' : 'สร้างบัญชี',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF202833),
                    ),
                  ),

                  const SizedBox(height: 32),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hint: 'Email address',
                      icon: Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                    hint: 'ชื่อผู้ใช้งาน',
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 16),
              ],

                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isLoading) _submit();
                    },
                    decoration: _inputDecoration(
                      hint: 'Password',
                      icon: Icons.lock_outline,
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _primaryColor,
                        disabledBackgroundColor:
                            _primaryColor.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'เข้าสู่ระบบ' : 'สมัครบัญชี',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFFE1E5EA)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFFE1E5EA)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F2F5),
                        foregroundColor: const Color(0xFF283342),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isLogin ? 'สมัครบัญชี' : 'กลับไปหน้าล็อกอิน',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'By continuing, you agree to our ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        'Terms of Service',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' and ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}