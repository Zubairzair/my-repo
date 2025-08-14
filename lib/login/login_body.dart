import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:formz/formz.dart';
import 'package:vyapar_app/home/home.dart';
import 'package:vyapar_app/config/session_manager.dart';

import 'bloc/login_bloc.dart';

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_usernameController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      // Simple login for now - set session and navigate
      SessionManager().setLOGIN("true");
      SessionManager().setFirstName(_usernameController.text);
      Navigator.pushReplacementNamed(context, "/home");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter username and password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Column(
          children: [
            const SizedBox(height: 50),
            const Text(
              "Sales & Marketing App",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: IconButton(
                constraints: const BoxConstraints(maxHeight: 90),
                icon: Icon(
                  Icons.business,
                  size: 130,
                  color: Colors.blueAccent.shade300,
                ),
                padding: EdgeInsets.zero,
                onPressed: () {},
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Login to Your Account",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
            const SizedBox(height: 30),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 15, bottom: 10),
                child: SizedBox(
                  height: 55,
                  child: TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.person,
                          color: Colors.blueAccent,
                        ),
                        focusColor: Colors.grey,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blueAccent, width: 2.0),
                        ),
                        labelText: 'Username',
                      )),
                )),
            Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, top: 15, bottom: 10),
                child: SizedBox(
                  height: 55,
                  child: TextFormField(
                      controller: _passwordController,
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      obscureText: true,
                      obscuringCharacter: "•",
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.blueAccent,
                        ),
                        focusColor: Colors.grey,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.blueAccent, width: 2.0),
                        ),
                        labelText: 'Password',
                      )),
                )),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Demo Login: Use any username/password",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}