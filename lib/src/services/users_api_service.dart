import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

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

  /// Paginated login history for the current user. `Accept-Language` (already
  /// on the client headers) controls the localized failureReasonLabel.
  Future<ApiResult<PaginatedResponse<LoginHistoryItem>>> getLoginHistory({
    int page = 0,
    int limit = 20,
    String? status,
  }) {
    return _client.get<PaginatedResponse<LoginHistoryItem>>(
      ApiPaths.loginHistory,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      },
      fromJson: (data) => PaginatedResponse<LoginHistoryItem>.fromJson(
        Map<String, dynamic>.from(data as Map),
        (e) => LoginHistoryItem.fromJson(Map<String, dynamic>.from(e as Map)),
      ),
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
