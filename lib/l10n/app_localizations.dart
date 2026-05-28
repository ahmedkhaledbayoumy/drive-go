import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Drive Go'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Car rental marketplace for Egypt'**
  String get tagline;

  /// No description provided for @driveGo.
  ///
  /// In en, this message translates to:
  /// **'DriveGo'**
  String get driveGo;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to Drive Go'**
  String get welcomeBack;

  /// No description provided for @joinDriveGo.
  ///
  /// In en, this message translates to:
  /// **'Join Drive Go'**
  String get joinDriveGo;

  /// No description provided for @noAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccountQuestion;

  /// No description provided for @haveAccountQuestion.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccountQuestion;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneOptional;

  /// No description provided for @businessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get checkInbox;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'We sent you a link to reset your password.'**
  String get resetLinkSent;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @iAmA.
  ///
  /// In en, this message translates to:
  /// **'I am a:'**
  String get iAmA;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @customerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rent cars for personal use'**
  String get customerSubtitle;

  /// No description provided for @individualOwner.
  ///
  /// In en, this message translates to:
  /// **'Individual Owner'**
  String get individualOwner;

  /// No description provided for @individualOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rent out my personal car'**
  String get individualOwnerSubtitle;

  /// No description provided for @dealership.
  ///
  /// In en, this message translates to:
  /// **'Dealership'**
  String get dealership;

  /// No description provided for @dealershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rent out multiple cars (business)'**
  String get dealershipSubtitle;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// No description provided for @minPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Min 6 characters'**
  String get minPasswordLength;

  /// No description provided for @fullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get fullNameRequired;

  /// No description provided for @nameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short'**
  String get nameTooShort;

  /// No description provided for @businessNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Business name is required'**
  String get businessNameRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileUpdateFailed;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirm;

  /// No description provided for @somethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWrong;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @myListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get myListings;

  /// No description provided for @findYourRide.
  ///
  /// In en, this message translates to:
  /// **'Find Your Perfect Ride'**
  String get findYourRide;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Egypt\'s #1 Car Rental Marketplace · 200+ Cars'**
  String get homeTagline;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Brand, model, city…'**
  String get searchHint;

  /// No description provided for @searchDreamCar.
  ///
  /// In en, this message translates to:
  /// **'Search your dream car…'**
  String get searchDreamCar;

  /// No description provided for @topBrands.
  ///
  /// In en, this message translates to:
  /// **'Top Brands'**
  String get topBrands;

  /// No description provided for @exploreAllCars.
  ///
  /// In en, this message translates to:
  /// **'Explore All Cars'**
  String get exploreAllCars;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @viewAllArrow.
  ///
  /// In en, this message translates to:
  /// **'View All →'**
  String get viewAllArrow;

  /// No description provided for @recommendForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommend For You'**
  String get recommendForYou;

  /// No description provided for @savedCollection.
  ///
  /// In en, this message translates to:
  /// **'Saved Collection'**
  String get savedCollection;

  /// No description provided for @bookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now'**
  String get bookNow;

  /// No description provided for @perDay.
  ///
  /// In en, this message translates to:
  /// **'/Day'**
  String get perDay;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @egyptSuffix.
  ///
  /// In en, this message translates to:
  /// **', Egypt'**
  String get egyptSuffix;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No cars found'**
  String get noResults;

  /// No description provided for @noSavedCars.
  ///
  /// In en, this message translates to:
  /// **'No saved cars yet'**
  String get noSavedCars;

  /// No description provided for @browseCars.
  ///
  /// In en, this message translates to:
  /// **'Browse Cars'**
  String get browseCars;

  /// No description provided for @signInToSave.
  ///
  /// In en, this message translates to:
  /// **'Sign in to save your favourites'**
  String get signInToSave;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @availableOnly.
  ///
  /// In en, this message translates to:
  /// **'Available only'**
  String get availableOnly;

  /// No description provided for @priceRange.
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @carClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get carClass;

  /// No description provided for @transmission.
  ///
  /// In en, this message translates to:
  /// **'Transmission'**
  String get transmission;

  /// No description provided for @fuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get fuel;

  /// No description provided for @anyBrand.
  ///
  /// In en, this message translates to:
  /// **'Any brand'**
  String get anyBrand;

  /// No description provided for @anyCity.
  ///
  /// In en, this message translates to:
  /// **'Any city'**
  String get anyCity;

  /// No description provided for @anyClass.
  ///
  /// In en, this message translates to:
  /// **'Any class'**
  String get anyClass;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @petrol.
  ///
  /// In en, this message translates to:
  /// **'Petrol'**
  String get petrol;

  /// No description provided for @diesel.
  ///
  /// In en, this message translates to:
  /// **'Diesel'**
  String get diesel;

  /// No description provided for @hybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// No description provided for @electric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get electric;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @carsTab.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get carsTab;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @models.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get models;

  /// No description provided for @cities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get cities;

  /// No description provided for @priceChip.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceChip;

  /// No description provided for @addListing.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addListing;

  /// No description provided for @colorWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colorWhite;

  /// No description provided for @colorBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colorBlack;

  /// No description provided for @colorSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get colorSilver;

  /// No description provided for @colorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colorBlue;

  /// No description provided for @colorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colorRed;

  /// No description provided for @colorGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get colorGrey;

  /// No description provided for @colorGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get colorGold;

  /// No description provided for @priceRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'EGP {min}–{max}'**
  String priceRangeLabel(int min, int max);

  /// No description provided for @priceRangeSheetLabel.
  ///
  /// In en, this message translates to:
  /// **'EGP {min} — EGP {max}'**
  String priceRangeSheetLabel(int min, int max);

  /// No description provided for @carLocationLine.
  ///
  /// In en, this message translates to:
  /// **'4.8 · {city}{egypt}'**
  String carLocationLine(String city, String egypt);

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'My Rentals'**
  String get history;

  /// No description provided for @historyActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get historyActive;

  /// No description provided for @historyPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get historyPast;

  /// No description provided for @historyNoActive.
  ///
  /// In en, this message translates to:
  /// **'No active rentals'**
  String get historyNoActive;

  /// No description provided for @historyNoActiveSub.
  ///
  /// In en, this message translates to:
  /// **'Browse cars to book your next trip.'**
  String get historyNoActiveSub;

  /// No description provided for @historyNoPast.
  ///
  /// In en, this message translates to:
  /// **'No past rentals yet'**
  String get historyNoPast;

  /// No description provided for @historyNoPastSub.
  ///
  /// In en, this message translates to:
  /// **'Your rental history will appear here.'**
  String get historyNoPastSub;

  /// No description provided for @historyError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load history'**
  String get historyError;

  /// No description provided for @historyErrorSub.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get historyErrorSub;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get notificationsEmpty;

  /// No description provided for @notificationsEmptySub.
  ///
  /// In en, this message translates to:
  /// **'You have no notifications yet.'**
  String get notificationsEmptySub;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave a Review'**
  String get reviewTitle;

  /// No description provided for @reviewNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking not found.'**
  String get reviewNotFound;

  /// No description provided for @reviewRating.
  ///
  /// In en, this message translates to:
  /// **'Your Rating'**
  String get reviewRating;

  /// No description provided for @reviewReview.
  ///
  /// In en, this message translates to:
  /// **'Your Review'**
  String get reviewReview;

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about your experience with this dealership...'**
  String get reviewHint;

  /// No description provided for @reviewSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get reviewSubmit;

  /// No description provided for @ratingPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get ratingPoor;

  /// No description provided for @ratingBelowAverage.
  ///
  /// In en, this message translates to:
  /// **'Below Average'**
  String get ratingBelowAverage;

  /// No description provided for @ratingAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get ratingAverage;

  /// No description provided for @ratingGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// No description provided for @ratingExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get ratingExcellent;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statusConfirmed;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statusDeclined;

  /// No description provided for @btnLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave Review'**
  String get btnLeaveReview;

  /// No description provided for @btnRentAgain.
  ///
  /// In en, this message translates to:
  /// **'Rent Again'**
  String get btnRentAgain;

  /// No description provided for @bookingDetails.
  ///
  /// In en, this message translates to:
  /// **'Booking Details'**
  String get bookingDetails;

  /// No description provided for @bookWithDriver.
  ///
  /// In en, this message translates to:
  /// **'Book with driver'**
  String get bookWithDriver;

  /// No description provided for @driverCostPerDay.
  ///
  /// In en, this message translates to:
  /// **'+200 EGP/day'**
  String get driverCostPerDay;

  /// No description provided for @rentalPeriod.
  ///
  /// In en, this message translates to:
  /// **'Rental Period'**
  String get rentalPeriod;

  /// No description provided for @pickupDate.
  ///
  /// In en, this message translates to:
  /// **'Pickup date'**
  String get pickupDate;

  /// No description provided for @returnDate.
  ///
  /// In en, this message translates to:
  /// **'Return date'**
  String get returnDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectDate;

  /// No description provided for @daysRental.
  ///
  /// In en, this message translates to:
  /// **'{count} day rental'**
  String daysRental(int count);

  /// No description provided for @daysRentalPlural.
  ///
  /// In en, this message translates to:
  /// **'{count} days rental'**
  String daysRentalPlural(int count);

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup location'**
  String get pickupLocation;

  /// No description provided for @pickupHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cairo Airport'**
  String get pickupHint;

  /// No description provided for @rentalCost.
  ///
  /// In en, this message translates to:
  /// **'Rental Cost'**
  String get rentalCost;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get totalAmount;

  /// No description provided for @driver.
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driver;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @payAmount.
  ///
  /// In en, this message translates to:
  /// **'Pay EGP {amount}'**
  String payAmount(String amount);

  /// No description provided for @creatingBooking.
  ///
  /// In en, this message translates to:
  /// **'Creating booking…'**
  String get creatingBooking;

  /// No description provided for @failedCreateBooking.
  ///
  /// In en, this message translates to:
  /// **'Failed to create booking.'**
  String get failedCreateBooking;

  /// No description provided for @bookingNotFound.
  ///
  /// In en, this message translates to:
  /// **'Booking not found.'**
  String get bookingNotFound;

  /// No description provided for @bookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingId;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @withDriver.
  ///
  /// In en, this message translates to:
  /// **'With driver'**
  String get withDriver;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markCompleted;

  /// No description provided for @phoneConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Phone Confirmation'**
  String get phoneConfirmation;

  /// No description provided for @didOwnerMarkCar.
  ///
  /// In en, this message translates to:
  /// **'Did the owner mark the car ready for you?'**
  String get didOwnerMarkCar;

  /// No description provided for @enjoyRide.
  ///
  /// In en, this message translates to:
  /// **'Great! Enjoy your ride 🚗'**
  String get enjoyRide;

  /// No description provided for @supportFollowUp.
  ///
  /// In en, this message translates to:
  /// **'Support will follow up with the owner.'**
  String get supportFollowUp;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @contactVia.
  ///
  /// In en, this message translates to:
  /// **'Contact via:'**
  String get contactVia;

  /// No description provided for @inApp.
  ///
  /// In en, this message translates to:
  /// **'In-App'**
  String get inApp;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet.'**
  String get noMessages;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start the conversation below.'**
  String get startConversation;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get typeMessage;

  /// No description provided for @ownerNoPhone.
  ///
  /// In en, this message translates to:
  /// **'Owner has not added a phone number yet.'**
  String get ownerNoPhone;

  /// No description provided for @whatsappNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp is not installed on this device.'**
  String get whatsappNotInstalled;

  /// No description provided for @cannotCall.
  ///
  /// In en, this message translates to:
  /// **'Cannot make calls on this device.'**
  String get cannotCall;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get paymentDetails;

  /// No description provided for @amountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get amountDue;

  /// No description provided for @secure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get secure;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @cardNumberHint.
  ///
  /// In en, this message translates to:
  /// **'0000 0000 0000 0000'**
  String get cardNumberHint;

  /// No description provided for @cardholderName.
  ///
  /// In en, this message translates to:
  /// **'Cardholder Name'**
  String get cardholderName;

  /// No description provided for @cardholderHint.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Khaled'**
  String get cardholderHint;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @cvv.
  ///
  /// In en, this message translates to:
  /// **'CVV'**
  String get cvv;

  /// No description provided for @bookingInformation.
  ///
  /// In en, this message translates to:
  /// **'Booking Information'**
  String get bookingInformation;

  /// No description provided for @carRental.
  ///
  /// In en, this message translates to:
  /// **'Car rental'**
  String get carRental;

  /// No description provided for @mockPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Mock payment — no real transaction occurs.'**
  String get mockPaymentNote;

  /// No description provided for @confirmPayAmount.
  ///
  /// In en, this message translates to:
  /// **'Confirm  •  EGP {amount}'**
  String confirmPayAmount(String amount);

  /// No description provided for @confirmPayment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Payment'**
  String get confirmPayment;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing Payment…'**
  String get processingPayment;

  /// No description provided for @doNotClose.
  ///
  /// In en, this message translates to:
  /// **'Please do not close this screen.'**
  String get doNotClose;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessful;

  /// No description provided for @bookingConfirmedSub.
  ///
  /// In en, this message translates to:
  /// **'Your car booking is now confirmed'**
  String get bookingConfirmedSub;

  /// No description provided for @viewBookingDetails.
  ///
  /// In en, this message translates to:
  /// **'View Booking Details'**
  String get viewBookingDetails;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @paidStatus.
  ///
  /// In en, this message translates to:
  /// **'Paid ✓'**
  String get paidStatus;

  /// No description provided for @bookingConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmedTitle;

  /// No description provided for @bookingRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Booking Request Sent!'**
  String get bookingRequestSent;

  /// No description provided for @ownerWillConfirm.
  ///
  /// In en, this message translates to:
  /// **'The owner will confirm shortly.'**
  String get ownerWillConfirm;

  /// No description provided for @chatWithOwner.
  ///
  /// In en, this message translates to:
  /// **'Chat with Owner'**
  String get chatWithOwner;

  /// No description provided for @viewFullDetails.
  ///
  /// In en, this message translates to:
  /// **'View Full Details'**
  String get viewFullDetails;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @enter16Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter 16 digits'**
  String get enter16Digits;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
