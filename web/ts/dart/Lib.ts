
interface DartFuncs {
  dartJMsgUserSignin: (mail: string, pass: string) => string;
  dartJMsgUserLogout: () => string;
  dartJMsgUserRegistration: (mail: string, pass: string,
    firstName: string, secondName: string) => string;
  dartJMsgDoc2X: (doc: string, docx: string) => string;
  dartJMsgZip: (dir: string, zip: string) => string;
  dartJMsgUnzip: (zip: string, dir: string) => string;
  dartJMsgNewTask: (settings: string) => string;
}
export const funcs = (window as unknown as DartFuncs);


export interface JUser {
  access: string,
  mail: string,
  pass: string,
  first_name?: string,
  second_name?: string,
}

export interface JTaskSettings {
  /// Почта пользователя запустившего задачу.
  user: string;

  /// Почта пользователей которым доступна задача
  users?: string[];

  /// Название задачи
  name?: string;

  /// Список сканируемых путей
  path?: string[];

  /// Расширения для архивных файлов
  'ar-e'?: string[];

  /// Расширения для файлов LAS и Инклинометрией
  'f-e'?: string[];

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
  'ar-s'?: number;

  /// Максимальный глубина прохода по архивам
  /// * `-1` - для бесконечной вложенности (По умолчанию)
  /// * `0` - для отбрасывания всех архивов
  /// * `1` - для входа на один уровень архива
  'ar-d'?: number;

  /// Время обновления каждой задачи в реальном времени в мс
  /// * 333мс по умолчанию
  'ud'?: number;
}

export const JTaskSettings_defs: JTaskSettings = {
  user: "any",
  users: ['@guest'],
  name: '@unnamed',
  path: ['D:\\Искринское м-е'],
  'ar-e': ['.zip', '.rar'],
  'f-e': ['.las', '.doc', '.docx', '.txt', '.dbf'],
  'ar-s': 1024 * 1024 * 1024,
  'ar-d': -1,
  'ud': 333,
}
