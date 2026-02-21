// HtmlItem.h  Copyright (C) 1996 DG Lane

#ifndef __HTMLITEM_H__
#define __HTMLITEM_H__

#include "Resource.h"
#include "OrbItem.h"

class HtmlItem : public OrbItem {
public:
	HtmlItem();
	virtual ~HtmlItem();
	DECLARE_SERIAL(HtmlItem)
	
	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void Serialize(CArchive& ar);
#ifdef _DEBUG
	void AssertValid() const;
	void Dump(CDumpContext& dc) const;
#endif //_DEBUG

	CString title;
	CString body;
};	// class HtmlItem

#endif // __HtmlItem_H__
