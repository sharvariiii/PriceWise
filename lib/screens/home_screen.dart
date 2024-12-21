import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import '../models/product.dart';
import 'compare_cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHints = [
    'Search for milk',
    'Search for mango',
    'Search for paneer',
    'Search for sweater'
  ];
  int _currentHintIndex = 0;
  String _currentPincode = '';
  bool _isLoading = false;

  // Timer for search hint rotation
  Timer? _hintTimer;

  // Product lists for each platform
  List<Product> _blinkitProducts = [];
  List<Product> _instamartProducts = [];
  List<Product> _zeptoProducts = [];

  // Compare cart lists
  List<Product> _compareCartBlinkit = [];
  List<Product> _compareCartInstamart = [];
  List<Product> _compareCartZepto = [];

  // Define the pincodeLocations map at the class level
  final Map<String, String> pincodeLocations = {
    //----------Mumbai Pincodes---------------------
    '400005': '400005_colaba_mumbai',
    '400014': '400014_dadar_mumbai',
    '400030': '400030_worli_mumbai',
    '400049': '400049_juhu_mumbai',
    '400050': '400050_bandra_mumbai',
    '400053': '400053_andheri_mumbai',
    '400063': '400063_goregaon_mumbai',
    '400064': '400064_malad_mumbai',
    '400066': '400066_borivali_mumbai',
    '400076': '400076_powai_mumbai',

    //------------Pune Pincodes------------
    '411014': 'kharadi_pune',
    '411057': 'hinjewadi_pune',

    //----------Hyderabad Pincodes---------------------
    '500032': '500032_gachibowli_circle_hyd',
    '500074': '500074_lb_nagar_hyd',
    '500081': '500081_vittal_rao_nagar_hyd',

    //----------Bangalore Pincodes---------------------
    '560034': 'koramangala',
    '560066': 'whitefield',
    '560038': 'indiranagar',
    '560102': 'hsr%20layout',

    //----------Chennai Pincodes---------------------
    '600012': '600012_jamalia_chennai',
    '600035': '600035_cit_nagar_chennai',
    '600097': '600097_srinivasa_nagar_chennai',

    //----------Delhi Pincodes---------------------
    '110051': 'eastdelhi',
    '110062': 'southdelhi',
    '201301': 'sector11',
    '123401': 'gurgaon',
    '110044': 'dwarka',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startHintAnimation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _hintTimer?.cancel();
    super.dispose();
  }

  void _startHintAnimation() {
    _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;
      });
    });
  }

  Future<void> _showLocationDialog({String? initialPincode}) async {
    String tempPincode =
        initialPincode ?? ''; // Default to empty if no initial pincode
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Pincode'),
        content: TextField(
          keyboardType: TextInputType.number,
          maxLength: 6, // Limits input to 6 characters
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // Only allow digits
          ],
          onChanged: (value) => tempPincode = value,
          decoration: InputDecoration(
            hintText: 'Enter 6-digit pincode',
            helperText: initialPincode != null
                ? 'Current: $initialPincode'
                : null, // Show current pincode
          ),
          controller: TextEditingController(
              text: initialPincode), // Pre-fill with current pincode
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (tempPincode.length == 6) {
                // if (tempPincode != _currentPincode) {
                //   _resetCompareCart(
                //       context); // Clear compare cart on pincode change
                // }
                setState(() => _currentPincode = tempPincode);
                Navigator.pop(context);
                _searchProducts(_searchController.text);
              } else {
                // Show a success message
                _showCustomSnackBar(
                    'Please enter a valid 6-digit pincode', Icons.info);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchProducts(String query) async {
    if (_currentPincode.isEmpty) {
      // Show a success message
      _showCustomSnackBar('Please set your pincode first', Icons.info);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final responses = await Future.wait([
        _fetchProducts('blinkit_products', query, _currentPincode),
        _fetchProducts('instamart_products', query, _currentPincode),
        _fetchProducts('zepto_products', query, _currentPincode),
      ]);

      setState(() {
        _blinkitProducts = responses[0];
        _instamartProducts = responses[1];
        _zeptoProducts = responses[2];
      });
    } catch (e) {
      // Show an error message
      _showCustomSnackBar('Error fetching products: $e', Icons.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // New method to convert pincode to location
  String _convertPincodeToLocation(String pincode) {
    return pincodeLocations[pincode] ?? '${pincode}_Undefined_Location';
  }

  Future<List<Product>> _fetchProducts(
      String platformKey, String query, String pincode) async {
    // Convert pincode to full location string
    final location = _convertPincodeToLocation(pincode);

    final url = Uri.parse(
        'https://9minutes.in/api/fetch_products?query=$query&location=$location');

    //----------Add logging for debugging-----------
    print('Fetching products from: $url');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = jsonDecode(response.body);
      if (jsonData.containsKey(platformKey) && jsonData[platformKey] is List) {
        final List<dynamic> productsJson = jsonData[platformKey];
        return productsJson.map((item) {
          return Product(
            id: '${platformKey}-${item['name']}',
            name: item['name'],
            image: item['image'] ?? 'https://via.placeholder.com/150',
            price: (item['selling_price'] as num?)?.toDouble() ?? 0.0,
            quantity: item['variant'] ?? 'N/A',
            platform: platformKey.replaceAll('_products', ''),
            productUrl: item['deeplink'] ?? '',
          );
        }).toList();
      } else {
        throw Exception('Invalid product list structure for $platformKey');
      }
    } else {
      throw Exception(
          'Failed to load products for $platformKey: ${response.body}');
    }
  }

//------------Generic SnackBar function-------------------------
  void _showCustomSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, // Custom icon
              color: const Color(0xFF4E377A),
            ),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4E377A),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB4A1D0),
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

//---------------Add To CompareCart---------------
  void _addToCompareCart(Product product) {
    setState(() {
      if (product.platform == 'blinkit' &&
          !_compareCartBlinkit.any((p) => p.id == product.id)) {
        _compareCartBlinkit.add(product);
        //----------------Show a success message-------
        _showCustomSnackBar('Added to Compare Cart', Icons.check_circle);
      } else if (product.platform == 'instamart' &&
          !_compareCartInstamart.any((p) => p.id == product.id)) {
        _compareCartInstamart.add(product);
        //-----------------Show a success message---------
        _showCustomSnackBar('Added to Compare Cart', Icons.check_circle);
      } else if (product.platform == 'zepto' &&
          !_compareCartZepto.any((p) => p.id == product.id)) {
        _compareCartZepto.add(product);
        //--------------------Show a success message--------
        _showCustomSnackBar('Added to Compare Cart', Icons.check_circle);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset(
          'assets/logo.png',
          width: 10,
          height: 10,
        ),
        // leading: IconButton(
        //   icon: const Icon(Icons.menu),
        //   onPressed: () {},
        // ),
        title: const Text(
          'PriceWise',
          style: TextStyle(
            color: Color(0xFF4E377A), // Purple color for the title
            fontSize: 18,
            fontWeight: FontWeight.bold,
            // letterSpacing: 1.2, // Adds spacing between letters
          ),
        ),
        backgroundColor: const Color(0xFFEBDDFF), // Light purple background
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Color(0xFF4E377A), // Darker color for icons
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _showLocationDialog,
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CompareCartScreen(
                    compareCartBlinkit: _compareCartBlinkit,
                    compareCartInstamart: _compareCartInstamart,
                    compareCartZepto: _compareCartZepto,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                //---------------Search Section-----------------
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  color: const Color(0xFFF3F3F3),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Color(0xFF4E377A)),
                      decoration: InputDecoration(
                        hintText: _searchHints[_currentHintIndex],
                        hintStyle: const TextStyle(color: Color(0xFFB4A1D0)),
                        prefixIcon:
                            const Icon(Icons.search, color: Color(0xFF4E377A)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF4E377A)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                      onSubmitted: _searchProducts,
                    ),
                  ),
                ),

                //------------Location Display Box---------
                if (_currentPincode.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Card(
                      elevation: 4,
                      color: const Color(0xFFEBDDFF), // Light purple background
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: Color(0xFF4E377A),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Location: ${_convertPincodeToLocation(_currentPincode)}',
                              style: const TextStyle(
                                color: Color(0xFF4E377A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF4E377A),
                                  size: 20,
                                ),
                                onPressed: () {
                                  _showLocationDialog(
                                      initialPincode: _currentPincode);
                                }),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          //-------------------------Tab Bar-----------------
          TabBar(
            controller: _tabController,
            indicatorColor:
                const Color(0xFF4E377A), // Custom color for the indicator
            labelColor:
                const Color(0xFF4E377A), // Color for the selected tab text
            unselectedLabelColor:
                const Color(0xFFB4A1D0), // Color for the unselected tab text
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'Blinkit'),
              Tab(text: 'Instamart'),
              Tab(text: 'Zepto'),
            ],
          ),

          //-----------------------Product List View----------------------
          Expanded(
            child: _isLoading
                ? Center(
                    child: Lottie.asset(
                      'assets/Animation.json',
                      width: 250,
                      height: 250,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductList(_blinkitProducts),
                      _buildProductList(_instamartProducts),
                      _buildProductList(_zeptoProducts),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Text(
          'Start searching by clicking on 🔍',
          style: TextStyle(
            color: Color(0xFF4E377A), // Purple color for the title
            fontSize: 15,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ListTile(
          leading: Image.network(
            product.image,
            width: 50,
            height: 50,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported),
          ),
          title: GestureDetector(
            onTap: () {
              print('Opening the link : ${product.productUrl}');
            },
            child: Text(product.name),
          ),
          subtitle: Text(
            '₹ ${product.price.toString()} \n${product.quantity}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _addToCompareCart(product),
                child: const Text('Compare'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}
