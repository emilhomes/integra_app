class AppValidators {
  static String? validarCampoObrigatorio(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  static String? validarNome(String? valor) {
    if (valor == null || valor.isEmpty) {
      return 'Nome é obrigatório';
    }
    if (valor.trim().split(' ').length < 2) {
      return 'Informe o nome completo';
    }
    if (valor.length < 3) {
      return 'O nome deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  static String? validarEmail(String? valor) {
    if (valor == null || valor.isEmpty) return 'E-mail obrigatório';
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(valor);
    if (!emailValid) return 'E-mail inválido';
    return null;
  }

  static String? validarCPF(String? valor) {
    if (valor == null || valor.isEmpty) return 'CPF obrigatório';
    final cleanCPF = valor.replaceAll(RegExp(r'\D'), '');
    if (cleanCPF.length != 11) return 'CPF deve ter 11 dígitos';
    // Validação básica de dígitos repetidos
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCPF)) return 'CPF inválido';
    return null;
  }

  static String? validarTelefone(String? valor) {
    if (valor == null || valor.isEmpty) return 'Telefone obrigatório';
    final cleanPhone = valor.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length < 10) return 'Telefone deve ter pelo menos 10 dígitos';
    return null;
  }
}
