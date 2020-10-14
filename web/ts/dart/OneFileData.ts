export enum NOneFileDataType { unknown, las, docx, ink_docx }


/// Значения иследований
export interface JOneFilesDataCurve {
    /// Наименование скважины
    well: string;

    /// Наименоваине кривой (.ink - для инклинометрии)
    name: string;

    /// Глубина начальной точки кривой
    strt: number;

    /// Глубина конечной точки кривой
    stop: number;

    /// Шаг точек (0 для инклинометрии)
    step: number;

    /// Значения в точках (у инклинометрии по три значения на точку)
    data: Array<number>;
}

/// Заметка на одной линии
export interface JOneFileLineNote {
    /// Номер линии
    line: number;

    /// Номер символа в строке
    column: number;

    /// Текст заметки
    /// * `!E` - ошибка
    /// * `!W` - предупреждение
    /// * `!P` - разобранная строка, разделяется символом [msgRecordSeparator],
    text: string;

    /// Доп. данные заметки (обычно то что записано в строке)
    data?: string;

}

/// Данные связанные с файлом.
///
/// Обычно хранятся рядом с самим файлом.
export interface JOneFileData {
    /// Путь к сущности обработанного файла
    path: string;

    /// Путь к оригинальной сущности файла
    origin: string;

    /// Тип файла
    type: NOneFileDataType;

    /// Размер файла в байтах
    size: number;

    /// Кодировка текстового файла
    encode?: string;

    /// Кривые найденные в файле
    curves?: Array<JOneFilesDataCurve>;

    /// Заметки файла
    notes?: Array<JOneFileLineNote>;

    /// Количество ошибок
    'n-errors'?: number;

    /// Количество предупрежений
    'n-warn'?: number;
}
