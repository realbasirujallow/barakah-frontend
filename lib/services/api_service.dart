import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/models/price.dart';
import 'package:barakah_app/models/transaction.dart';

/// User-friendly exception thrown by [ApiService].
/// Screens can catch this and display [message] directly in a SnackBar.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // Override at build time:  flutter build apk --dart-define=API_URL=http://192.168.1.x:8080
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.trybarakah.com',
  );

  late final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json; charset=utf-8',
      },
      responseDecoder: (responseBytes, options, responseBody) {
        return utf8.decode(responseBytes);
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Convert DioException to user-friendly AppException
        final response = e.response;

        // Handle 401 — token expired / invalid
        if (response?.statusCode == 401) {
          _authService.logout();
          return handler.reject(DioException(
            requestOptions: e.requestOptions,
            error: AppException('Session expired. Please log in again.', statusCode: 401),
          ));
        }

        // Extract server error message if available
        if (response?.data is Map) {
          final data = response!.data as Map;
          final serverMsg = data['error'] ?? data['message'];
          if (serverMsg != null && serverMsg.toString().isNotEmpty) {
            return handler.reject(DioException(
              requestOptions: e.requestOptions,
              error: AppException(serverMsg.toString(), statusCode: response.statusCode),
            ));
          }
        }

        // Map common network errors
        String message;
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
          case DioExceptionType.sendTimeout:
            message = 'Server is taking too long. Please try again.';
            break;
          case DioExceptionType.connectionError:
          case DioExceptionType.unknown:
            message = 'No connection to server. Check your internet.';
            break;
          default:
            message = 'Something went wrong. Please try again.';
        }

        return handler.reject(DioException(
          requestOptions: e.requestOptions,
          error: AppException(message, statusCode: response?.statusCode),
        ));
      },
    ));
  }

  /// Extract user-friendly error message from any exception.
  /// Use in catch blocks: `catch (e) { showSnackBar(ApiService.errorMessage(e)); }`
  static String errorMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    if (error is DioException) return 'Something went wrong. Please try again.';
    final msg = error.toString();
    if (msg.startsWith('Exception: ')) return msg.substring(11);
    return msg;
  }

  // ─── Auth ────────────────────────────────────────────

  Future<Map<String, dynamic>> signup(String name, String email, String password, String? state) async {
    final response = await _dio.post('/auth/signup', data: {
      'fullName': name,
      'email': email,
      'password': password,
      'state': state,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    final response = await _dio.post('/auth/resend-verification', data: {
      'email': email,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─── Assets ──────────────────────────────────────────

  Future<List<Asset>> getAssets() async {
    final response = await _dio.get('/api/assets/list');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> assets = data['assets'] as List<dynamic>? ?? [];
    return assets.map((json) => Asset.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Asset> addAsset(Asset asset) async {
    final response = await _dio.post('/api/assets/add', data: asset.toJson());
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<Asset> updateAsset(int id, Asset asset) async {
    final response = await _dio.put('/api/assets/$id', data: asset.toJson());
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  Future<void> deleteAsset(int id) async {
    await _dio.delete('/api/assets/$id');
  }

  Future<Map<String, dynamic>> getAssetTotal() async {
    final response = await _dio.get('/api/assets/total');
    return response.data as Map<String, dynamic>;
  }

  Future<Asset> updateAssetPrice(int id, {required String symbol, String source = 'crypto'}) async {
    final response = await _dio.post('/api/assets/$id/update-price', data: {
      'symbol': symbol,
      'source': source,
    });
    final data = response.data as Map<String, dynamic>;
    return Asset.fromJson(data['asset'] as Map<String, dynamic>);
  }

  // ─── Prices ──────────────────────────────────────────

  Future<CryptoPrice> getCryptoPrice(String symbol) async {
    final response = await _dio.get('/api/prices/crypto/$symbol');
    return CryptoPrice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StockPrice> getStockPrice(String symbol) async {
    final response = await _dio.get('/api/prices/stock/$symbol');
    return StockPrice.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> getSupportedCryptos() async {
    final response = await _dio.get('/api/prices/crypto');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.cast<String>();
  }

  // ─── Health ──────────────────────────────────────────

  Future<String> healthCheck() async {
    final response = await _dio.get('/health');
    return response.data.toString();
  }

  // ─── Transactions ────────────────────────────────────

  Future<List<Transaction>> getTransactions({String? type, int limit = 50}) async {
    final params = <String, dynamic>{'limit': limit};
    if (type != null) params['type'] = type;
    final response = await _dio.get('/api/transactions/list', queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> transactions = data['transactions'] as List<dynamic>? ?? [];
    return transactions.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final response = await _dio.post('/api/transactions/add', data: transaction.toJson());
    final data = response.data as Map<String, dynamic>;
    return Transaction.fromJson(data['transaction'] as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(int id) async {
    await _dio.delete('/api/transactions/$id');
  }

  Future<Map<String, dynamic>> getTransactionSummary({String period = 'month'}) async {
    final response = await _dio.get('/api/transactions/summary', queryParameters: {'period': period});
    return response.data as Map<String, dynamic>;
  }

  // ─── Halal Screener ──────────────────────────────────

  Future<Map<String, dynamic>> checkHalalStock(String symbol) async {
    final response = await _dio.get('/api/halal/check/$symbol');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHalalStocks({String? search, String? sector}) async {
    final params = <String, dynamic>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (sector != null && sector.isNotEmpty) params['sector'] = sector;
    final response = await _dio.get('/api/halal/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHalalSectors() async {
    final response = await _dio.get('/api/halal/sectors');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getHalalStats() async {
    final response = await _dio.get('/api/halal/stats');
    return response.data as Map<String, dynamic>;
  }

  // ─── Password Reset ─────────────────────────────────

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _dio.post('/auth/forgot-password', data: {'email': email});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    final response = await _dio.post('/auth/reset-password', data: {
      'token': token,
      'newPassword': newPassword,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─── Profile ─────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/auth/profile');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? email,
    String? currentPassword,
    String? newPassword,
  }) async {
    final data = <String, String>{};
    if (fullName != null) data['fullName'] = fullName;
    if (email != null) data['email'] = email;
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (newPassword != null) data['newPassword'] = newPassword;
    final response = await _dio.put('/auth/update-profile', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAccount(String password) async {
    await _dio.delete('/auth/delete-account', data: {'password': password});
  }

  // ─── Savings Goals ───────────────────────────────────

  Future<Map<String, dynamic>> getSavingsGoals() async {
    final response = await _dio.get('/api/savings-goals/list');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addSavingsGoal({
    required String name,
    required double targetAmount,
    required String category,
    String? description,
    String currency = 'USD',
    int? deadline,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'targetAmount': targetAmount,
      'category': category,
      'currency': currency,
    };
    if (description != null) data['description'] = description;
    if (deadline != null) data['deadline'] = deadline;
    final response = await _dio.post('/api/savings-goals/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateSavingsGoal(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/savings-goals/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> contributeSavingsGoal(int id, double amount) async {
    final response = await _dio.post('/api/savings-goals/$id/contribute', data: {'amount': amount});
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteSavingsGoal(int id) async {
    await _dio.delete('/api/savings-goals/$id');
  }

  // ─── Recurring Transactions ──────────────────────────

  Future<List<Transaction>> getRecurringTransactions() async {
    final response = await _dio.get('/api/transactions/recurring');
    final data = response.data as Map<String, dynamic>;
    final List<dynamic> transactions = data['transactions'] as List<dynamic>? ?? [];
    return transactions.map((json) => Transaction.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> toggleRecurring(int id) async {
    final response = await _dio.put('/api/transactions/$id/toggle-recurring');
    return response.data as Map<String, dynamic>;
  }

  // ─── Budgets ─────────────────────────────────────────

  Future<Map<String, dynamic>> getBudgets({int? month, int? year}) async {
    final params = <String, dynamic>{};
    if (month != null) params['month'] = month;
    if (year != null) params['year'] = year;
    final response = await _dio.get('/api/budgets/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addBudget({
    required String category,
    required double monthlyLimit,
    int? month,
    int? year,
    String? color,
  }) async {
    final data = <String, dynamic>{
      'category': category,
      'monthlyLimit': monthlyLimit,
    };
    if (month != null) data['month'] = month;
    if (year != null) data['year'] = year;
    if (color != null) data['color'] = color;
    final response = await _dio.post('/api/budgets/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBudget(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/budgets/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBudget(int id) async {
    await _dio.delete('/api/budgets/$id');
  }

  // ─── Debts ───────────────────────────────────────────

  Future<Map<String, dynamic>> getDebts({String? status}) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    final response = await _dio.get('/api/debts/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addDebt({
    required String name,
    required String type,
    required double totalAmount,
    double? remainingAmount,
    double? monthlyPayment,
    double? interestRate,
    bool? ribaFree,
    String? lender,
    String? description,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'type': type,
      'totalAmount': totalAmount,
    };
    if (remainingAmount != null) data['remainingAmount'] = remainingAmount;
    if (monthlyPayment != null) data['monthlyPayment'] = monthlyPayment;
    if (interestRate != null) data['interestRate'] = interestRate;
    if (ribaFree != null) data['ribaFree'] = ribaFree;
    if (lender != null) data['lender'] = lender;
    if (description != null) data['description'] = description;
    final response = await _dio.post('/api/debts/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> makeDebtPayment(int id, double amount) async {
    final response = await _dio.post('/api/debts/$id/payment', data: {'amount': amount});
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteDebt(int id) async {
    await _dio.delete('/api/debts/$id');
  }

  Future<Map<String, dynamic>> updateDebt(int id, {
    required String name,
    required String type,
    required double totalAmount,
    double? monthlyPayment,
    double? interestRate,
    bool? ribaFree,
    String? lender,
  }) async {
    final response = await _dio.put('/api/debts/$id', data: {
      'name': name,
      'type': type,
      'totalAmount': totalAmount,
      'monthlyPayment': ?monthlyPayment,
      'interestRate': ?interestRate,
      'ribaFree': ?ribaFree,
      'lender': ?lender,
    });
    return response.data as Map<String, dynamic>;
  }

  // ─── Bills ───────────────────────────────────────────

  Future<Map<String, dynamic>> getBills({bool? paid}) async {
    final params = <String, dynamic>{};
    if (paid != null) params['paid'] = paid;
    final response = await _dio.get('/api/bills/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addBill({
    required String name,
    required double amount,
    required int dueDay,
    String category = 'other',
    String frequency = 'monthly',
    String? description,
    bool reminderEnabled = true,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'amount': amount,
      'dueDay': dueDay,
      'category': category,
      'frequency': frequency,
      'reminderEnabled': reminderEnabled,
    };
    if (description != null) data['description'] = description;
    final response = await _dio.post('/api/bills/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markBillPaid(int id) async {
    final response = await _dio.post('/api/bills/$id/mark-paid');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUpcomingBills() async {
    final response = await _dio.get('/api/bills/upcoming');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteBill(int id) async {
    await _dio.delete('/api/bills/$id');
  }

  // ─── Hawl Tracker ────────────────────────────────────

  Future<Map<String, dynamic>> getHawlTrackers({bool activeOnly = true}) async {
    final response = await _dio.get('/api/hawl/list', queryParameters: {'activeOnly': activeOnly});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addHawlTracker({
    required String assetName,
    required double amount,
    String assetType = 'cash',
    int? hawlStartDate,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'assetName': assetName,
      'amount': amount,
      'assetType': assetType,
    };
    if (hawlStartDate != null) data['hawlStartDate'] = hawlStartDate;
    if (notes != null) data['notes'] = notes;
    final response = await _dio.post('/api/hawl/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> markHawlZakatPaid(int id) async {
    final response = await _dio.post('/api/hawl/$id/mark-paid');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteHawlTracker(int id) async {
    await _dio.delete('/api/hawl/$id');
  }

  // ─── Sadaqah ─────────────────────────────────────────

  Future<Map<String, dynamic>> getSadaqahList({String? category, String? period}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (period != null) params['period'] = period;
    final response = await _dio.get('/api/sadaqah/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addSadaqah({
    required double amount,
    String category = 'general',
    String? recipientName,
    String? recipientType,
    String? description,
    bool anonymous = false,
  }) async {
    final data = <String, dynamic>{
      'amount': amount,
      'category': category,
      'anonymous': anonymous,
    };
    if (recipientName != null) data['recipientName'] = recipientName;
    if (recipientType != null) data['recipientType'] = recipientType;
    if (description != null) data['description'] = description;
    final response = await _dio.post('/api/sadaqah/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSadaqahStats() async {
    final response = await _dio.get('/api/sadaqah/stats');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteSadaqah(int id) async {
    await _dio.delete('/api/sadaqah/$id');
  }

  // ─── Wasiyyah (Islamic Will) ─────────────────────────

  Future<Map<String, dynamic>> getWasiyyahList() async {
    final response = await _dio.get('/api/wasiyyah/list');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addWasiyyahBeneficiary({
    required String beneficiaryName,
    required String relationship,
    required double sharePercentage,
    String shareType = 'fixed',
    String? assetDescription,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      'beneficiaryName': beneficiaryName,
      'relationship': relationship,
      'sharePercentage': sharePercentage,
      'shareType': shareType,
    };
    if (assetDescription != null) data['assetDescription'] = assetDescription;
    if (notes != null) data['notes'] = notes;
    final response = await _dio.post('/api/wasiyyah/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getIslamicShares() async {
    final response = await _dio.get('/api/wasiyyah/islamic-shares');
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteWasiyyahBeneficiary(int id) async {
    await _dio.delete('/api/wasiyyah/$id');
  }

  // ─── Waqf ────────────────────────────────────────────

  Future<Map<String, dynamic>> getWaqfList({String? purpose}) async {
    final params = <String, dynamic>{};
    if (purpose != null) params['purpose'] = purpose;
    final response = await _dio.get('/api/waqf/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addWaqf({
    required String organizationName,
    required double amount,
    String type = 'cash',
    String purpose = 'general',
    String? description,
    bool recurring = false,
    String? frequency,
  }) async {
    final data = <String, dynamic>{
      'organizationName': organizationName,
      'amount': amount,
      'type': type,
      'purpose': purpose,
      'recurring': recurring,
    };
    if (description != null) data['description'] = description;
    if (frequency != null) data['frequency'] = frequency;
    final response = await _dio.post('/api/waqf/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteWaqf(int id) async {
    await _dio.delete('/api/waqf/$id');
  }

  Future<Map<String, dynamic>> updateWaqf(int id, {
    String? organizationName,
    double? amount,
    String? type,
    String? purpose,
    String? description,
    bool? recurring,
    String? frequency,
  }) async {
    final data = <String, dynamic>{};
    if (organizationName != null) data['organizationName'] = organizationName;
    if (amount != null) data['amount'] = amount;
    if (type != null) data['type'] = type;
    if (purpose != null) data['purpose'] = purpose;
    if (description != null) data['description'] = description;
    if (recurring != null) data['recurring'] = recurring;
    if (frequency != null) data['frequency'] = frequency;
    final response = await _dio.put('/api/waqf/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  // ─── Riba Detector ──────────────────────────────────

  Future<Map<String, dynamic>> scanForRiba() async {
    final response = await _dio.get('/api/riba/scan');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeTransaction(int transactionId) async {
    final response = await _dio.get('/api/riba/analyze/$transactionId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getIslamicAlternatives() async {
    final response = await _dio.get('/api/riba/alternatives');
    return response.data as Map<String, dynamic>;
  }

  // ─── Auto Categorization ────────────────────────────

  Future<Map<String, dynamic>> suggestCategory(String description) async {
    final response = await _dio.get('/api/categorize/suggest', queryParameters: {'description': description});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reviewCategories() async {
    final response = await _dio.get('/api/categorize/review');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> applyAutoCategories({int minConfidence = 60}) async {
    final response = await _dio.post('/api/categorize/apply', queryParameters: {'minConfidence': minConfidence});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAvailableCategories() async {
    final response = await _dio.get('/api/categorize/categories');
    return response.data as Map<String, dynamic>;
  }

  // ─── Export Data (PDF/CSV) ───────────────────────────

  Future<List<int>> exportTransactionsCsv({String period = 'month', String? type}) async {
    final params = <String, dynamic>{'period': period};
    if (type != null) params['type'] = type;
    final response = await _dio.get(
      '/api/transactions/export/csv',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }

  Future<List<int>> exportTransactionsPdf({String period = 'month', String? type}) async {
    final params = <String, dynamic>{'period': period};
    if (type != null) params['type'] = type;
    final response = await _dio.get(
      '/api/transactions/export/pdf',
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data as List<int>;
  }

  // ─── Net Worth ───────────────────────────────────────

  Future<Map<String, dynamic>> getNetWorthHistory({String period = '6m'}) async {
    final response = await _dio.get('/api/net-worth/history', queryParameters: {'period': period});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recordNetWorthSnapshot() async {
    final response = await _dio.post('/api/net-worth/snapshot');
    return response.data as Map<String, dynamic>;
  }

  // ─── Shared Finances ────────────────────────────────

  Future<Map<String, dynamic>> createSharedGroup(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/shared/groups/create', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinSharedGroup(String inviteCode) async {
    final response = await _dio.post('/api/shared/groups/join', data: {'inviteCode': inviteCode});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSharedGroups() async {
    final response = await _dio.get('/api/shared/groups/list');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSharedGroupDetails(int groupId) async {
    final response = await _dio.get('/api/shared/groups/$groupId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addSharedTransaction(int groupId, Map<String, dynamic> data) async {
    final response = await _dio.post('/api/shared/groups/$groupId/transactions/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSharedTransactions(int groupId, {String? type}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    final response = await _dio.get('/api/shared/groups/$groupId/transactions', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteSharedTransaction(int groupId, int txnId) async {
    final response = await _dio.delete('/api/shared/groups/$groupId/transactions/$txnId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSharedGroupSummary(int groupId, {String period = 'month'}) async {
    final response = await _dio.get('/api/shared/groups/$groupId/summary', queryParameters: {'period': period});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> regenerateInviteCode(int groupId) async {
    final response = await _dio.post('/api/shared/groups/$groupId/regenerate-invite');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> leaveSharedGroup(int groupId) async {
    final response = await _dio.post('/api/shared/groups/$groupId/leave');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteSharedGroup(int groupId) async {
    final response = await _dio.delete('/api/shared/groups/$groupId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> removeSharedGroupMember(int groupId, int memberId) async {
    final response = await _dio.delete('/api/shared/groups/$groupId/members/$memberId');
    return response.data as Map<String, dynamic>;
  }

  // ─── Zakat Payments ─────────────────────────────────

  Future<Map<String, dynamic>> getZakatPayments({int? lunarYear}) async {
    final params = <String, dynamic>{};
    if (lunarYear != null) params['lunarYear'] = lunarYear;
    final response = await _dio.get('/api/zakat/payments', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addZakatPayment({
    required double amount,
    String? recipient,
    String? notes,
    int? lunarYear,
    int? paidAt,
  }) async {
    final data = <String, dynamic>{
      'amount': amount,
    };
    if (recipient != null) data['recipient'] = recipient;
    if (notes != null) data['notes'] = notes;
    if (lunarYear != null) data['lunarYear'] = lunarYear;
    if (paidAt != null) data['paidAt'] = paidAt;
    final response = await _dio.post('/api/zakat/payments', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteZakatPayment(int id) async {
    await _dio.delete('/api/zakat/payments/$id');
  }

  // ─── Investment Accounts ────────────────────────────

  Future<Map<String, dynamic>> addInvestmentAccount(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/investments/accounts/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInvestmentAccounts({String? type}) async {
    final params = <String, dynamic>{};
    if (type != null) params['type'] = type;
    final response = await _dio.get('/api/investments/accounts/list', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInvestmentAccount(int id) async {
    final response = await _dio.get('/api/investments/accounts/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateInvestmentAccount(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/investments/accounts/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteInvestmentAccount(int id) async {
    final response = await _dio.delete('/api/investments/accounts/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addInvestmentHolding(int accountId, Map<String, dynamic> data) async {
    final response = await _dio.post('/api/investments/accounts/$accountId/holdings/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getInvestmentHoldings(int accountId) async {
    final response = await _dio.get('/api/investments/accounts/$accountId/holdings');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateInvestmentHolding(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/investments/holdings/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateHoldingPrice(int id, double price) async {
    final response = await _dio.put('/api/investments/holdings/$id/price', data: {'currentPrice': price});
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteInvestmentHolding(int id) async {
    final response = await _dio.delete('/api/investments/holdings/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPortfolioSummary() async {
    final response = await _dio.get('/api/investments/portfolio/summary');
    return response.data as Map<String, dynamic>;
  }

  // ─── Credit Score ────────────────────────────────────

  Future<Map<String, dynamic>> addCreditScore(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/credit-score/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLatestCreditScore() async {
    final response = await _dio.get('/api/credit-score/latest');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCreditScoreHistory() async {
    final response = await _dio.get('/api/credit-score/history');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCreditScore(int id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/credit-score/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteCreditScore(int id) async {
    final response = await _dio.delete('/api/credit-score/$id');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCreditScoreTips() async {
    final response = await _dio.get('/api/credit-score/tips');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> simulateCreditScore({int? utilization, int? payments, int? inquiries}) async {
    final params = <String, dynamic>{};
    if (utilization != null) params['utilization'] = utilization;
    if (payments != null) params['payments'] = payments;
    if (inquiries != null) params['inquiries'] = inquiries;
    final response = await _dio.get('/api/credit-score/simulate', queryParameters: params);
    return response.data as Map<String, dynamic>;
  }

  // ─── Import (Monarch Money) ──────────────────────────────────────────────

  /// Upload a Monarch Money Balances CSV for preview.
  Future<Map<String, dynamic>> monarchPreview(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'balances.csv'),
    });
    final response = await _dio.post(
      '/api/import/monarch/preview',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Execute the Monarch import with the user-confirmed account selections.
  Future<Map<String, dynamic>> monarchExecute(List<Map<String, dynamic>> accounts) async {
    final response = await _dio.post(
      '/api/import/monarch/execute',
      data: {'accounts': accounts},
    );
    return response.data as Map<String, dynamic>;
  }
}
