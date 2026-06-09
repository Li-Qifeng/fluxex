import '../models/topic.dart';

class TopicListResult {
  final List<Topic> topics;
  final bool fromCache;
  final Object? error;
  final String filter;

  const TopicListResult(this.topics, {this.fromCache = false, this.error, this.filter = ''});

  bool get hasError => error != null;
}
