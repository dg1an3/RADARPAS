// wlPyram.cpp  Copyright (C) 1997  DG Lane

#include "stdafx.h"
#include <math.h>
#include "wlPyram.h"

typedef wlSignal *wlSignalPtr;

wlPyramid::wlPyramid(wlSignal *fromSig, int levels) {
	l = levels;
	g = new wlSignalPtr[l];
	dg = new wlSignalPtr[l];
	ddg = new wlSignalPtr[l];
	g[0] = fromSig;
	initKernels();
}

wlPyramid::~wlPyramid() {
	delete [] g;
	delete [] dg;
	delete [] ddg;
}

wlSignal *wlPyramid::original() {
	return g[0];
}

void wlPyramid::update() {
	for (int level = 1; level < l; level++) {
		if (g[level])
			delete g[level];
		g[level] = new wlSignal(g[level-1]);
		g[level]->convolve(gKernel);
		g[level]->decimate();
		dg[level] = new wlSignal(g[level]);
		dg[level]->convolve(dgKernel);
		ddg[level] = new wlSignal(g[level]);
		ddg[level]->convolve(ddgKernel);
	}
}

int    wlPyramid::kernelTap = 7;
float *wlPyramid::gKernel = NULL;
float *wlPyramid::dgKernel = NULL;
float *wlPyramid::ddgKernel = NULL;

#define pi             (4.0*atan(1.0))
#define sqrt2pi        sqrt(2.0*pi)
#define normGauss(t)   exp(-(t)*(t)/2.0) / \
						    sqrt2pi
#define dnormGauss(t)  -(t)*exp(-(t)*(t)/2) / \
							 sqrt2pi
#define ddnormGauss(t) ((t)*(t)-sqrt2pi)*exp(-(t)*(t)/2) / \
                               (2.0*pi)

void wlPyramid::initKernels() {
	if (!gKernel) {
		gKernel = new float[kernelTap];
		dgKernel = new float[kernelTap];
		ddgKernel = new float[kernelTap];
		for (int count = 0; count <= kernelTap; count++) {
			gKernel[count-kernelTap/2] = (float)normGauss((double)count);
			dgKernel[count-kernelTap/2] = (float)dnormGauss((double)count);
			ddgKernel[count-kernelTap/2] = (float)ddnormGauss((double)count);
		}
	}
}
