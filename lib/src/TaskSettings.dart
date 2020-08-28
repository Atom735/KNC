class TaskSettings {
  /// Название задачи
  final String name;
  static const def_name = '@unnamed';

  /// Имя пользователя запустившего задачу
  final String user;

  /// Список сканируемых путей
  final List<String> path;
  static const def_path = [r'D:\Искринское м-е'];

  /// Настройки расширения для архивных файлов
  final List<String> ext_ar;
  static const def_ext_ar = ['.zip', '.rar'];

  /// Настройки расширения для файлов LAS и Инклинометрией
  final List<String> ext_files;
  static const def_ext_files = ['.las', '.doc', '.docx', '.txt', '.dbf'];

  /// Максимальный размер вскрываемого архива в байтах
  ///
  /// Для задания значения можно использовать постфиксы:
  /// * `k` = КилоБайты
  /// * `m` = МегаБайты = `kk`
  /// * `g` = ГигаБайты = `kkk`
  ///
  /// `0` - для всех архивов
  ///
  /// По умолчанию 1Gb
  final int maxsize_ar;
  static const def_maxsize_ar = 1024 * 1024 * 1024;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  final int maxdepth_ar;
  static const def_maxdepth_ar = -1;

  TaskSettings(
      {this.user,
      this.name = def_name,
      this.path = def_path,
      this.ext_ar = def_ext_ar,
      this.ext_files = def_ext_files,
      this.maxsize_ar = def_maxsize_ar,
      this.maxdepth_ar = def_maxdepth_ar});

  TaskSettings.fromJson(final Map<String, Object> json)
      : user = json['user'],
        name = json['name'] ?? def_name,
        path = ((json['path'] ?? def_path) as Iterable)
            .map((e) => e as String)
            .toList(growable: false),
        ext_ar = ((json['ext_ar'] ?? def_ext_ar) as Iterable)
            .map((e) => e as String)
            .toList(growable: false),
        ext_files = ((json['ext_las'] ?? def_ext_files) as Iterable)
            .map((e) => e as String)
            .toList(growable: false),
        maxsize_ar = json['maxsize_ar'] ?? def_maxsize_ar,
        maxdepth_ar = json['maxdepth_ar'] ?? def_maxdepth_ar;

  Map<String, Object> get json => {
        'name': name,
        'path': path,
        'ext_ar': ext_ar,
        'ext_las': ext_files,
        'maxsize_ar': maxsize_ar,
        'maxdepth_ar': maxdepth_ar
      };
}
