pendu: pendu.o
	ld pendu.o -o pendu

pendu.o: pendu.asm
	nasm -f elf64 pendu.asm -o pendu.o

run: pendu
	./pendu

clean:
	rm -f pendu pendu.o
