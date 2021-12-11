SRC = src/
BIN = bin/
CC = ./p3as-linux
RUN = java -jar p3sim.jar

all: game run

game:
	$(CC) $(SRC)space_invaders.as
	mv $(SRC)space_invaders.exe $(BIN)
	mv $(SRC)space_invaders.lis $(BIN)

run:
	$(RUN) $(BIN)space_invaders.exe

clean:
	rm -f $(BIN)*.lis
	rm -f $(BIN)*.exe
