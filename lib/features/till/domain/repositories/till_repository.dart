import '../entities/open_till.dart';

abstract class TillRepository {
  Future<TillSession> openTill(OpenTillForm form);
  Future<TillSession?> getCurrentSession(OpenTillForm form);
}
