#!/bin/bash
# Раздел 1, задача 3
# Выполнять в каталоге sandbox, где лежат файлы Task_1, Task_2, Task_3.

# Архив MyArch.tar с файлами Task_1, Task_2, Task_3
tar -cf MyArch.tar Task_1 Task_2 Task_3

# Сжатие архива утилитой gzip -> MyArch.tar.gz
gzip MyArch.tar

# Содержимое каталога sandbox (команда ls) -> в файл List
ls > List

# Добавление List в архив.
# В сжатый архив tar дописывать не умеет, поэтому: распаковать gzip, дописать, сжать снова
gzip -d MyArch.tar.gz
tar -rf MyArch.tar List
gzip MyArch.tar
