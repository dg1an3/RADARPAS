// signal.h (C) 1996 DG Lane

#ifndef __SIGNAL_H__
#define __SIGNAL_H__

#include <stdio.h>

#define DEFAULT_BINS 4

class Histogram;

class Signal {
public:
// Initialization
    Signal();
    Signal(Signal *fromSig);	// copy constructor
    ~Signal();
 
    void whiteNoise(int xSize, int ySize, REAL max);
		// initialize with white noise

// Member manipulation
    void setAt(int x, int y, REAL val);
    void setAt(int at, REAL val) { setAt(at, 0, val); }
    REAL getAt(int x, int y);
    REAL getAt(int at) { return getAt(at, 0); }

    int getWidth() { return width; }
    int getHeight() { return height; }
    int getNumSamples() { return getWidth()*getHeight(); }

// Statistics
    Histogram *getHist();
    REAL getMin();
    REAL getMax();

// Input/Output	
    void printStats(FILE *toFile = stdout);
    void printData(FILE *toFile = stdout);

// Operations
	REAL innrProd(Signal *withSig, int xOfs, int yOfs);
    void filter(Signal *withSig, Signal *output);

private:
    // int numSamples;
    int width, height;
    REAL *data;    
    Histogram *hist;
    int dirtyHist;	// marks for update
};  // class Signal

class Histogram : public Signal {
public:
// Initialization
    Histogram();
    ~Histogram() { }

// Member manipulation
    REAL getMinBin() { return minBin; }
    REAL getMaxBin() { return maxBin; }
    void setMinMax(REAL mn, REAL mx);
    int getNumBins() { return numBins; }
    void setNumBins(int n);
    int inBin(REAL val);

// Operations
    void update(Signal *forSig);

private:
    REAL minBin, maxBin;
    int numBins;
};	// class Histogram

#endif




