import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'add_product_page.dart';
import 'add_category_page.dart';
import 'add_location_page.dart';
import 'add_stock_movements_page.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/token_service.dart'; 

class Product {
  final int id;
  String name;
  String category;
  int quantity;
  String location; 
  int minStock; 
  String description; 
  final Map<String, int>? dimensions;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.minStock,
    required this.description,
    this.dimensions,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 1. Pobieramy zagnieżdżony obiekt 'product'
    final productData = json['product'] as Map<String, dynamic>? ?? {};
    
    // 2. Pobieramy kategorie z wnętrza 'product'
    final categoriesList = productData['categories'] as List? ?? [];
    String categoryName = 'Nieokreślona';
    if (categoriesList.isNotEmpty) {
      // Zakładamy, że pierwszy element to mapa z polem 'name'
      final firstCat = categoriesList.first;
      if (firstCat is Map<String, dynamic>) {
        categoryName = firstCat['name']?.toString() ?? 'Nieokreślona';
      }
    }
    
    // 3. Pobieramy ilość (quantity) z głównego poziomu DTO
    final quantity = json['quantity'] as int? ?? 0;
    
    // 4. Pobieramy listę nazw lokalizacji z głównego poziomu DTO i łączymy w string
    final locationNamesList = json['locationNames'] as List? ?? [];
    final locationString = locationNamesList.isNotEmpty 
        ? locationNamesList.join(', ') // Np. "A-1, B-2"
        : 'Brak lokalizacji';

    // 5. Pobieramy wymiary z wnętrza 'product'
    Map<String, int>? dimensionsMap;
    if (productData['dimensions'] != null && productData['dimensions'] is Map) {
       final dims = productData['dimensions'];
       dimensionsMap = {
         'x': (dims['x'] as num?)?.toInt() ?? 0,
         'y': (dims['y'] as num?)?.toInt() ?? 0,
         'z': (dims['z'] as num?)?.toInt() ?? 0,
       };
    }

