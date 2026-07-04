\# Сборка ядра ОС «Родник» 6.8



\## Устройства



| Устройство | Процессор | GPU |

|-----------|-----------|-----|

| ASUS NUC 14 Pro | Core Ultra 5 125H | Meteor Lake (Xe) |

| Huawei MateBook D16 | i5-13420H | Raptor Lake |

| ASUS Vivobook Slate 13 | N6000 | Jasper Lake |

| DEPO Storm 3400 | Xeon E-2400 | Нет |



\## Быстрая сборка (WSL)



```bash

cd /mnt/c/Projects/linux

bash rodnik/scripts/generate-configs.sh

bash rodnik/scripts/build-all.sh

Результаты

Ядра в rodnik/output/:



bzImage-asus-nuc14



bzImage-matebook-d16



bzImage-vivobook-slate13



bzImage-depo-storm3400



Размер каждого < 15 МБ.

