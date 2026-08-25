class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ingresa tu correo';
    if (!_emailRegex.hasMatch(text)) return 'Correo inválido';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Ingresa tu contraseña';
    if (text.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  static String? notEmpty(String? value, {String message = 'Este campo es obligatorio'}) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  static String? positiveNumber(String? value, {String message = 'Ingresa un número válido'}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return message;
    final number = num.tryParse(text);
    if (number == null || number <= 0) return message;
    return null;
  }
}