    return Product(
      // ID i Name bierzemy z obiektu 'product'
      id: (productData['id'] as num?)?.toInt() ?? 0,
      name: productData['name']?.toString() ?? 'Brak nazwy',
      
      category: categoryName,
      quantity: quantity, 
      location: locationString, 
      
      // Domyślne wartości dla pól, których nie ma w tym DTO
      minStock: 5, 
      description: 'Brak opisu', 
      
      dimensions: dimensionsMap,
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  final String _apiProductsUrl = 'http://ab-student-22052.uksouth.cloudapp.azure.com:8080/api/products/with-stock';

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await TokenService.getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "Brak tokena autoryzacji. Zaloguj się ponownie.";
          _isLoading = false;
        });
      }
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.get(Uri.parse(_apiProductsUrl), headers: headers);

      if (response.statusCode == 200) {
        // Dekodujemy listę obiektów StockItemLocationDto
        final List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
        
        if (mounted) {
          setState(() {
            _allProducts = jsonList.map((item) => Product.fromJson(item)).toList();
            _filteredProducts = List.from(_allProducts);
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
         if (mounted) {
            setState(() {
              _errorMessage = "Sesja wygasła lub brak autoryzacji. Kod: 401";
              _isLoading = false;
            });
          }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Błąd serwera: ${response.statusCode}';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Błąd połączenia sieciowego: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        return product.name.toLowerCase().contains(query) ||
               product.category.toLowerCase().contains(query) ||
               product.location.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkty w magazynie'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              TokenService.deleteToken(); 
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Szukaj produktów, kategorii lub lokalizacji...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Wszystkie', _allProducts.length, Colors.blue),
                    _buildStatCard('Niski stan', _getLowStockCount(), Colors.orange),
                    _buildStatCard('Kategorie', _getCategoriesCount(), Colors.green),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      )
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            itemCount: _filteredProducts.length,
                            padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 80),
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return _buildProductCard(product);
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        spacing: 10,
        spaceBetweenChildren: 8,
        
        children: [
          SpeedDialChild(
            child: const Icon(Icons.inventory_2),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Dodaj Produkt',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.swap_horiz),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Nowa Operacja',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStockMovementsPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.location_on),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Dodaj Lokalizację',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLocationPage()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.category),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            label: 'Dodaj Kategorię',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCategoryPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.quantity <= product.minStock;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            _getCategoryIcon(product.category),
            color: isLowStock ? Colors.red : Colors.blue,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kategoria: ${product.category}'),
            Text('Lokalizacja: ${product.location}'),
            Row(
              children: [
                Text('Stan: ${product.quantity} szt.'),
                if (isLowStock) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NISKI STAN!',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editProduct(product),
              color: Colors.blue,
              tooltip: 'Edytuj produkt',
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _updateQuantity(product, -1),
              color: Colors.red,
              tooltip: 'Wydaj z magazynu',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => _updateQuantity(product, 1),
              color: Colors.green,
              tooltip: 'Przyjmij do magazynu',
            ),
          ],
        ),
        onTap: () => _showProductDetails(product),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nie znaleziono produktów',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Spróbuj zmienić kryteria wyszukiwania',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'elektronika':
        return Icons.computer;
      case 'meble':
        return Icons.chair;
      case 'akcesoria':
        return Icons.cable;
      case 'biuro':
        return Icons.business_center;
      default:
        return Icons.inventory_2;
    }
  }

  int _getLowStockCount() {
    return _allProducts.where((p) => p.quantity <= p.minStock).length;
  }

  int _getCategoriesCount() {
    return _allProducts.map((p) => p.category).toSet().length;
  }

  void _updateQuantity(Product product, int change) {
    setState(() {
      final newQuantity = product.quantity + change;
      if (newQuantity >= 0) {
        product.quantity = newQuantity;
        _onSearchChanged(); 
      }
    });
    
    final action = change > 0 ? 'Przyjęto' : 'Wydano';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action: ${product.name} (stan: ${product.quantity})'),
        duration: const Duration(seconds: 2),
        backgroundColor: change > 0 ? Colors.green : Colors.orange,
      ),
    );
  }

  void _editProduct(Product product) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final quantityController = TextEditingController(text: product.quantity.toString());
    final minStockController = TextEditingController(text: product.minStock.toString());
    final locationController = TextEditingController(text: product.location);
    String selectedCategory = product.category;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edytuj produkt'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nazwa produktu',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategoria',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: ['Elektronika', 'Meble', 'Akcesoria', 'Biuro', 'Odzież', 'Narzędzia', 'Inne']
                        .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                        .toList(),
                    onChanged: (value) => setState(() => selectedCategory = value!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Opis',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stan aktualny',
                            border: OutlineInputBorder(),
                            suffixText: 'szt.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Min. stan',
                            border: OutlineInputBorder(),
                            suffixText: 'szt.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lokalizacja',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                      hintText: 'np. A-1-3',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANULUJ'),
            ),
            FilledButton.icon(
              onPressed: () => _confirmDeleteProduct(product),
              icon: const Icon(Icons.delete),
              label: const Text('USUŃ'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && 
                    locationController.text.isNotEmpty) {
                  
                  Navigator.of(context).pop();
                  
                  this.setState(() {
                    final index = _allProducts.indexWhere((p) => p.id == product.id);
                    if (index != -1) {
                      _allProducts[index] = Product(
                        id: product.id,
                        name: nameController.text,
                        category: selectedCategory,
                        quantity: int.tryParse(quantityController.text) ?? product.quantity,
                        location: locationController.text.toUpperCase(),
                        minStock: int.tryParse(minStockController.text) ?? product.minStock,
                        description: descriptionController.text.isEmpty 
                            ? 'Brak opisu' 
                            : descriptionController.text,
                        dimensions: product.dimensions,
                      );
                    }
                    _onSearchChanged(); 
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Produkt "${nameController.text}" został zaktualizowany!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('ZAPISZ ZMIANY'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    Navigator.of(context).pop(); 
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Usuń produkt'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Czy na pewno chcesz usunąć produkt?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(_getCategoryIcon(product.category), color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('${product.category} • ${product.location}'),
                        Text('Stan: ${product.quantity} szt.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ta akcja jest nieodwracalna!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANULUJ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              setState(() {
                _allProducts.remove(product);
                _onSearchChanged();
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Produkt "${product.name}" został usunięty'),
                  backgroundColor: Colors.red,
                  action: SnackBarAction(
                    label: 'COFNIJ',
                    onPressed: () {
                      setState(() {
                        _allProducts.add(product);
                        _onSearchChanged();
                      });
                    },
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('USUŃ PRODUKT'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Product product) {
    final isLowStock = product.quantity <= product.minStock;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getCategoryIcon(product.category), color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(product.name)),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Kategoria', product.category),
            _buildDetailRow('Opis', product.description),
            _buildDetailRow('Aktualny stan', '${product.quantity} szt.'),
            _buildDetailRow('Minimalny stan', '${product.minStock} szt.'),
            _buildDetailRow('Lokalizacja', product.location),
            if (product.dimensions != null) _buildDetailRow('Wymiary (X)', product.dimensions!['x'].toString()),
            if (product.dimensions != null) _buildDetailRow('Wymiary (Y)', product.dimensions!['y'].toString()),
            if (product.dimensions != null) _buildDetailRow('Wymiary (Z)', product.dimensions!['z'].toString()),
            if (isLowStock) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Stan poniżej minimum!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}