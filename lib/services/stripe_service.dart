
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StripeService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<void> createStripeAccount(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to connect a Stripe account.')),
      );
      return;
    }

    try {
      final callable = _functions.httpsCallable('createStripeAccount');
      final response = await callable.call<Map<String, dynamic>>({
        'accountType': 'express',
      });

      final data = response.data;
      if (data.containsKey('accountLinkUrl')) {
        // In a real app, you would open this URL in a webview or browser.
        // For this example, we'll just print the URL.
        print('Stripe Account Onboarding URL: ${data['accountLinkUrl']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stripe account creation initiated. Check the console for the onboarding URL.')),
        );
      } else {
        throw Exception('Failed to get account link.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating Stripe account: $e')),
      );
    }
  }
}
