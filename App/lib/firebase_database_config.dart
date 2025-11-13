/// Realtime Database URL override.
/// Set this to your new instance URL when you create a regional database.
/// Example patterns:
///   Global default: https://swep-5c75d-default-rtdb.firebaseio.com
///   Regional (e.g. asia-northeast3 Seoul): https://swep-5c75d-default-rtdb.asia-northeast3.firebasedatabase.app
/// If left empty (""), FirebaseDatabase.instance will use default options from initialization.
class FirebaseDbConfig {
  // ASSUMPTION: Using asia-northeast3 region. Change if your console shows a different URL.
  static const String databaseUrl = 'https://swep-5c75d-default-rtdb.asia-northeast3.firebasedatabase.app';
}
