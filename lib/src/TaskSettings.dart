/// Класс содержащий параметры и настройки поставленной задачи
class JTaskSettings {
  /// Почта пользователя запустившего задачу.
  final String user;
  static const jsonKey_user = 'user';

  /// Почта пользователей которым доступна задача
  final List<String>? users;
  static const jsonKey_users = 'users';
  static const def_users = ['@guest'];

  /// Название задачи
  final String name;
  static const jsonKey_name = 'name';
  static const def_name = '@unnamed';

  /// Список сканируемых путей
  final List<String> path;
  static const jsonKey_path = 'path';
  static const def_path = [r'D:\Искринское м-е'];

  /// Расширения для архивных файлов
  final List<String> ext_ar;
  static const jsonKey_ext_ar = 'ar-e';
  static const def_ext_ar = ['.zip', '.rar'];

  /// Расширения для файлов LAS и Инклинометрией
  final List<String> ext_files;
  static const jsonKey_ext_files = 'f-e';
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
  static const jsonKey_maxsize_ar = 'ar-s';
  static const def_maxsize_ar = 1024 * 1024 * 1024;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  final int maxdepth_ar;
  static const jsonKey_maxdepth_ar = 'ar-d';
  static const def_maxdepth_ar = -1;

  /// Время обновления каждой задачи в реальном времени в мс
  /// * 333мс по умолчанию
  final int update_duration;
  static const jsonKey_update_duration = 'ud';
  static const def_update_duration = 333;

  JTaskSettings(
      {required this.user,
      this.users = def_users,
      this.name = def_name,
      this.path = def_path,
      this.ext_ar = def_ext_ar,
      this.ext_files = def_ext_files,
      this.maxsize_ar = def_maxsize_ar,
      this.maxdepth_ar = def_maxdepth_ar,
      this.update_duration = def_update_duration});

  JTaskSettings.fromJson(final Map<String, dynamic> m)
      : user = m[jsonKey_user] as String,
        users = (m[jsonKey_users] as List?)
                ?.map((e) => e as String)
                .toList(growable: false) ??
            def_users,
        name = (m[jsonKey_name] as String?) ?? def_name,
        path = (m[jsonKey_path] as List?)
                ?.map((e) => e as String)
                .toList(growable: false) ??
            def_path,
        ext_ar = (m[jsonKey_ext_ar] as String?)?.split(';') ?? def_ext_ar,
        ext_files =
            (m[jsonKey_ext_files] as String?)?.split(';') ?? def_ext_files,
        maxsize_ar = (m[jsonKey_maxsize_ar] as int?) ?? def_maxsize_ar,
        maxdepth_ar = (m[jsonKey_maxdepth_ar] as int?) ?? def_maxdepth_ar,
        update_duration =
            (m[jsonKey_update_duration] as int?) ?? def_update_duration;

  Map<String, dynamic> toJson() => {
        jsonKey_user: user,
        jsonKey_users: users,
        jsonKey_name: name,
        jsonKey_path: path,
        jsonKey_ext_ar: ext_ar,
        jsonKey_ext_files: ext_files,
        jsonKey_maxsize_ar: maxsize_ar,
        jsonKey_maxdepth_ar: maxdepth_ar,
        jsonKey_update_duration: update_duration,
      };
}
