import 'package:flutter/material.dart'; 

 

void main() => runApp(FormApp()); 

 

class FormApp extends StatelessWidget { 

  @override 

  Widget build(BuildContext context) { 

    return MaterialApp( 

      home: Scaffold( 

        appBar: AppBar(title: Text('Interactive Form')), 

        body: Padding( 

          padding: const EdgeInsets.all(16.0), 

          child: UserForm(), 

        ), 

      ), 

    ); 

  } 

} 

 

class UserForm extends StatefulWidget { 

  @override 

  _UserFormState createState() => _UserFormState(); 

} 

 

class _UserFormState extends State<UserForm> { 

  final _formKey = GlobalKey<FormState>(); 

  final _nameController = TextEditingController(); 

  final _emailController = TextEditingController(); 

 

  @override 

  Widget build(BuildContext context) { 

    return Form( 

      key: _formKey, 

      child: Column( 

        children: [ 

          TextFormField( 

            controller: _nameController, 

            decoration: InputDecoration(labelText: 'Name'), 

            validator: (value) => 

                value!.isEmpty ? 'Please enter your name' : null, 

          ), 

          TextFormField( 

            controller: _emailController, 

            decoration: InputDecoration(labelText: 'Email'), 

            validator: (value) => 

                value!.isEmpty ? 'Please enter your email' : null, 

          ), 

          SizedBox(height: 20), 

          ElevatedButton( 

            onPressed: () { 

              if (_formKey.currentState!.validate()) { 

                ScaffoldMessenger.of(context).showSnackBar( 

                  SnackBar( 

                    content: Text( 

                        'Form Submitted! Name: ${_nameController.text}, Email: ${_emailController.text}'), 

                  ), 

                ); 

              } 

            }, 

            child: Text('Submit'), 

          ), 

        ], 

      ), 

    ); 

  } 

} 

 