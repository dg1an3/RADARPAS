// wlSignal.cpp  Copyright (C) 1997  DG Lane

#include "stdafx.h"
#include <math.h>
#include "wlSignal.h"

int wlSignal::maxSamples = 200;
int wlSignal::kernelTap  = 5;

wlSignal::wlSignal() {
	t0 = 0;
	rate = 1;	// msec/sample
	s = new float[maxSamples];
	memset(s, 0, sizeof(s));
	numSamples = 0;
}

wlSignal::wlSignal(wlSignal *parent) {
	t0 = parent->t0;
	rate = parent->rate;
	s = new float[maxSamples];
	memcpy(s, parent->s, sizeof(s));
	numSamples = parent->numSamples;
}

wlSignal::~wlSignal() { 
	delete [] s;
}

void wlSignal::addSample(float value) {
	t0 += rate;
	memmove(&s[1], &s[0], sizeof(s) - sizeof(s[0]));
	s[0] = value;
    numSamples++;
}

void wlSignal::decimate() {
	for (int atSample = 1; atSample*2 < maxSamples; atSample++)
		s[atSample] = s[atSample*2];
	rate *= 2;
	numSamples = maxSamples/2;
}

void wlSignal::convolve(float *kernel) {
	wlSignal *oldSignal = new wlSignal(this);
	memset(s, 0, sizeof(s));
	for (int atSample = kernelTap/2; atSample < maxSamples - kernelTap/2; atSample++) {
		float sum = 0.0;
		for (int count = -kernelTap/2; count <= kernelTap/2; count++)
			sum += oldSignal->s[atSample + count] * kernel[count + kernelTap];
		s[count] = sum;
	}
	delete oldSignal;
}

