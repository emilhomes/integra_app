class AppValidators {
  static String? obrigatorio(String? value) {
    if (value == null || value.isEmpty) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'E-mail obrigatório';
    final bool emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(value);
    if (!emailValid) return 'E-mail inválido';
    return null;
  }

  static String? cpf(String? value) {
    if (value == null || value.isEmpty) return 'CPF obrigatório';
    if (value.length != 11) return 'CPF deve ter 11 dígitos';
    return null;
  }
}
