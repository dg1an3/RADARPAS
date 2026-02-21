// TextView.h  Copyright (C) 1996 DG Lane

#ifndef TextView_h
#define TextView_h

#include "Resource.h"
#include "ItemView.h"

class TextView : public ItemView {
public:
	TextView() { }
	virtual ~TextView() { }
	DECLARE_DYNCREATE(TextView);

	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);

#ifdef _DEBUG
	void AssertValid() const;
	void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class TextView

#endif
