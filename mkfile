
%.o: %.asm
	nasm -f elf64 $stem.asm

%: %.o
	ld -o $stem $stem.o
