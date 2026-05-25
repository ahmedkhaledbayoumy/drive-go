// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Drive Go';

  @override
  String get tagline => 'Car rental marketplace for Egypt';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get search => 'Search';

  @override
  String get home => 'Home';

  @override
  String get favorites => 'Favorites';

  @override
  String get myListings => 'My Listings';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get logout => 'Logout';

  @override
  String get findYourRide => 'Find Your Perfect Ride';

  @override
  String get homeTagline => 'Egypt\'s #1 Car Rental Marketplace · 200+ Cars';

  @override
  String get searchHint => 'Brand, model, city…';

  @override
  String get searchDreamCar => 'Search your dream car…';

  @override
  String get topBrands => 'Top Brands';

  @override
  String get exploreAllCars => 'Explore All Cars';

  @override
  String get viewAll => 'View All';

  @override
  String get viewAllArrow => 'View All →';

  @override
  String get recommendForYou => 'Recommend For You';

  @override
  String get savedCollection => 'Saved Collection';

  @override
  String get bookNow => 'Book Now';

  @override
  String get perDay => '/Day';

  @override
  String get filters => 'Filters';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get clearAll => 'Clear All';

  @override
  String get availableOnly => 'Available only';

  @override
  String get priceRange => 'Price Range';

  @override
  String get noResults => 'No cars found';

  @override
  String get noSavedCars => 'No saved cars yet';

  @override
  String get browseCars => 'Browse Cars';

  @override
  String get signInToSave => 'Sign in to save your favourites';

  @override
  String get color => 'Color';

  @override
  String get model => 'Model';

  @override
  String get brand => 'Brand';

  @override
  String get city => 'City';

  @override
  String get carClass => 'Class';

  @override
  String get transmission => 'Transmission';

  @override
  String get fuel => 'Fuel';

  @override
  String get anyBrand => 'Any brand';

  @override
  String get anyCity => 'Any city';

  @override
  String get anyClass => 'Any class';

  @override
  String get manual => 'Manual';

  @override
  String get automatic => 'Automatic';

  @override
  String get petrol => 'Petrol';

  @override
  String get diesel => 'Diesel';

  @override
  String get hybrid => 'Hybrid';

  @override
  String get electric => 'Electric';

  @override
  String get available => 'Available';

  @override
  String get all => 'All';

  @override
  String get carsTab => 'Cars';

  @override
  String get saved => 'Saved';

  @override
  String get models => 'Models';

  @override
  String get cities => 'Cities';

  @override
  String get priceChip => 'Price';

  @override
  String get addListing => 'Add';

  @override
  String get history => 'History';

  @override
  String get driveGo => 'DriveGo';

  @override
  String get egyptSuffix => ', Egypt';

  @override
  String get colorWhite => 'White';

  @override
  String get colorBlack => 'Black';

  @override
  String get colorSilver => 'Silver';

  @override
  String get colorBlue => 'Blue';

  @override
  String get colorRed => 'Red';

  @override
  String get colorGrey => 'Grey';

  @override
  String get colorGold => 'Gold';

  @override
  String priceRangeLabel(int min, int max) {
    return 'EGP $min–$max';
  }

  @override
  String priceRangeSheetLabel(int min, int max) {
    return 'EGP $min — EGP $max';
  }

  @override
  String carLocationLine(String city, String egypt) {
    return '4.8 · $city$egypt';
  }
}
