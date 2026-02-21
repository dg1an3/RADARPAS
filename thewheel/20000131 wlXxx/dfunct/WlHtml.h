// WlHtml.h  Copyright (C) 1996 DG Lane

#ifndef _WLHTML_H_
#define _WLHTML_H_

#include "WlDoc.h"

class WlHtml : public WlDoc {
public:
	WlHtml() { }
	virtual ~WlHtml() { }
	DECLARE_SERIAL(Html);

	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void SkipSpace(CString raw, int *at);
	int NextHtmlField(CString raw, int *at);
	void Process();

#ifdef _DEBUG
	void AssertValid() const;
	void Dump(CDumpContext& dc) const;
#endif //_DEBUG

	// Member variables
	CString title, body;
};	// WlHtml

#endif
