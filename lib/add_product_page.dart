import 'package:flutter/material.dart';
import 'products_page.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _locationController = TextEditingController();
  final _codeController = TextEditingController();
  final _dimensionsController = TextEditingController();
  
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Elektronika',
    'Meble',
    'Akcesoria',
    'Biuro',
    'Odzież',
    'Narzędzia',
    'Spożywcze',
    'Inne',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _locationController.dispose();
    _codeController.dispose();
    _dimensionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dodaj nowy produkt'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: Text(
              'ZAPISZ',
              style: TextStyle(
                color: _isLoading ? Colors.white54 : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sekcja: Podstawowe informacje
              _buildSectionHeader('Podstawowe informacje', Icons.info),
              const SizedBox(height: 12),
              
              // Nazwa produktu
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nazwa produktu *',
                  hintText: 'np. Laptop Dell XPS 13',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nazwa produktu jest wymagana';
                  }
                  if (value.trim().length < 3) {
                    return 'Nazwa musi mieć co najmniej 3 znaki';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kod produktu
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Kod produktu',
                  hintText: 'np. DELL-XPS13-001',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Kategoria
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategoria *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wybierz kategorię produktu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Opis
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  hintText: 'Szczegółowy opis produktu...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: 24),

              // Sekcja: Magazyn
              _buildSectionHeader('Informacje magazynowe', Icons.warehouse),
              const SizedBox(height: 12),

              // Stan początkowy
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stan początkowy *',
                  hintText: '0',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                  suffixText: 'szt.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wprowadź stan początkowy';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 0) {
                    return 'Wprowadź prawidłową liczbę (≥ 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Minimalny stan
              TextFormField(
                controller: _minStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minimalny stan magazynowy *',
                  hintText: '5',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warning_amber),
                  suffixText: 'szt.',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Wprowadź minimalny stan';
                  }
                  final minStock = int.tryParse(value);
                  if (minStock == null || minStock < 0) {
                    return 'Wprowadź prawidłową liczbę (≥ 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Lokalizacja
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lokalizacja w magazynie *',
                  hintText: 'np. A-1-3 (Magazyn-Regał-Półka)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lokalizacja jest wymagana';
                  }
                  // Prosta walidacja formatu lokalizacji (X-Y-Z)
                  if (!RegExp(r'^[A-Z]-\d+-\d+$').hasMatch(value.trim().toUpperCase())) {
                    return 'Format: A-1-3 (Magazyn-Regał-Półka)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Sekcja: Dodatkowe informacje
              _buildSectionHeader('Dodatkowe informacje', Icons.straighten),
              const SizedBox(height: 12),

              // Wymiary
              TextFormField(
                controller: _dimensionsController,
                decoration: const InputDecoration(
                  labelText: 'Wymiary',
                  hintText: 'np. 30x20x5 cm',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 32),

              // Przyciski akcji
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('ANULUJ'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('DODAJ PRODUKT'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Informacja o polach wymaganych
              Text(
                '* Pola wymagane',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: Colors.blue[200])),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sprawdź poprawność wszystkich pól'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Symulacja zapisywania (2 sekundy)
    await Future.delayed(const Duration(seconds: 2));

    // Tworzenie nowego produktu
    final newProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: _selectedCategory!,
      quantity: int.parse(_quantityController.text),
      location: _locationController.text.trim().toUpperCase(),
      minStock: int.parse(_minStockController.text),
      description: _descriptionController.text.trim().isEmpty 
          ? 'Brak opisu' 
          : _descriptionController.text.trim(),
      code: _codeController.text.trim().isEmpty 
          ? null 
          : _codeController.text.trim().toUpperCase(),
      dimensions: _dimensionsController.text.trim().isEmpty 
          ? null 
          : _dimensionsController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      // Pokazanie sukcesu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produkt "${newProduct.name}" został dodany!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Powrót do listy produktów
      Navigator.of(context).pop(newProduct);
    }
  }
}