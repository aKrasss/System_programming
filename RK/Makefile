# Сборка всех задач (разделы 2 и 3): make
# Сборка одной задачи: make 2_1
PROGS = 2_1 2_2 2_3 2_4 2_5 3_1 3_2 3_3 3_4 3_5

all: $(PROGS)

%: %.asm func.asm
	fasm $< $@.o
	ld $@.o -o $@

clear:
	rm -f $(PROGS) *.o
