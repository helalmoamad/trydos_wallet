import '../api/api.dart';
import '../config/trydos_wallet_config.dart';

class UsersApiService {
  UsersApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<Map<String, dynamic>>> getMyProfile() {
    return _client.get<Map<String, dynamic>>(
      ApiPaths.myProfile,
      fromJson: (data) => Map<String, dynamic>.from(data as Map),
    );
  }

  Future<ApiResult<dynamic>> updateMyProfile({
    required String firstName,
    required String lastName,
    required String profilePictureURL,
  }) {
    return _client.patch<dynamic>(
      ApiPaths.myProfile,
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'profilePictureURL': profilePictureURL,
      },
    );
  }
}
