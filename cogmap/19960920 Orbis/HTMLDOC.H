// HtmlDoc.h  Copyright (C) 1996 DG Lane

#ifndef _HTMLDOC_H_
#define _HTMLDOC_H_

#include "OrbItem.h"

class HtmlDoc : public OrbItem {
public:
	HtmlDoc() { }
	virtual ~HtmlDoc() { }
	DECLARE_SERIAL(HtmlDoc);

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
};	// class HtmlDoc

#endif
