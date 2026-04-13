// TextItem.h  Copyright (C) 1996 DG Lane

#ifndef __TEXTITEM_H__
#define __TEXTITEM_H__

#include "Resource.h"
#include "OrbItem.h"

class TextItem : public OrbItem {
public:
	TextItem();
	virtual ~TextItem() { }
	
	DECLARE_SERIAL(TextItem)

	// virtual void Update();	// does nothing if state = complete	
	BOOL Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound = NULL, CDC *pFormatDC = NULL);
	void Serialize(CArchive& ar);
	
#ifdef _DEBUG
	void AssertValid() const;
	void Dump(CDumpContext& dc) const;
#endif //_DEBUG
};	// class TextItem

#endif
