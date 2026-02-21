// synth.cpp (C) 1996 DG Lane

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include "misc.h"

#include "signal.h"
#include "filtnode.h"

// Be sure NOE linker option is used for the matherr handler to be called
/* 
int _matherrl( struct _exceptionl *except ) {
    if( except->type == _DOMAIN ) {
        if( strcmp( except->name, "log" ) == 0 ) {
            except->retval = logl( -(except->arg1) );
            printf( "Special: using absolute value: %s: _DOMAIN error\n", except->name );
            return 1;
        } else if( strcmp( except->name, "log10" ) == 0 ) {
            except->retval = log10l( -(except->arg1) );
            printf( "Special: using absolute value: %s: _DOMAIN error\n", except->name );
            return 1;
        }
    } else if (except->type == _OVERFLOW ) {
        printf( "Special: using retval: %s: _OVERFLOW error\n", except->name );
        return 1;
    }
    printf( "Normal: " );
    return 0; 
}
*/

#define EPSILON 0.12

void main() {
    printf("Synth (C) 1996 DG Lane\n");
    srand(948);	
    printf("Constructing texture exemplar...");
    FilterNode *exemp = new FilterNode();    // exemplar filter bank

    Signal *input = new Signal;
    for (int i = 7; i >= 0; i -= 4)
    	for (int j = 7; j >= 0; j -= 4)
        	input->setAt(i, j, 15.0);
    exemp->setInput(input);

    Signal *filter = new Signal();
    filter->setAt(0, 0, 1.0);    // impulse filter
    exemp->setFilter(filter);
    exemp->setMatch();
    
    filter = new Signal();
    for (i = 3; i >= 0; i--)
    	for (int j = 3; j >= 0; j--)
        	filter->setAt(i, j, 1.0);    // rectangular filter
    FilterNode *next = new FilterNode();
    next->setFilter(filter);
    next->setMatch();
    exemp->setNext(next);

    exemp->update();
    printf("done.\n");
    
    printf("Constructing new texture...");
    FilterNode *synth = new FilterNode(exemp);    
        // duplicate exemplar filter bank
    input = new Signal();
    input->whiteNoise(8, 8, 15.0);
    synth->setInput(input);
    synth->update();
    printf("done.\n");

// Now ensure that the histograms are properly aligned
    int numBins = 4;
    synth->alignHist(exemp, numBins);
    exemp->update();
    synth->update();

    exemp->printStats();
    exemp->getOutput()->printData();
    exemp->getNext()->getOutput()->printData();
	
    REAL maxHistDiff = 0.0;
    maxHistDiff = synth->updateLambda(exemp);
    synth->printStats();
    synth->getOutput()->printData();
    synth->getNext()->getOutput()->printData();
    REAL epsilon = EPSILON;
    do {
        do {
            for (int i = 0; i < 1; i++) {
                synth->sweep();
                synth->printStats();
                synth->getOutput()->printData();
                synth->getNext()->getOutput()->printData();
            }
            maxHistDiff = synth->updateLambda(exemp);
            printf("Max Hist Diff: %4.2Lf\n", maxHistDiff);
        } while (maxHistDiff > epsilon);
        numBins *= 2;
        epsilon /= 2;
        printf("Setting number of bins to %i\n", numBins);
        synth->setHistBins(numBins);
        exemp->setHistBins(numBins);
        printf("Exemplar:\n");
        exemp->printStats();
        maxHistDiff = synth->updateLambda(exemp);
    } while (numBins < 32);
    printf(  "Exemplar: ");
    exemp->getInput()->printData();
    printf("\nSynth   : ");
    synth->getInput()->printData();
}   // main
