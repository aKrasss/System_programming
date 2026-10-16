#!/bin/bash
# Раздел 1, задача 4
# Выполнять в каталоге sandbox, где лежат файлы Task_1, Task_2, Task_3.

# Жёсткая ссылка на Task_1
ln Task_1 Task_1_hard

# Символическая ссылка на Task_2
ln -s Task_2 Task_2_sym

# Подробный отчёт о содержимом текущего каталога -> в файл Task_3
ls -la > Task_3
