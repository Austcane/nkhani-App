import 'package:nkhani/features/auth/user_service.dart';

class SubscriptionService {
  final UserService _userService = UserService();

  Future<void> activatePaidSubscription(String uid) async {
    await Future.delayed(const Duration(seconds: 2));
    await _userService.activateSubscription(uid);
  }
}
