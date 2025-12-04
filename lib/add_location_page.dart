import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Zakładam, że ten plik i klasa istnieją i zawierają statyczną metodę getToken()
import 'services/token_service.dart'; 

class ParentLocation {
  final int id;
  final String name;

  ParentLocation({required this.id, required this.name});
  
  factory ParentLocation.fromJson(Map<String, dynamic> json) {
    return ParentLocation(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

enum LocationType { WAREHOUSE, RACK, SHELF }

class AddLocationPage extends StatefulWidget {
  const AddLocationPage({super.key});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();

  String _name = '';
  LocationType? _selectedType;
  int? _selectedParentId; 

  final String _apiUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/locations';
  
  List<ParentLocation> _parentLocations = [];
  bool _isLoadingParents = true;
  String? _parentLoadError;

  @override
  void initState() {
    super.initState();
    _fetchParentLocations();
  }
  
  Future<void> _fetchParentLocations() async {
    final token = await TokenService.getToken(); // Użycie TokenService

    if (token == null) {
      setState(() {
        _parentLoadError = "Brak tokena autoryzacji.";
        _isLoadingParents = false;
      });
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(_apiUrl), headers: headers);
      
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> jsonList = json.decode(response.body);
          
          setState(() {
            _parentLocations = [
              ParentLocation(id: 0, name: "Brak lokalizacji rodzica (Główna)"), 
              ...jsonList.map((item) => ParentLocation.fromJson(item)).toList(),
            ];
            _selectedParentId = 0; 
            _isLoadingParents = false;
          });

        } else {
          setState(() {
            _parentLoadError = 'Nie udało się załadować lokalizacji rodzica: ${response.statusCode}';
            _isLoadingParents = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _parentLoadError = 'Błąd sieci podczas ładowania lokalizacji: $e';
          _isLoadingParents = false;
        });
      }
    }
  }


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final int? finalParentId = (_selectedParentId == 0) ? null : _selectedParentId;

      final Map<String, dynamic> locationData = {
        'name': _name,
        'locationType': _selectedType.toString().split('.').last,
        'parentId': finalParentId,
      };
      
      final token = await TokenService.getToken(); // Użycie TokenService
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Błąd: Wymagane jest zalogowanie.')),
        );
        return; 
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      try {
        final response = await http.post(
          Uri.parse(_apiUrl),
          headers: headers,
          body: json.encode(locationData),
        );

        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lokalizacja dodana pomyślnie!')),
          );
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd dodawania: ${response.statusCode} - ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd sieci: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj Nową Lokalizację'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nazwa Lokalizacji',
                  hintText: 'Np. Magazyn Główny A',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nazwa jest wymagana.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _name = value!;
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<LocationType>(
                decoration: const InputDecoration(
                  labelText: 'Typ Lokalizacji',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                hint: const Text('Wybierz typ (WAREHOUSE, RACK, SHELF)'),
                items: LocationType.values.map((LocationType type) {
                  final String display = type.toString().split('.').last;
                  return DropdownMenuItem<LocationType>(
                    value: type,
                    child: Text(display),
                  );
                }).toList(),
                onChanged: (LocationType? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Wybór typu jest wymagany.';
                  }
                  return null;
                },
                onSaved: (value) {
                  _selectedType = value;
                },
              ),
              const SizedBox(height: 20),

              _isLoadingParents
                  ? const Center(child: CircularProgressIndicator())
                  : _parentLoadError != null
                      ? Text(_parentLoadError!, style: const TextStyle(color: Colors.red))
                      : DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Lokalizacja Rodzica (opcjonalne)',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedParentId,
                          hint: const Text('Wybierz lokalizację nadrzędną'),
                          items: _parentLocations.map((loc) {
                            return DropdownMenuItem<int>(
                              value: loc.id,
                              child: Text(loc.name),
                            );
                          }).toList(),
                          onChanged: (int? newValue) {
                            setState(() {
                              _selectedParentId = newValue;
                            });
                          },
                          onSaved: (value) {
                            _selectedParentId = value;
                          },
                        ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'DODAJ LOKALIZACJĘ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}