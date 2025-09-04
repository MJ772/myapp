
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ListVehicleForRentScreen extends StatefulWidget {
  const ListVehicleForRentScreen({super.key});

  @override
  State<ListVehicleForRentScreen> createState() =>
      _ListVehicleForRentScreenState();
}

class _ListVehicleForRentScreenState extends State<ListVehicleForRentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _make = '';
  String _model = '';
  double _pricePerDay = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List Vehicle for Rent')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Make'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the make' : null,
                onSaved: (value) => _make = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Model'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the model' : null,
                onSaved: (value) => _model = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Price per Day'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter the price' : null,
                onSaved: (value) => _pricePerDay = double.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();

                    await FirebaseFirestore.instance.collection('rentals').add({
                      'vehicle': {
                        'make': _make,
                        'model': _model,
                      },
                      'pricePerDay': _pricePerDay,
                      'garageId': FirebaseAuth.instance.currentUser!.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  }
                },
                child: const Text('List Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
