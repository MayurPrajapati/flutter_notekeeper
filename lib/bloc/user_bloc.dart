class User{
  String email;
  String name;
  String displayPicUrl;

  static User _instance;

  static User get instance {
    if(_instance == null) {
      _instance = User._();
    }
    return _instance;
  }

  User._();
}