import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _countryController = TextEditingController(text: "+91");
  
  bool _showOtp = false;
  bool _isLoading = false;
  String? _verificationId;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _countryController.dispose();
    super.dispose();
  }
  
  // 1. Send Real SMS via Firebase
  void _sendOtp() async {
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid 10-digit number")));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final fullNumber = "${_countryController.text.trim()}${_phoneController.text.trim()}";

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android Auto-Verify (Instant Login)
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) _checkUserAndNavigate();
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        String msg = "Verification Failed";
        if (e.code == 'invalid-phone-number') msg = "Invalid Phone Number";
        if (e.code == 'missing-client-identifier') msg = "Missing SHA-1 Key in Firebase Console";
        
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$msg: ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _showOtp = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP Sent!")));
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!mounted) return;
        _verificationId = verificationId; 
      },
    );
  }

  // 2. Verify Code Manually
  void _verifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter 6-digit Code")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!, 
        smsCode: _otpController.text.trim()
      );

      // Sign In
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        await _checkUserAndNavigate();
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP: $e")));
    }
  }

  // 3. Check Logic: Existing User -> Home, New User -> Signup
  Future<void> _checkUserAndNavigate() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!mounted) return;

        if (doc.exists) {
          // Existing User: Go to Home
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          // New User: Go to Signup
          Navigator.pushNamedAndRemoveUntil(
            context, 
            '/signup', 
            (route) => false, 
            arguments: user.phoneNumber ?? "${_countryController.text} ${_phoneController.text}"
          );
        }
      } catch (e) {
        if (mounted) {
          // If there's an error (like permission denied), try to go to home anyway if user is auth'd
          // This acts as a failsafe for existing users with weird connection issues
           Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: const BackButton(color: Colors.grey)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_showOtp ? "Verification" : "Sign In", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 8),
            Text(_showOtp ? "Enter the code sent to you." : "We will send an OTP to verify.", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            
            if (!_showOtp)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: TextField(controller: _countryController, decoration: const InputDecoration(border: InputBorder.none)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: "Phone Number", border: InputBorder.none, icon: Icon(LucideIcons.phone)),
                      ),
                    ),
                  ],
                ),
              )
            else
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "6-digit Code", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(LucideIcons.lock)),
              ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_showOtp ? _verifyOtp : _sendOtp),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_showOtp ? "Verify & Login" : "Send OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}