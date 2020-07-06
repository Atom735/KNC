# KNC

* [ ] проходим по списку всех путей

* [ ] обходим по всем файлам

* [ ] разархивируем архивы во временную папку и продолжаем обход там

* [ ] отправляем файлы на обработку изолятам

* [ ] получая данные от изолятов, готовим конечную таблицу данных

* [x] полностью разбираем LAS файл

* [ ] разбираем файлы с инклинометрией TXT

* [ ] разбираем файлы с инклинометрией DOC (DOCX)

* [ ] разбираем файлы баз данных DBF

* [x] формируем таблицу XLSX

# Задачи потоков

Главный поток отдаёт файлы на обработку субизолятам

Субизолят обработав файл, возвращает конечные данные для формирования таблицы, а так же запрашивает конечное имя файла для копирования

Главный поток даёт имя нового файла и отправляет его запросившему субизоляту

Субизолят получив имя файла занимается его копированием или созданием нового
