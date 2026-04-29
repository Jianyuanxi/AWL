class Word {
  final int id;
  final String english;
  final String phonetic;
  final String chinese;
  final String example;
  int errorCount;

  Word({
    required this.id,
    required this.english,
    this.phonetic = '',
    this.chinese = '',
    this.example = '',
    this.errorCount = 0,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int,
      english: json['english'] as String,
      phonetic: json['phonetic'] as String? ?? '',
      chinese: json['chinese'] as String? ?? '',
      example: json['example'] as String? ?? '',
    );
  }
}
