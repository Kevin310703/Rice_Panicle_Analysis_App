import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  final _storage = GetStorage();

  final RxBool _isLoggedIn = false.obs;
  final RxBool _isFirstTime = true.obs;

  bool get isLoggedIn => _isLoggedIn.value;
  bool get isFirstTime => _isFirstTime.value;

  @override
  void onInit() {
    super.onInit();
    _loadInitialState();
  }

  void _loadInitialState() {
    _isLoggedIn.value = _storage.read('isLoggedIn') ?? false;
    _isFirstTime.value = _storage.read('isFirstTime') ?? true;
  }

  void setFirstTimeDone() {
    _isFirstTime.value = false;
    _storage.write('isFirstTime', false);
  }

  void login() {
    _isLoggedIn.value = true;
    _storage.write('isLoggedIn', true);
  }

  void logout() {
    _isLoggedIn.value = false;
    _storage.write('isLoggedIn', false);
  }
}