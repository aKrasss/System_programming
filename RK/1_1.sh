#!/bin/bash
# Раздел 1, задача 1
# Выполнять в каталоге sandbox, где лежат файлы Task_1, Task_2, Task_3.

# Объём файлов в Кб
du -k Task_1 Task_2 Task_3

# Переименование файлов
mv Task_1 Task_first
mv Task_2 Task_second
mv Task_3 Task_third

# Дописать содержимое Task_first в конец Task_third
cat Task_first >> Task_third
