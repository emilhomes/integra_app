import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/utils/validators.dart';
import 'bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  late AnimationController _animationController;
  late Animation<double> _riseAnimation;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _riseAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuart,
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _animationController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startLoginAnimation(BuildContext context) {
    setState(() => _isAnimating = true);
    _animationController.forward().then((_) {
      if (context.mounted) {
        context.go('/dashboard');
      }
    });
  }

  void _shakeForm() {
    _shakeController.forward(from: 0).then((_) => _shakeController.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(AuthService()),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSucesso) {
            _startLoginAnimation(context);
          } else if (state is AuthErro) {
            _shakeForm();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.mensagem.contains('password') || state.mensagem.contains('invalid-credential')
                      ? 'E-mail ou senha incorretos'
                      : 'Ocorreu um erro ao entrar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                ),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                // Main Content
                AnimatedBuilder(
                  animation: Listenable.merge([_riseAnimation, _shakeAnimation]),
                  builder: (context, child) {
                    final shakeOffset = Offset(
                      _shakeController.isAnimating 
                          ? (0.5 - (0.5 - _shakeController.value).abs()) * 20 * ( ( ( (10 * _shakeController.value).toInt() % 2 == 0) ? 1 : -1) )
                          : 0,
                      0
                    );

                    return Opacity(
                      opacity: (1.0 - _riseAnimation.value * 2).clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(shakeOffset.dx, -100 * _riseAnimation.value + shakeOffset.dy),
                        child: child,
                      ),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    const Spacer(flex: 3),
                                    // Logo
                                    Image.asset(
                                      'assets/images/Logo.png',
                                      height: 140,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'ÍNTEGRA',
                                      style: GoogleFonts.outfit(
                                        color: AppColors.primary,
                                        fontSize: 44,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'GESTÃO DE PRÁTICAS INTEGRATIVAS',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        color: Colors.grey[500],
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const Spacer(flex: 2),
                                    
                                    // E-mail
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'E-mail',
                                      icon: Icons.email_outlined,
                                      validator: AppValidators.validarEmail,
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Senha
                                    _buildTextField(
                                      controller: _senhaController,
                                      label: 'Senha',
                                      icon: Icons.lock_outline,
                                      isObscure: true,
                                      validator: AppValidators.validarCampoObrigatorio,
                                    ),
                                    const SizedBox(height: 40),
                                    
                                    // Botão Entrar
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: state is AuthCarregando || _isAnimating
                                            ? null
                                            : () {
                                                if (_formKey.currentState!.validate()) {
                                                  context.read<AuthBloc>().add(
                                                        AuthLoginSolicitado(
                                                          _emailController.text,
                                                          _senhaController.text,
                                                        ),
                                                      );
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 4,
                                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                                        ),
                                        child: state is AuthCarregando
                                            ? const SizedBox(
                                                height: 24,
                                                width: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Entrar',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const Spacer(flex: 4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Transition Animation Layer
                AnimatedBuilder(
                  animation: _riseAnimation,
                  builder: (context, child) {
                    final height = MediaQuery.of(context).size.height;
                    
                    // The panel simply rises from bottom to top
                    double panelOffset = (1 - _riseAnimation.value) * height;

                    return Positioned(
                      top: panelOffset,
                      left: 0,
                      right: 0,
                      height: height,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                        ),
                        child: _isAnimating 
                          ? Center(
                              child: FadeTransition(
                                opacity: _riseAnimation,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 80),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Bem-vindo',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Acessando sua conta...',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
