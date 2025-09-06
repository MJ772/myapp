
import 'package:myapp/services/auth_service.dart';

Future<void> createDevUsers() async {
  final authService = AuthService();

  // Admin User
  await authService.createUserWithEmailAndPassword(
    'admin@test.com',
    'password',
    'admin',
  );

  // Garage User
  await authService.createUserWithEmailAndPassword(
    'garage@test.com',
    'password',
    'garage',
  );

  // Chauffeur User
  await authService.createUserWithEmailAndPassword(
    'chauffeur@test.com',
    'password',
    'chauffeur',
  );

  // Courier User
  await authService.createUserWithEmailAndPassword(
    'courier@test.com',
    'password',
    'courier',
  );

  // Support User
  await authService.createUserWithEmailAndPassword(
    'support@test.com',
    'password',
    'support',
  );

  // Customer User
  await authService.createUserWithEmailAndPassword(
    'customer@test.com',
    'password',
    'customer',
  );
}
