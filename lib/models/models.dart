import 'enums.dart';

// ═══════════════════════════════════════════════════════════════
// PROFILE — Drive Go user data (separate from Supabase auth.users)
// ═══════════════════════════════════════════════════════════════
class Profile {
  final String id; // matches Supabase auth.users.id
  final String email;
  final String fullName;
  final String? phone;
  final AccountType accountType;
  final String? avatarUrl;
  final DateTime createdAt;

  // Dealership-only fields (null for Customer / Individual Owner)
  final String? businessName;
  final String? bannerUrl;
  final bool verified;
  final String? city;

  const Profile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    required this.accountType,
    this.avatarUrl,
    required this.createdAt,
    this.businessName,
    this.bannerUrl,
    this.verified = false,
    this.city,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String?,
        accountType:
            enumFromString(AccountType.values, json['account_type'] as String?),
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        businessName: json['business_name'] as String?,
        bannerUrl: json['banner_url'] as String?,
        verified: (json['verified'] as bool?) ?? false,
        city: json['city'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'account_type': accountType.name,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
        'business_name': businessName,
        'banner_url': bannerUrl,
        'verified': verified,
        'city': city,
      };

  bool get isCustomer => accountType == AccountType.customer;
  bool get isIndividualOwner => accountType == AccountType.individualOwner;
  bool get isDealership => accountType == AccountType.dealership;
  bool get isOwner => isIndividualOwner || isDealership;
  bool get isAdmin => accountType == AccountType.admin;
}

// ═══════════════════════════════════════════════════════════════
// CAR — A car listing on the marketplace
// ═══════════════════════════════════════════════════════════════
class Car {
  final String id;
  final String ownerId;
  final String brand;
  final String model;
  final int year;
  final String color;
  final Transmission transmission;
  final FuelType fuelType;
  final String city;
  final double pricePerDay; // in EGP
  final double? pricePerWeek;
  final double? pricePerMonth;
  final String description;
  final List<String> photos; // Supabase Storage URLs
  final CarStatus status;
  final DateTime createdAt;

  const Car({
    required this.id,
    required this.ownerId,
    required this.brand,
    required this.model,
    required this.year,
    required this.color,
    required this.transmission,
    required this.fuelType,
    required this.city,
    required this.pricePerDay,
    this.pricePerWeek,
    this.pricePerMonth,
    required this.description,
    required this.photos,
    required this.status,
    required this.createdAt,
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        year: json['year'] as int,
        color: json['color'] as String,
        transmission: enumFromString(
            Transmission.values, json['transmission'] as String?),
        fuelType: enumFromString(FuelType.values, json['fuel_type'] as String?),
        city: json['city'] as String,
        pricePerDay: (json['price_per_day'] as num).toDouble(),
        pricePerWeek: (json['price_per_week'] as num?)?.toDouble(),
        pricePerMonth: (json['price_per_month'] as num?)?.toDouble(),
        description: json['description'] as String,
        photos: (json['photos'] as List?)?.cast<String>() ?? [],
        status: enumFromString(CarStatus.values, json['status'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'brand': brand,
        'model': model,
        'year': year,
        'color': color,
        'transmission': transmission.name,
        'fuel_type': fuelType.name,
        'city': city,
        'price_per_day': pricePerDay,
        'price_per_week': pricePerWeek,
        'price_per_month': pricePerMonth,
        'description': description,
        'photos': photos,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}

// ═══════════════════════════════════════════════════════════════
// BOOKING — A rental request / confirmed rental
// ═══════════════════════════════════════════════════════════════
class Booking {
  final String id;
  final String carId;
  final String customerId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice; // in EGP
  final bool withDriver;
  final String? pickupLocation;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.carId,
    required this.customerId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.withDriver,
    this.pickupLocation,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        carId: json['car_id'] as String,
        customerId: json['customer_id'] as String,
        ownerId: json['owner_id'] as String,
        startDate: DateTime.parse(json['start_date'] as String),
        endDate: DateTime.parse(json['end_date'] as String),
        totalPrice: (json['total_price'] as num).toDouble(),
        withDriver: (json['with_driver'] as bool?) ?? false,
        pickupLocation: json['pickup_location'] as String?,
        status: enumFromString(BookingStatus.values, json['status'] as String?),
        paymentStatus: enumFromString(
            PaymentStatus.values, json['payment_status'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'car_id': carId,
        'customer_id': customerId,
        'owner_id': ownerId,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'total_price': totalPrice,
        'with_driver': withDriver,
        'pickup_location': pickupLocation,
        'status': status.name,
        'payment_status': paymentStatus.name,
        'created_at': createdAt.toIso8601String(),
      };
}

// ═══════════════════════════════════════════════════════════════
// REVIEW — Customer rating + comment for a Dealership rental
// ═══════════════════════════════════════════════════════════════
class Review {
  final String id;
  final String dealershipId;
  final String customerId;
  final String? bookingId;
  final int rating; // 1 to 5
  final String comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.dealershipId,
    required this.customerId,
    this.bookingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        dealershipId: json['dealership_id'] as String,
        customerId: json['customer_id'] as String,
        bookingId: json['booking_id'] as String?,
        rating: json['rating'] as int,
        comment: json['comment'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dealership_id': dealershipId,
        'customer_id': customerId,
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };
}

// ═══════════════════════════════════════════════════════════════
// CHAT MESSAGE — In-app chat between Customer and Owner per Booking
// ═══════════════════════════════════════════════════════════════
class ChatMessage {
  final String id;
  final String bookingId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool read;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.read = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        bookingId: json['booking_id'] as String,
        senderId: json['sender_id'] as String,
        text: json['text'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        read: (json['read'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'booking_id': bookingId,
        'sender_id': senderId,
        'text': text,
        'created_at': createdAt.toIso8601String(),
        'read': read,
      };
}

// ═══════════════════════════════════════════════════════════════
// APP NOTIFICATION — In-app notifications for booking events etc.
// (Named AppNotification to avoid clash with Flutter's Notification)
// ═══════════════════════════════════════════════════════════════
class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId; // ID of the related Booking or Car
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.read = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: enumFromString(NotificationType.values, json['type'] as String?),
        relatedId: json['related_id'] as String?,
        read: (json['read'] as bool?) ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'related_id': relatedId,
        'read': read,
        'created_at': createdAt.toIso8601String(),
      };
}
