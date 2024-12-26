class AppConfig {
  static const String appName = 'Flutter Application';
  static const String apiBaseUrl = 'https://api.example.com';  // Replace with your API URL
  
  // API Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String userEndpoint = '/user';
  
  // Cache Configuration
  static const int cacheTimeout = 3600;  // 1 hour in seconds
  
  // Other app-wide configurations
  static const int pageSize = 20;
  static const int maxRetries = 3;
}
