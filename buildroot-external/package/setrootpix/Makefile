CC = gcc

CFLAGS = -Wall -Wextra -O2 -pipe

all: setrootpix

setrootpix: setrootpix.o
	$(CC) -o setrootpix setrootpix.o -lX11
    
.c.o:
	$(CC) -c $(CFLAGS) $<

setrootpix.o: setrootpix.c
