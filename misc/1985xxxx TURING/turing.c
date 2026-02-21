#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NUM_STATES 50
#define NUM_SYMBOLS 2
#define TAPE_LENGTH 1024

char *symbol[NUM_SYMBOLS] = {"0", "1"};

enum Direction {Left, Right, Halt};

struct StateEntry
{
	int writeSym;
	enum Direction move;
	int nextState;
};

void compute(struct StateEntry *stateTable, int initState, 
		char *tape, int initPos)
{
	int currState = initState;
	int currPos = initPos;
	struct StateEntry *currEntry;
	do {
		currEntry = &stateTable[currState*NUM_SYMBOLS + tape[currPos]];
		tape[currPos] = currEntry->writeSym;
		switch (currEntry->move) {
		case Left :
			currPos--;
			if (currPos < 0) exit(-1);
			/* check for end of tape */
			break;
		case Right :
			currPos++;
			if (currPos >= TAPE_LENGTH) exit(-1);
			break;
		case Halt : 
		default :
			break;
		}
		currState = currEntry->nextState;
	} while (currEntry->move != Halt);
}

struct StateEntry stateTable[] =
{
	{1, Halt, 0}, {0, Right, 0}
};

void
main(int argc, char **argv)
{	
	char tape[TAPE_LENGTH];
	char buffer[TAPE_LENGTH];
	int count;
	
	memset(tape, 0, sizeof(tape));	/* initialize: all zeros */
	tape[0] = 1;
	tape[1] = 1;
	tape[2] = 1;
	
	printf("Derek's New Turing Machine Simulator!\n");
	for (count = TAPE_LENGTH-1; !tape[count] && (count >= 0); count--);
	buffer[0] = '\0';
	for (; count >= 0; count--)
		strcat(buffer, symbol[tape[count]]);
	printf("   Input tape: %s\n", buffer);
	
	compute(stateTable, 0, tape, 0);
	
	for (count = TAPE_LENGTH-1; !tape[count] && (count >= 0); count--);
	buffer[0] = '\0';
	for (; count >= 0; count--)
		strcat(buffer, symbol[tape[count]]);
	printf("   Output tape: %s\n", buffer);
}