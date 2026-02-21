// filtnode.cpp (C) 1996 DG Lane

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include "misc.h"

#include "filtnode.h"

FilterNode::FilterNode() {
    match = 0;
    in = (Signal *)NULL;
    filter = (Signal *)NULL;
    out = (Signal *)NULL;
    lambda = (Signal *)NULL;
    next = (FilterNode *)NULL;
}	// FilterNode::FilterNode

FilterNode::FilterNode(FilterNode *fromNode) {
	in = new Signal(fromNode->in);
	filter = new Signal(fromNode->filter);
	out = (Signal *)NULL; // new Signal(fromNode->out);
	lambda = (Signal *)NULL; 
	match = fromNode->match;
	if (fromNode->next != NULL)
		next = new FilterNode(fromNode->next);
	else
		next = (FilterNode *)NULL;
}   // FilterNode::FilterNode

FilterNode::~FilterNode() {
    if (in != NULL) delete in;
    if (filter != NULL) delete filter;
    if (out != NULL) delete out;
    if (lambda != NULL) delete lambda;
    if (next != NULL) delete next;
}	// FilterNode::~FilterNode

void FilterNode::setInput(Signal *input) { 
	in = input; 
}

void FilterNode::setFilter(Signal *f) { 
	filter = f; 
}

Signal *FilterNode::getOutput() {
	if (out == NULL)
		update();
	return out;
}

void FilterNode::setNext(FilterNode *n) {
	next = n; 
}

void FilterNode::printStats() {
    printf("===============================\n");
    printf("Input : ");
    getInput()->printStats();
    FilterNode *atFilt = this;
    while (atFilt != NULL) {
        if (atFilt->out != NULL) {
            printf("Output: ");
            atFilt->getOutput()->printStats();
        }   // if
        if (atFilt->lambda != NULL) {
            printf("Lambda: ");
            for (int i = 0; i < atFilt->getOutput()->getHist()->getNumBins(); i++)
                printf("%4.2Lf ", atFilt->lambda->getAt(i));
            printf("\n");
        }   // if
        atFilt = atFilt->getNext();
    }   // while
    printf("===============================\n");	
}   // FilterNode::printStats

void FilterNode::update() {
    ASSERT(in != NULL);
    if (out == NULL)
        out = new Signal();
    in->filter(filter, out);
    ASSERT(out != NULL);
    if (next != NULL) {
    	next->in = out;
        ASSERT(next->in != NULL);
    	next->update();
    }
}   // FilterNode::update

#define ZETA 1024.0

REAL FilterNode::updateLambda(FilterNode *exemp) {
    ASSERT(this != NULL);
    ASSERT(out != NULL);
    ASSERT(exemp->out != NULL);
    if (getOutput()->getHist()->getNumBins() != 
        exemp->getOutput()->getHist()->getNumBins())
	printf("Synth #bins = %i; exemp #bins = %i",
            getOutput()->getHist()->getNumBins(),
            exemp->getOutput()->getHist()->getNumBins());
    ASSERT(out->getHist()->getNumBins() == 
        exemp->out->getHist()->getNumBins());
    REAL histDiff = 0.0;
    if (match) {
        if (lambda == NULL)
            lambda = new Signal();
        int i;
        for (i = getOutput()->getHist()->getNumBins()-1; i >= 0; i--) {
       	    histDiff += FABS(getOutput()->getHist()->getAt(i) - 
       	    	exemp->getOutput()->getHist()->getAt(i));
            lambda->setAt(i, lambda->getAt(i) + 
                ZETA*(getOutput()->getHist()->getAt(i) - 
                exemp->getOutput()->getHist()->getAt(i)));
        }
        REAL nextHistDiff = 0.0;
        if (next != NULL) 
            nextHistDiff = next->updateLambda(exemp->next);
        histDiff = MAX(nextHistDiff, histDiff);
    }
    return histDiff;
}   // FilterNode::updateLambda

REAL FilterNode::expSum() {
    REAL e = 0.0;
    for (int i = 0; i < out->getHist()->getNumBins(); i++)
        e += lambda->getAt(i) * out->getHist()->getAt(i);
    if (next != NULL)
    	e += next->expSum();
    return e;
}	// FilterNode::expSum

