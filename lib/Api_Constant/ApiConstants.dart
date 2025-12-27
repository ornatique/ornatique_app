
class ApiConstants {
  // Base URL Live

     static const String baseUrl = 'https://ornatique.co/portal/api/';

  // Base URL Testing

       //static const String baseUrl = 'https://development.ornatique.co/portal/api/';



  // API Endpoints
  static const String check_version = 'check-version';
  static const String login = 'user/login';
  static const String signup = 'user/sign-up';
  static const String verify_otp = 'user/verify-otp';
  static const String home_offer = 'offer/list';
  static const String home_banner = 'banner/list';
  static const String storehome_banner = 'stores';
  static const String home_heading = 'headings';
  static const String Ornatique_Essential = 'essentials';
  static const String welcome_popup = 'get/advertise';
  static const String cat_list = 'category/list';
  static const String topcollectioncat_list = 'collections';
  static const String subcat_list = 'subcategory/list';
  static const String updateprofie = 'profile/update';
  static const String product = 'product/list';
  static const String product_details = 'product/details';
  static const String wishlist = 'get/list';
  static const String addwishlist = 'add/wishlist';
  static const String removewishlist = 'remove/wishlist';
  // cart Api //
  static const String cartlist = 'view/cart';
  static const String add_cart = 'add/cart';
  static const String delete_cart = 'delete/cart';
  static const String view_order = 'orders';
  static const String order_details = 'order/details';
  static const String add_order = 'order/add';

  static const String logout = 'user/logout';
  static const String privacy_policy = 'privacy-policy';
  static const String terms = 'terms';
  static const String customize_add = 'custom/add';
  static const String customize_list = 'custom/list';
  static const String Scan_qr = 'get/qr';
  static const String save_qr = 'qr/save';
  static const String social = 'social';
  static const String media_list = 'media/list';
  static const String filtermedia_list = 'media/filter';
  static const String layout = 'layouts';
  static const String insideapplayout = 'layouts/inside';

  // Add more API endpoints or constants as needed

  // Timeout duration
  static const int connectTimeout = 5000; // 5 seconds
  static const int receiveTimeout = 5000; // 5 seconds
}