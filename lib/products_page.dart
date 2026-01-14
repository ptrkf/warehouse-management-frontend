import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'add_product_page.dart';
import 'add_category_page.dart';
import 'add_location_page.dart';
import 'add_stock_movements_page.dart'; 
import 'edit_product_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'services/token_service.dart'; 
import 'alerts_page.dart';

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
    icon: const Icon(Icons.notifications),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AlertsPage()),
      );
    },
    tooltip: 'Powiadomienia',
  ),
  IconButton(
    icon: const Icon(Icons.logout),
    onPressed: () {
      TokenService.clearUserData(); 
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchProducts,
                              child: const Text('Spróbuj ponownie'),
                            ),
                          ],
                        ),
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
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductPage()),
              );
              if (shouldRefresh == true) {
                _fetchProducts();
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.swap_horiz),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Nowa Operacja',
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddStockMovementsPage()),
              );
              if (shouldRefresh == true) {
                _fetchProducts(); 
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.location_on),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            label: 'Dodaj Lokalizację',
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddLocationPage()),
              );
              if (shouldRefresh == true) {
                _fetchProducts(); 
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.category),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            label: 'Dodaj Kategorię',
            onTap: () async {
              final shouldRefresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddCategoryPage()),
              );
              if (shouldRefresh == true) {
                _fetchProducts(); 
              }
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
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editProduct(product),
          color: Colors.blue,
          tooltip: 'Edytuj produkt',
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

  // NOWA METODA - zastąpiła stary dialog edycji
  void _editProduct(Product product) async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(
          productId: product.id,
          initialName: product.name,
          initialCategory: product.category,
          initialDimensions: product.dimensions,
        ),
      ),
    );
    
    if (shouldRefresh == true) {
      _fetchProducts(); // Odświeża listę po edycji/usunięciu
    }
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
            if (product.dimensions != null) _buildDetailRow('Wymiary (X)', '${product.dimensions!['x']} mm'),
            if (product.dimensions != null) _buildDetailRow('Wymiary (Y)', '${product.dimensions!['y']} mm'),
            if (product.dimensions != null) _buildDetailRow('Wymiary (Z)', '${product.dimensions!['z']} mm'),
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
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _editProduct(product); // Otwiera stronę edycji
            },
            child: const Text('Edytuj'),
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