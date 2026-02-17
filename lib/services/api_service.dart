import 'package:dio/dio.dart';
import 'package:barakah_app/services/auth_service.dart';
import 'package:barakah_app/models/asset.dart';
import 'package:barakah_app/models/price.dart';
import 'package:barakah_app/models/transaction.dart';

class ApiService {
  static const String baseUrl = 'https://api.trybarakah.com';

  late final Dio _dio;
  final AuthService _authService;

  ApiService(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
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
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _authService.logout();
        }
        return handler.next(error);
      },
    ));
  }

  // ─── Auth ────────────────────────────────────────────

  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final response = await _dio.post('/auth/signup', data: {
      'fullName': name,
      'email': email,
      'password': password,
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

  Future<Map<String, dynamic>> getHalalStocks() async {
    final response = await _dio.get('/api/halal/list');
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
}
