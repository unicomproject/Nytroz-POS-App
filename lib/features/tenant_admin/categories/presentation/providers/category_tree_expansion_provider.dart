import 'package:flutter_riverpod/flutter_riverpod.dart';

final categoryTreeExpansionProvider = StateNotifierProvider.autoDispose<
    CategoryTreeExpansionController, Set<String>>(
  (ref) => CategoryTreeExpansionController(),
);

class CategoryTreeExpansionController extends StateNotifier<Set<String>> {
  CategoryTreeExpansionController() : super(const {});

  bool isExpanded(String nodeId) => state.contains(nodeId);

  void toggle(String nodeId) {
    if (state.contains(nodeId)) {
      state = Set<String>.from(state)..remove(nodeId);
    } else {
      state = {...state, nodeId};
    }
  }

  void expandMany(Iterable<String> ids) {
    if (ids.isEmpty) return;
    state = {...state, ...ids};
  }

  void collapseAll() => state = const {};
}
