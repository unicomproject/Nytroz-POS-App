import '../entities/open_till.dart';

abstract class TillRepository {
  Future<TillSession> openTill(OpenTillForm form);
}
