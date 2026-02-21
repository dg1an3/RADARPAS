/////////////////////////////////////
// signal.cpp (C) 1996 DG Lane

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include "misc.h"

#include "signal.h"

/////////////////////////////////////
// class Signal

Signal::Signal() {
    width = 0;
    height = 0;
    data = (REAL *)NULL;
    hist = (Histogram *)NULL;
    dirtyHist = 1;
}   // Signal::Signal() 

Signal::Signal(Signal *fromSig) {
    if (fromSig != NULL) {
        width = fromSig->getWidth();
        height = fromSig->getHeight();
        if (data != NULL) {
        	data = new REAL[width*height];
        	memcpy(data, fromSig->data, sizeof(REAL)*width*height);
        }
    } else {
        width = 0;
        height = 0;
        data = (REAL *)NULL;
    }
    hist = (Histogram *)NULL;
    dirtyHist = 1;
}   // Signal::Signal(Signal *fromSig)

Signal::~Signal() {
    if (data != NULL) 
        delete [] data;
    if (hist != NULL)
        delete hist;
}   // Signal::~Signal()

void Signal::whiteNoise(int xSize, int ySize, REAL max) {
    for (int aty = ySize-1; aty >= 0; aty--)
    	for (int atx = xSize-1; atx >= 0; atx--) {
            int v = (int)RAND_RANGE(max);
            setAt(atx, aty, v);
        }
}   // Signal::whiteNoise

void Signal::setAt(int x, int y, REAL val) {
    // int at;
    if ((x >= width) || (y >= height)) {
        REAL *newData = new REAL[(x+1)*(y+1)];
        memset(newData, 0, sizeof(REAL)*(x+1)*(y+1));
        if (data != NULL) {
            memcpy(newData, data, sizeof(REAL)*height*width);
            delete [] data;
        }
        data = newData; 
        width = x+1;
        height = y+1;
    }
    data[y*width + x] = val;
    dirtyHist = 1;
}	// Signal::setAt
                         
REAL Signal::getAt(int x, int y) {
	if (data == NULL)
		return 0;
    while (x < 0) x += width;	// circulant boundaries
    x %= width;
    while (y < 0) y += height;
    y %= height;
    return data[y*width + x];
}   // Signal::getAt

REAL Signal::getMin() {
    if (data == NULL)
        return 0;
    REAL m = getAt(0,0);
    for (int atx = 0; atx < getWidth(); atx++)
    	for (int aty = 0; aty < getHeight(); aty++)
        	m = MIN(getAt(atx, aty), m);
    return m;
}   // Signal::getMin

REAL Signal::getMax() {
    if (data == NULL)
        return 0;
    REAL m = getAt(0,0);
    for (int atx = 0; atx < getWidth(); atx++)
    	for (int aty = 0; aty < getHeight(); aty++)
        	m = MAX(getAt(atx, aty), m);
    return m;
}   // Signal::getMax

Histogram *Signal::getHist() {
    if (hist == NULL) {
        hist = new Histogram();
        hist->setMinMax(getMin(), getMax());
        dirtyHist = 1;
    }
    if (dirtyHist) {
        hist->update(this);
        dirtyHist = 0;
    }
    return hist;
}	// Signal::getHist

void Signal::printStats(FILE *toFile) {
    fprintf(toFile, "Size = (%i w x %i h) ", getWidth(), getHeight());
    fprintf(toFile, "Min = %4.2Lf  Max = %4.2Lf\nHist: ", getMin(), getMax());
    for (int i = 0; i < getHist()->getNumBins(); i++)
        fprintf(toFile, "%4.2Lf ", getHist()->getAt(i, 0));
    fprintf(toFile, "\n");
    fflush(toFile);
}   // Signal::printStats

void Signal::printData(FILE *toFile) {
    printf("\n");
    for (int aty = 0; aty < getHeight(); aty++) {
    	for (int atx = 0; atx < getWidth(); atx++)
	        fprintf(toFile, "%3i ", (int)getAt(atx, aty));
    	fprintf(toFile, "\n");
    }
    fflush(toFile);
}	// Signal::printData

REAL Signal::innrProd(Signal *withSig, int xOfs, int yOfs) {
	REAL sum = 0.0;
	for (int atx = 0; atx < withSig->getWidth(); atx++)
		for (int aty = 0; aty < withSig->getHeight(); aty++)
			sum += getAt(atx+xOfs, aty+yOfs) * withSig->getAt(atx, aty);
	return sum;
}	// Signal::inProd

void Signal::filter(Signal *withSig, Signal *output) {
    for (int atx = getWidth()-1; atx >= 0; atx--)
    	for (int aty = getHeight()-1; aty >= 0; aty--)
			output->setAt(atx, aty, innrProd(withSig, atx, aty));
}   // Signal::filter
                  
                  
/////////////////////////////////////
// class Histogram

Histogram::Histogram() :
        Signal() {
    setMinMax(0.0, 0.0);
    setNumBins(DEFAULT_BINS);
    setAt(DEFAULT_BINS-1, 0.0);
}   // Histogram::Histogram

int Histogram::inBin(REAL val) {
    if (maxBin == minBin)
        return 0;
    else if (val < minBin)
        return 0;
    else if (val > maxBin)
        return numBins-1;
    else {
        int temp = (int)((REAL)numBins*(val-minBin)/
            (maxBin-minBin) - 0.02);
        ASSERT((temp >= 0) && (temp < numBins));
        return temp;
    }   // if
}   // Histogram::inBin

void Histogram::setMinMax(REAL mn, REAL mx) {
    minBin = mn;
    maxBin = mx;
}   // Histogram::setMinMax

void Histogram::setNumBins(int n) {
    numBins = n;
}   // Histogram::setNumBins

void Histogram::update(Signal *forSig) {
    for (int at = 0; at < numBins; at++)
        setAt(at, 0.0);
    for (int atx = 0; atx < forSig->getWidth(); atx++)
    	for (int aty = 0; aty < forSig->getHeight(); aty++) {
            int b = inBin(forSig->getAt(atx, aty));
            setAt(b, getAt(b) + 1.0);
        }
    for (at = 0; at < numBins; at++)	// normalize
        setAt(at, getAt(at) / (REAL)forSig->getNumSamples());
}   // Histogram::update

















































