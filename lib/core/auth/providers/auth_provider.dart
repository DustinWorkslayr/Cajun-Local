import 'package:cajun_local/core/auth/api/auth_api.dart';
import 'package:cajun_local/core/auth/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<UserModel?> build() async {
    final api = ref.watch(authApiProvider);
    return await api.initializeSession();
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authApiProvider);
      final res = await api.signIn(email: email, password: password);
      return res;
    });
  }

  Future<void> signUp({required String email, required String password, String? displayName}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authApiProvider);
      return await api.signUp(email: email, password: password, displayName: displayName);
    });
  }

  Future<String?> signInWithGoogle() async {
    try {
      final googleSignIn = gsi.GoogleSignIn.instance;

      // Initialize if needed (calling multiple times is fine in 7.2.0 if wait for completion)
      await googleSignIn.initialize();

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) return 'Failed to get ID token from Google';

      state = const AsyncValue.loading();
      final api = ref.read(authApiProvider);
      final user = await api.signInWithGoogle(idToken);

      state = AsyncValue.data(user);
      return null;
    } catch (e) {
      if (e is gsi.GoogleSignInException) {
        if (e.code == gsi.GoogleSignInExceptionCode.canceled) {
          return 'Google sign in cancelled';
        }
        return 'Google Sign In Error: ${e.code} - ${e.description}';
      }
      state = AsyncValue.error(e, StackTrace.current);
      return e.toString();
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    final api = ref.read(authApiProvider);
    await api.signOut();
    state = const AsyncValue.data(null);
  }

  Future<void> recoverPassword(String email) async {
    final api = ref.read(authApiProvider);
    await api.recoverPassword(email);
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final api = ref.read(authApiProvider);
    await api.resetPassword(token, newPassword);
  }

  Future<void> updateProfile({String? displayName, String? avatarUrl}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(authApiProvider);
      return api.updateProfile(displayName: displayName, avatarUrl: avatarUrl);
    });
  }

  Future<bool> isAdmin() async {
    final user = state.valueOrNull;
    return user?.role == 'admin';
  }
}

@riverpod
bool isAuthenticated(IsAuthenticatedRef ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  return user != null;
}

@riverpod
bool isAdmin(IsAdminRef ref) {
  final user = ref.watch(authNotifierProvider).valueOrNull;
  return user?.role == 'admin';
}
