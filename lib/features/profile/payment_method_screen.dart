import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nkhani/features/auth/user_model.dart';
import 'package:nkhani/features/auth/user_service.dart';
import 'package:nkhani/features/auth/widgets/app_colors.dart';
import 'package:nkhani/features/subscription/subscription_service.dart';
import 'package:paychangu_flutter/paychangu_flutter.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  static const int _subscriptionAmount = 500;
  static const String _currencyCode = 'MWK';
  static const String _paychanguSecretKey =
      String.fromEnvironment('PAYCHANGU_SECRET_KEY');
  static const String _callbackUrl = 'https://nkhani.app/paychangu/callback';
  static const String _returnUrl = 'https://nkhani.app/paychangu/return';

  final SubscriptionService _subscriptionService = SubscriptionService();
  bool _isProcessing = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _startPayment(AppUser user) async {
    if (_isProcessing) return;

    if (_paychanguSecretKey.isEmpty) {
      _showMessage(
        'Missing PayChangu secret key. Add --dart-define=PAYCHANGU_SECRET_KEY=...',
      );
      return;
    }

    final names = user.name.trim().split(RegExp(r'\s+'));
    final firstName = names.isNotEmpty ? names.first : 'Nkhani';
    final lastName =
        names.length > 1 ? names.sublist(1).join(' ') : 'User';

    final txRef =
        'nkhani_${user.uid}_${DateTime.now().millisecondsSinceEpoch}';

    final paychangu = PayChangu(
      PayChanguConfig(
        secretKey: _paychanguSecretKey,
        isTestMode: true,
      ),
    );

    final request = PaymentRequest(
      txRef: txRef,
      amount: _subscriptionAmount,
      currency: Currency.MWK,
      callbackUrl: _callbackUrl,
      returnUrl: _returnUrl,
      firstName: firstName,
      lastName: lastName,
      email: user.email,
      customization: {
        'title': 'Nkhani Subscription',
        'description': 'Monthly access',
      },
      meta: {
        'userId': user.uid,
        'plan': 'monthly',
      },
    );

    setState(() => _isProcessing = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => paychangu.launchPayment(
            request: request,
            onSuccess: (response) async {
              await _verifyAndActivate(paychangu, txRef, user.uid);
            },
            onError: (message) {
              _showMessage('Payment failed: $message');
            },
            onCancel: () {
              _showMessage('Payment cancelled.');
            },
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _verifyAndActivate(
    PayChangu paychangu,
    String txRef,
    String uid,
  ) async {
    try {
      final verification = await paychangu.verifyTransaction(txRef);
      final isValid = paychangu.validatePayment(
        verification,
        expectedTxRef: txRef,
        expectedCurrency: _currencyCode,
        expectedAmount: _subscriptionAmount,
      );
      if (!isValid) {
        _showMessage('Payment verification failed.');
        return;
      }

      await _subscriptionService.activatePaidSubscription(uid);
      if (!mounted) return;
      _showMessage('Subscription activated.');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Verification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom +
        kBottomNavigationBarHeight +
        16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
      ),
      body: StreamBuilder<AppUser?>(
        stream: UserService().watchUser(firebaseUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('User profile not found.'));
          }

          final user = snapshot.data!;

          return ListView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
            children: [
              _sectionLabel('Subscription'),
              _sectionCard([
                _PaymentTile(
                  icon: Icons.verified,
                  title: 'Monthly subscription',
                  subtitle: 'MWK $_subscriptionAmount / month',
                  trailing: FilledButton(
                    onPressed: _isProcessing ? null : () => _startPayment(user),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Pay with PayChangu'),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _sectionLabel('Other options'),
              _sectionCard([
                _PaymentTile(
                  icon: Icons.account_balance,
                  title: 'Bank transfer',
                  subtitle: 'Coming soon',
                ),
                _PaymentTile(
                  icon: Icons.phone_android,
                  title: 'Mobile money',
                  subtitle: 'Coming soon',
                ),
              ]),
            ],
          );
        },
      ),
    );
  }
}

Widget _sectionLabel(String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    ),
  );
}

class _PaymentTile {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const _PaymentTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });
}

Widget _sectionCard(List<_PaymentTile> items) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          ListTile(
            leading: Icon(items[i].icon, color: AppColors.primary),
            title: Text(
              items[i].title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: items[i].subtitle != null
                ? Text(items[i].subtitle!)
                : null,
            trailing: items[i].trailing,
          ),
          if (i != items.length - 1)
            const Divider(height: 1, indent: 16, endIndent: 16),
        ],
      ],
    ),
  );
}
