class SublistProgress {
  final int currentIndex;
  final int completedCount;
  final bool completed;

  const SublistProgress({
    required this.currentIndex,
    required this.completedCount,
    required this.completed,
  });

  const SublistProgress.empty()
      : currentIndex = 0,
        completedCount = 0,
        completed = false;

  factory SublistProgress.fromJson(Map<String, dynamic> json) {
    return SublistProgress(
      currentIndex: (json['currentIndex'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentIndex': currentIndex,
        'completedCount': completedCount,
        'completed': completed,
      };
}
