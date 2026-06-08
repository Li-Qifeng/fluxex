import '../models/topic.dart';

class TopicListResult {
  final List<Topic> topics;
  final bool fromCache;
  final Object? error;

  const TopicListResult(this.topics, {this.fromCache = false, this.error});

  bool get hasError => error != null;
}
