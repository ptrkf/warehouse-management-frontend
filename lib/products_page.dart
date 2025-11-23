import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadMockData() {
    // Mockowe dane produktów dla systemu magazynowego
    _allProducts = [
      Product(
        id: '1',
        name: 'Laptop Dell XPS 13',
        category: 'Elektronika',
        quantity: 15,
        location: 'A-1-3',
        minStock: 5,
        description: 'Laptop biznesowy 13 cali',
        code: 'DELL-XPS13-001',
        dimensions: '30.2x20.1x1.4 cm',
      ),
      Product(
        id: '2',
        name: 'Krzesło biurowe Ergonomic',
        category: 'Meble',
        quantity: 23,
        location: 'B-2-1',
        minStock: 10,
        description: 'Krzesło z regulacją wysokości',
      ),
      Product(
        id: '3',
        name: 'Monitor Samsung 24"',
        category: 'Elektronika',
        quantity: 8,
        location: 'A-1-5',
        minStock: 12,
        description: 'Monitor Full HD 1920x1080',
      ),
      Product(
        id: '4',
        name: 'Kabel HDMI 2m',
        category: 'Akcesoria',
        quantity: 45,
        location: 'C-3-2',
        minStock: 20,
        description: 'Kabel HDMI wysokiej jakości',
      ),
      Product(
        id: '5',
        name: 'Długopis niebieski',
        category: 'Biuro',
        quantity: 2,
        location: 'D-1-1',
        minStock: 50,
        description: 'Długopis żelowy 0.7mm',
      ),
      Product(
        id: '6',
        name: 'Papier A4 500 ark.',
        category: 'Biuro',
        quantity: 78,
        location: 'D-1-3',
        minStock: 30,
        description: 'Papier biurowy 80g/m²',
      ),
    ];
    _filteredProducts = List.from(_allProducts);
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
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel wyszukiwania i statystyk
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Pasek wyszukiwania
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
                
                // Statystyki
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

          // Lista produktów
          Expanded(
            child: _filteredProducts.isEmpty
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Dodaj nowy produkt',
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
        _filteredProducts = List.from(_allProducts.where((p) {
          final query = _searchController.text.toLowerCase();
          return p.name.toLowerCase().contains(query) ||
                 p.category.toLowerCase().contains(query) ||
                 p.location.toLowerCase().contains(query);
        }));
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
                    // Aktualizuj pola produktu
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
                        code: product.code,
                        dimensions: product.dimensions,
                      );
                    }
                    _onSearchChanged(); // Odśwież listę
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
    Navigator.of(context).pop(); // Zamknij dialog edycji
    
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
            if (product.code != null) _buildDetailRow('Kod', product.code!),
            if (product.dimensions != null) _buildDetailRow('Wymiary', product.dimensions!),
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

  void _showAddProductDialog() {
    // Tymczasowa implementacja - prosty dialog z podstawowymi polami
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final locationController = TextEditingController();
    String selectedCategory = 'Elektronika';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Dodaj nowy produkt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa produktu',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategoria',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Elektronika', 'Meble', 'Akcesoria', 'Biuro', 'Inne']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Ilość początkowa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Lokalizacja (np. A-1-3)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ANULUJ'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && 
                    quantityController.text.isNotEmpty &&
                    locationController.text.isNotEmpty) {
                  
                  final newProduct = Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    category: selectedCategory,
                    quantity: int.tryParse(quantityController.text) ?? 0,
                    location: locationController.text.toUpperCase(),
                    minStock: 5,
                    description: 'Produkt dodany przez użytkownika',
                  );
                  
                  Navigator.of(context).pop();
                  
                  this.setState(() {
                    _allProducts.add(newProduct);
                    _onSearchChanged();
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Produkt "${newProduct.name}" został dodany!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('DODAJ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Model produktu
class Product {
  final String id;
  String name;
  String category;
  int quantity;
  String location;
  int minStock;
  String description;
  final String? code;
  final String? dimensions;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.minStock,
    required this.description,
    this.code,
    this.dimensions,
  });
}