#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NUM_STATES 50
#define NUM_SYMBOLS 2
#define TAPE_LENGTH 1024

#define TRUE 1
#define FALSE 0

#define assert(x) if (!(x)) exit(-7);

enum OpCode {L, R, H};

char *symbol[NUM_SYMBOLS] = {"0", "1"};

typedef struct _StateRec {
		int writeSymbol;
		OpCode op;
		int nextState;
} StateRec;

class TuringMachine {
	public:
		TuringMachine();
		TuringMachine(TuringMachine& parent, int mutate = FALSE);
	   ~TuringMachine();

    	char  getSymbol(int *at);
    	char  setSymbol(int *at, char symbol);		
    	char *tapeString();

    	int   step();
    	
	public:
		StateRec stateTable[NUM_STATES][NUM_SYMBOLS];
		char *inTape;
		int   inLen;
		
		char *tape;
		int   len,  pos,  state;
		
		long steps;
		
		TuringMachine *parent;
};

TuringMachine::TuringMachine() {
	inTape = tape = (char *)NULL;
	inLen  = len  = pos  = state = 0;
}

TuringMachine::TuringMachine(TuringMachine& parent, int mutate) {
	inLen = parent.inLen;
	inTape = new char[inLen];
	memcpy(inTape, parent.inTape, inLen);
	memcpy(stateTable, parent.stateTable, sizeof(stateTable));
	if (mutate) {
		if (rand() % 2) {	// mutate the code
			// choose a state
			// choose a symbol
			// choose a field -- writeSymbol, op, nextState
			
		} else {			// mutate the data
			// choose a position
			// flip the symbol at that position
		}
	}
	tape = (char *)NULL;
	len = pos = state = 0;
}

TuringMachine::~TuringMachine() {
	if (inTape) delete inTape;
	if (tape)   delete tape;
}

char TuringMachine::getSymbol(int *at) {
	while (*at < 0) {
		char *newTape = new char[len + 1];
		newTape[0] = '\0';
		memcpy(newTape + 1, tape, len);    len++;
		if (tape) delete tape;             pos++;
		tape = newTape;	   				   (*at)++;
	}	
	while (*at >= len) {
		char *newTape = new char[len + 1];
		memcpy(newTape, tape, len);
		newTape[len] = '\0';               len++;
		if (tape) delete tape;
		tape = newTape;
	}                              return tape[*at]; 
}

char TuringMachine::setSymbol(int *at, char symbol) {
	getSymbol(at);
	tape[*at] = symbol;            return symbol; 
}

char *TuringMachine::tapeString() {
	char *buffer = new char[len + 1];
	for (int count = 0; count < len; count++)
		buffer[count] = (tape[count] == '\0' ? '0' : '1');
	buffer[count] = '\0';          return buffer;
}

int TuringMachine::step() {
	char currChar = getSymbol(&pos);
	assert(state >= 0 && state < NUM_STATES);
	StateEntry currState = &stateTable[state][currChar];
	setSymbol(&pos, currState->writeSymbol);
	switch (currState->op) {
		case L : pos--; break;
		case R : pos++; break;
		case H :                   return FALSE;
		default : break;
	}
	state = currState->nextState;  return TRUE;
}

char initTape[] = {1, 1, 1};

StateEntryRec stateTable[][NUM_SYMBOLS] = {
	{ {1, R, 1}, {0, R, 0} },
	{ {0, R, 2}, {1, R, 1} },
	{ {0, R, 3}, {1, R, 3} },
	{ {0, H, 4}, {1, R, 4} }
};

void main(int argc, char **argv) {	
	printf("Derek's New Turing Machine Simulator!\n");
	
	TuringMachine *T = new TuringMachine();
	for (int count = 0; count < sizeof(initTape); count++)
		T->setSymbol(&count, initTape[count]);
	printf("Ts initial tape: %s\n", T->tapeString());
	
	memcpy(T->stateTable, stateTable, sizeof(stateTable));
	while (T->step());
	
	printf("Ts final   tape: %s\n", T->tapeString());
}