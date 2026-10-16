#!/bin/bash
# Раздел 1, задача 2
# Выполнять в каталоге sandbox, где лежат файлы Task_1, Task_2, Task_3.

# Список всех процессов -> в файл Task_1
ps aux > Task_1

# Каталог sandbox-2, перемещение туда Task_2 и Task_3
mkdir sandbox-2
mv Task_2 Task_3 sandbox-2

# Содержимое /bin/ls -> в Task_2, переименование в myls, права r-xr--r--
cat /bin/ls > sandbox-2/Task_2
mv sandbox-2/Task_2 sandbox-2/myls
chmod 544 sandbox-2/myls

# Информация о ядре системы -> в конец Task_3
uname -a >> sandbox-2/Task_3
