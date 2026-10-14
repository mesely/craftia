import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/category.dart';
import '../models/filter_state.dart';
import '../models/paged.dart';
import '../models/provider_application.dart';
import '../models/usta.dart';

class UstaRepository {
  UstaRepository(this._remote);

  final RemoteDataSource _remote;

  Future<Paged<Usta>> fetchPage(ProviderQuery query, int page) async {
    try {
      final json = await _remote.getProviders(query.toQueryParameters(page));
      final items = (json['items'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => Usta.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return Paged(
        items: items,
        total: (json['total'] as num?)?.toInt() ?? items.length,
        page: page,
        hasMore: json['hasMore'] == true,
      );
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  Future<Usta> getById(String id) async {
    try {
      return Usta.fromJson(await _remote.getProvider(id));
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  Future<List<ProviderCategory>> fetchCategories() async {
    try {
      return (await _remote.getCategories())
          .whereType<Map>()
          .map((e) => ProviderCategory.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }

  Future<Usta> apply(ProviderApplication application) async {
    try {
      return Usta.fromJson(await _remote.createProvider(application.toJson()));
    } on AppFailure {
      rethrow;
    } catch (_) {
      throw AppFailure.unknown;
    }
  }
}
