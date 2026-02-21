// wlImage.h  Copyright (C) 1997  DG Lane

#ifndef _wlImage_h_
#define _wlImage_h_

#include "wlObject.h"

class wlImage : public wlObject {
		CBitmap data;
		CDC *context;

	public:
		wlImage(int bitPlanes, int height, int width);
		~wlImage();
		
		void setPixel(int atX, int atY, long value);
		long getPixel(int atX, int atY);
		
		void convolve(wlImage *kernel);
		void Draw(CDC *pDC, CPoint at);
		void Stretch(CDC *pDC, CRect intoRect);
};

#endif