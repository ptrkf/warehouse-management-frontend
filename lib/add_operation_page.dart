import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SimpleItem {
  final int id;
  final String name;
  SimpleItem({required this.id, required this.name});
  factory SimpleItem.fromJson(Map<String, dynamic> json) {
    return SimpleItem(id: json['id'] as int, name: json['name'] as String);
  }
}

enum MovementType { INBOUND, OUTBOUND }

class StockMovementRequest {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  int? productId;
  int? locationId;
  int? quantity;
  MovementType? type;
}

class TokenManager {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_bearer_token';

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}

class AddStockMovementsPage extends StatefulWidget {
  const AddStockMovementsPage({super.key});

  @override
  State<AddStockMovementsPage> createState() => _AddStockMovementsPageState();
}

class _AddStockMovementsPageState extends State<AddStockMovementsPage> {
  List<StockMovementRequest> _movementRequests = [StockMovementRequest()];
  
  List<SimpleItem> _products = [];
  List<SimpleItem> _locations = [];
  bool _isLoadingData = true;
  String? _dataLoadError;

  final String _apiMovementsUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/stock-movements';
  final String _apiProductsUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/products';
  final String _apiLocationsUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/locations';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final token = await TokenManager.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _dataLoadError = "Brak tokena autoryzacji.";
          _isLoadingData = false;
        });
      }
      return;
    }

    final headers = {'Authorization': 'Bearer $token'};

    try {
      final responses = await Future.wait([
        http.get(Uri.parse(_apiProductsUrl), headers: headers),
        http.get(Uri.parse(_apiLocationsUrl), headers: headers),
      ]);

      if (mounted) {
        if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
          final List<dynamic> productsJson = json.decode(responses[0].body);
          final List<dynamic> locationsJson = json.decode(responses[1].body);

          setState(() {
            _products = productsJson.map((item) => SimpleItem.fromJson(item)).toList();
            _locations = locationsJson.map((item) => SimpleItem.fromJson(item)).toList();
            _isLoadingData = false;
          });
        } else {
          setState(() {
            _dataLoadError = 'Błąd ładowania danych: Produkty: ${responses[0].statusCode}, Lokalizacje: ${responses[1].statusCode}';
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dataLoadError = 'Błąd sieci podczas ładowania danych: $e';
          _isLoadingData = false;
        });
      }
    }
  }

  void _addMovementField() {
    setState(() {
      _movementRequests.add(StockMovementRequest());
    });
  }

  void _removeMovementField(int index) {
    setState(() {
      if (_movementRequests.length > 1) {
        _movementRequests.removeAt(index);
      }
    });
  }

  void _submitAllForms() async {
    bool allValid = true;
    for (var req in _movementRequests) {
      if (req.formKey.currentState!.validate()) {
        req.formKey.currentState!.save();
      } else {
        allValid = false;
      }
    }

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wypełnij poprawnie wszystkie pola we wszystkich operacjach.')),
      );
      return;
    }

    final token = await TokenManager.getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Błąd: Wymagane jest zalogowanie.')),
      );
      return;
    }
    
    final List<Map<String, dynamic>> payload = _movementRequests.map((req) => {
      'productId': req.productId,
      'locationId': req.locationId,
      'quantity': req.quantity,
      'type': req.type.toString().split('.').last,
    }).toList();

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        Uri.parse(_apiMovementsUrl),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dodano ${_movementRequests.length} operacji pomyślnie!')),
        );
        Navigator.pop(context); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd masowego dodawania: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd sieci: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj Przesunięcia Magazynowe'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _dataLoadError != null
              ? Center(child: Text(_dataLoadError!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _movementRequests.length,
                        itemBuilder: (context, index) {
                          return _buildMovementForm(
                            _movementRequests[index],
                            index,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _addMovementField,
                            icon: const Icon(Icons.add),
                            label: const Text('Dodaj kolejną operację'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _submitAllForms,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'ZATWIERDŹ WSZYSTKIE PRZESUNIĘCIA',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMovementForm(StockMovementRequest request, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: request.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Operacja ${index + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_movementRequests.length > 1)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeMovementField(index),
                    ),
                ],
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<MovementType>(
                decoration: const InputDecoration(
                  labelText: 'Typ Operacji',
                  border: OutlineInputBorder(),
                ),
                value: request.type,
                items: MovementType.values.map((type) {
                  final String display = type.toString().split('.').last;
                  return DropdownMenuItem<MovementType>(
                    value: type,
                    child: Text(display),
                  );
                }).toList(),
                onChanged: (MovementType? newValue) {
                  request.type = newValue;
                },
                validator: (value) => value == null ? 'Wybierz typ.' : null,
                onSaved: (value) => request.type = value,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Produkt',
                  border: OutlineInputBorder(),
                ),
                value: request.productId,
                hint: const Text('Wybierz produkt'),
                items: _products.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  request.productId = newValue;
                },
                validator: (value) => value == null ? 'Wybierz produkt.' : null,
                onSaved: (value) => request.productId = value,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Lokalizacja Docelowa',
                  border: OutlineInputBorder(),
                ),
                value: request.locationId,
                hint: const Text('Wybierz lokalizację'),
                items: _locations.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  request.locationId = newValue;
                },
                validator: (value) => value == null ? 'Wybierz lokalizację.' : null,
                onSaved: (value) => request.locationId = value,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Ilość',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Wprowadź prawidłową ilość.';
                  }
                  return null;
                },
                onSaved: (value) {
                  request.quantity = int.tryParse(value ?? '');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}