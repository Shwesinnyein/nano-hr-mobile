
class AppConstants {

  static const String baseUrl = 'https://nano-api-production.vercel.app';
  static const int apiTimeoutSeconds = 30;

  
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;


  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);


  static const String checkInType = 'checkin';
  static const String checkOutType = 'checkout';
  static const String checkedOutType = 'checked_out';


  static const String notCheckedInMessage = 'Not Checked In';
  static const String checkedInMessage = 'Checked In';
  static const String checkedOutMessage = 'Checked Out';


  static const String checkInButton = 'Check In';
  static const String checkOutButton = 'Check Out';
  static const String alreadyCheckedOutButton = 'Already Checked Out';


  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred.';


  static const String timeFormat = 'HH:mm:ss';
  static const String dateFormat = 'MMM dd, yyyy';
  static const String fullDateTimeFormat = 'MMM dd, yyyy HH:mm';


  static const int thailandTimezoneOffset = 7; // UTC+7

  
  static const String privacyPolicyUrl = 'https://nano-api-production.vercel.app/privacy-policy';
  static const String termsOfServiceUrl = 'https://nano-api-production.vercel.app/terms-of-service';
}