void FilterNode::sweep() {
    int min = 0; // (int)getInput()->getMin();
    int pSize = 16; // (int)getInput()->getMax() - min + 1;
    REAL *p = new REAL[pSize];
    REAL maxp;
    for (int count = 0; count < getInput()->getNumSamples(); count++) {
    	int atx = (int)RAND_RANGE(getInput()->getWidth());
    	int aty = (int)RAND_RANGE(getInput()->getHeight());
        printf("at: (%i,%i)  \r", atx, aty); fflush(stdout);
        // ASSERT(atx >= 0);
        // ASSERT(at < getInput()->getNumSamples());
        maxp = 0.0;
        for (int v = 0; v < pSize; v++) {
            getInput()->setAt(atx, aty, (REAL)(v));
            update();
            p[v] = EXP(-0.1*expSum());
            if (p[v] > LDBL_MAX) {
               printf("%i: p[v] is inf! p[%i] = %Lf; expSum = %Lf\n", __LINE__, v, p[v], expSum());
               p[v] = LDBL_MAX/16.0;
            }
            if (p[v] != p[v])
                printf("%i: p[v] is NaN! p[%i] = %Lf; expSum = %Lf\n", __LINE__, v, p[v], expSum());
            maxp += p[v];
        }
        if (maxp == 0.0) maxp = 1e-10;
        for (v = 0; v < pSize; v++) {
	        p[v] /= maxp;
            if (p[v] != p[v])
                 printf("%i: p[%i] is NaN! maxp = %Lf\n", __LINE__, v, maxp);
        }
        maxp = 0.0;
        for (v = 0; v < pSize; v++) 
            maxp += p[v];
        if (maxp != maxp) {
            printf("maxp is not a number! maxp = %Lf\n", maxp);
            for (v = 0; v < 16; v++)
                printf("p[%i] = %Lf\t", v, p[v]);
            maxp = 0.0;
        }
        REAL x = RAND_RANGE(maxp);
        if (x != x) {   // flag NAN 
            printf("X is not a number! x = %Lf\nmaxp = %Lf\n", x);
            x = 0.0;
        }
        if ((x >= 0.0) && (x <= maxp)) {
            v = -1;
            while (x >= 0.0) {
                ASSERT(v <= pSize);
                x -= p[++v];
	        }
            getInput()->setAt(atx, aty, (REAL)v);
            update();
        } else 
            printf("x = %Lf\nmaxp = %Lf\n", x);
    }
    delete [] p;
}   // FilterNode::sweep

void FilterNode::alignHist(FilterNode *withBank, int numBins) {
    REAL hmin, hmax;
    Histogram *thisHist = getInput()->getHist();
    Histogram *thatHist = withBank->getInput()->getHist();
    hmin = MIN(thisHist->getMinBin(), thatHist->getMinBin());
    hmax = MAX(thisHist->getMaxBin(), thatHist->getMaxBin());
    thisHist->setMinMax(hmin, hmax);
    thisHist->setNumBins(numBins);
    thatHist->setMinMax(hmin, hmax);
    thatHist->setNumBins(numBins);
    getInput()->setAt(0, getInput()->getAt(0));    // trigger dirtyHist
    withBank->getInput()->setAt(0, withBank->getInput()->getAt(0));

    thisHist = getOutput()->getHist();
    thatHist = withBank->getOutput()->getHist();
    hmin = MIN(thisHist->getMinBin(), thatHist->getMinBin());
    hmax = MAX(thisHist->getMaxBin(), thatHist->getMaxBin());
    thisHist->setMinMax(hmin, hmax);
    thisHist->setNumBins(numBins);
    thatHist->setMinMax(hmin, hmax);
    thatHist->setNumBins(numBins);

    if (next != NULL) {
        ASSERT(withBank->next != NULL);
        next->alignHist(withBank->next, numBins);
    }
}   // FilterNode::alignHist

void FilterNode::setHistBins(int numBins) {
    getInput()->getHist()->setNumBins(numBins);
    getInput()->setAt(0, getInput()->getAt(0));
    getOutput()->getHist()->setNumBins(numBins);
    getOutput()->setAt(0, getOutput()->getAt(0));
    if (lambda != NULL) {
        Signal *newLam = new Signal();
        for (int i = numBins-1; i >= 0; i--)
            newLam->setAt(i, lambda->getAt(i*lambda->getNumSamples()/numBins));
        delete lambda;
        lambda = newLam;
    }
    if (getNext() != NULL)
        getNext()->setHistBins(numBins);
}










