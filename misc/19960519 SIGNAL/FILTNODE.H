// filtnode.h (C) 1996 DG Lane

#ifndef __FILTNODE_H__
#define __FILTNODE_H__

#include "signal.h"

class FilterNode {    // one node of filter bank tree
public:
// Constructors
    FilterNode();
    FilterNode(FilterNode *fromNode);	// copy constructor
    ~FilterNode();
    
// Member manipulation
    void setMatch(int mFlag = 1) { match = mFlag; }
    void setInput(Signal *input);
    Signal *getInput() { return in; }
    void setFilter(Signal *f);
    Signal *getFilter() { return filter; }
    Signal *getOutput();
    REAL getLambda(int at) { return lambda->getAt(at); }
    FilterNode *getNext() { return next; }
    void setNext(FilterNode *n);
	
// Input/Output
    void printStats();

// Operations
    void update();	// update the filter bank
    REAL expSum();    // helper function for sweep
    void sweep();    // implements Gibbs sweeper
    REAL updateLambda(FilterNode *exemp);    // updates lamdba for FRAME
    	// returns maximum histogram difference
    void alignHist(FilterNode *withBank, int numBins);
    void setHistBins(int numBins);
        // takes care of the lambda

private:
    int match;    // indicates whether sweep should match this filter
    Signal *in, *filter, *out, *lambda;
    FilterNode *next, *lap;
};  // class FilterNode

#endif

