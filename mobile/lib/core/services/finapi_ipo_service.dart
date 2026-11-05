import 'package:dio/dio.dart';

class FinApiIpoService {
  static final FinApiIpoService _instance = FinApiIpoService._internal();
  factory FinApiIpoService() => _instance;
  FinApiIpoService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://finapi.upvaly.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  List<Map<String, dynamic>>? _cachedIpos;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 45);

  /// Fetch all market IPOs (Live, Upcoming, and Closed)
  Future<List<Map<String, dynamic>>> fetchMarketIpos({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedIpos != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedIpos!;
    }

    try {
      final response = await _dio.get('/api/ipo');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic raw = response.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map && raw['data'] is List) {
          list = raw['data'] as List;
        }

        final parsed = list.map((item) {
          final m = Map<String, dynamic>.from(item as Map);
          return _normalizeIpoItem(m);
        }).toList();

        _cachedIpos = parsed;
        _lastFetchTime = DateTime.now();
        return parsed;
      }
    } catch (e) {
      // If network fails and cache is available, return cache
      if (_cachedIpos != null) return _cachedIpos!;
    }

    return _cachedIpos ?? [];
  }

  /// Normalize and parse fields from FinAPI schema
  static Map<String, dynamic> _normalizeIpoItem(Map<String, dynamic> raw) {
    final symbol = (raw['symbol'] ?? raw['ticker'] ?? '').toString().toUpperCase().trim();
    final name = (raw['name'] ?? raw['companyName'] ?? symbol).toString().trim();
    final type = (raw['type'] ?? 'Mainboard').toString().trim();
    final status = (raw['status'] ?? 'LIVE').toString().toUpperCase().trim();

    // Price range & cut-off parsing
    final priceRangeStr = (raw['priceRange'] ?? raw['price'] ?? '').toString();
    double cutOffPrice = 0.0;
    final priceMatches = RegExp(r'\d+(\.\d+)?').allMatches(priceRangeStr);
    if (priceMatches.isNotEmpty) {
      final numbers = priceMatches.map((m) => double.tryParse(m.group(0)!) ?? 0.0).toList();
      cutOffPrice = numbers.reduce((curr, next) => curr > next ? curr : next);
    }

    // Lot size parsing
    final lotSizeRaw = raw['lotSize'] ?? raw['sharesPerLot'] ?? 1;
    final int lotSize = int.tryParse(lotSizeRaw.toString().replaceAll(RegExp(r'[^\d]'), '')) ?? 1;

    // Schedule dates
    final schedule = raw['schedule'] as Map<String, dynamic>? ?? {};
    final startDate = (schedule['startDate'] ?? raw['openDate'] ?? '').toString();
    final endDate = (schedule['endDate'] ?? raw['closeDate'] ?? '').toString();
    final allotmentDate = (schedule['allotmentFinalization'] ?? raw['allotmentDate'] ?? '').toString();
    final listingDate = (schedule['listingDate'] ?? raw['listingDate'] ?? '').toString();
    final refundDate = (schedule['refundInitiation'] ?? '').toString();

    // Registrar
    final registrar = (raw['registrar'] ?? raw['registrarName'] ?? '').toString().trim();

    // GMP (Grey Market Premium) if provided
    double gmp = 0.0;
    double expectedGain = 0.0;
    if (raw['greyMarketPremium'] is Map) {
      final gmpMap = raw['greyMarketPremium'] as Map;
      gmp = double.tryParse(gmpMap['gmp']?.toString() ?? '0') ?? 0.0;
      expectedGain = double.tryParse(gmpMap['percentage']?.toString() ?? '0') ?? 0.0;
    } else if (raw['gmp'] != null) {
      gmp = double.tryParse(raw['gmp'].toString()) ?? 0.0;
    }

    return {
      'symbol': symbol,
      'name': name,
      'type': type.toUpperCase().contains('SME') ? 'SME' : 'MAINBOARD',
      'status': status,
      'priceRange': priceRangeStr.isEmpty ? '₹$cutOffPrice' : priceRangeStr,
      'cutOffPrice': cutOffPrice,
      'lotSize': lotSize > 0 ? lotSize : 1,
      'startDate': startDate,
      'endDate': endDate,
      'allotmentDate': allotmentDate,
      'listingDate': listingDate,
      'refundDate': refundDate,
      'registrar': registrar,
      'gmp': gmp,
      'expectedListingGain': expectedGain,
      'raw': raw,
    };
  }

  /// Get Registrar status check direct URL
  static String getRegistrarUrl(String registrarName, String? symbol) {
    final lower = registrarName.toLowerCase();
    if (lower.contains('link intime') || lower.contains('linkintime')) {
      return 'https://linkintime.co.in/initial_offer/public-issues.html';
    } else if (lower.contains('kfin') || lower.contains('karvy')) {
      return 'https://kosmic.kfintech.com/ipostatus';
    } else if (lower.contains('bigshare')) {
      return 'https://ipo.bigshareonline.com/';
    } else if (lower.contains('skyline')) {
      return 'https://www.skylinerta.com/ipo.php';
    } else if (lower.contains('purva')) {
      return 'https://www.purvashare.com/queries/';
    } else if (lower.contains('cameo')) {
      return 'https://ipo.cameoindia.com/';
    }
    // Fallback: BSE India direct IPO allotment lookup
    return 'https://www.bseindia.com/investors/appli_check.aspx';
  }
}
