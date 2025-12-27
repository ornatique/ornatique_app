import 'package:flutter/material.dart';
import 'package:pinch_zoom/pinch_zoom.dart';

class ProductDetailScreen1 extends StatefulWidget {
  final imageUrls;

  ProductDetailScreen1({super.key, required this.imageUrls});

  @override
  State<ProductDetailScreen1> createState() => _ProductDetailScreen1State();
}

class _ProductDetailScreen1State extends State<ProductDetailScreen1> {
  int _currentPage = 0;
  late List<bool> _isZoomedList;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // દરેક ઈમેજ માટે zoom state false થી શરૂ થાય
   // _isZoomedList = List<bool>.filled(widget.imageUrls.length, false);

  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Detail')),
      body: Column(
        children: [
          SizedBox(
            height: 300,
            child:  PinchZoom(
              zoomEnabled: true,
              child:
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                 widget.imageUrls.toString(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                ),
              ),
              // CachedNetworkImage(
              //   //width: double.infinity,
              //   imageUrl: "https://ornatique.co/portal/public/assets/images/product/${images[index]}",
              //   fit: BoxFit.cover,
              //   placeholder: (context, url) => Center(
              //     child: CircularProgressIndicator(),
              //   ),
              //   errorWidget: (context, url, error) => Center(
              //     child: Icon(Icons.error),
              //   ),
              // ),
            )
          ),
          const SizedBox(height: 10),
          Text('Image ${_currentPage + 1} of ${widget.imageUrls.length}'),
        ],
      ),
    );
  }
}
