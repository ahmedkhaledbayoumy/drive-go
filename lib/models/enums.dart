// All enum types used across Drive Go models.
// Stored in Postgres as text (the enum's `.name` value).

enum AccountType { customer, individualOwner, dealership, admin }

enum CarStatus { available, pendingConfirmation, booked }

enum BookingStatus {
  pending, // customer requested, owner not yet responded
  confirmed, // owner accepted
  declined, // owner rejected
  completed, // rental finished
  cancelled, // customer cancelled
}

enum PaymentStatus { pending, paid, refunded }

enum Transmission { manual, automatic }

enum FuelType { petrol, diesel, hybrid, electric }

enum NotificationType {
  bookingRequest,
  bookingConfirmed,
  bookingDeclined,
  statusChange,
  reviewPrompt,
}

/// Helper: convert a stored string back to its enum value.
T enumFromString<T extends Enum>(List<T> values, String? value) {
  return values.firstWhere(
    (e) => e.name == value,
    orElse: () => values.first,
  );
}
