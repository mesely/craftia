import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/complaint.dart';

class ComplaintsRepository {
  ComplaintsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<ComplaintReceipt> submit({
    required String reporterId,
    required ComplaintTarget target,
    required ComplaintReason reason,
    String details = '',
  }) => guarded(
    () async => ComplaintReceipt.fromJson(
      await _remote.createComplaint({
        'reporterId': reporterId,
        'targetType': target.type.name,
        'targetId': target.id,
        if (target.name.isNotEmpty) 'targetName': target.name,
        'conversationId': ?target.conversationId,
        'reason': reason.apiValue,
        if (details.trim().isNotEmpty) 'details': details.trim(),
      }),
    ),
  );
}
