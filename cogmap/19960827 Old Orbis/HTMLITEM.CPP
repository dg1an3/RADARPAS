// HtmlItem.cpp
                                      
#include "stdafx.h"                                     
#include "HtmlItem.h"
#include "TextItem.h"

IMPLEMENT_SERIAL(HtmlItem, OrbItem, 1);

HtmlItem::HtmlItem() {
}	// HtmlItem::HtmlItem

HtmlItem::~HtmlItem() { 
}	// HtmlItem::~HtmlItem
	
BOOL HtmlItem::Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound, CDC *pFormatDC) {
	((TextItem *)this)->Draw(pDC, lpBounds, lpWBound, pFormatDC);
	return TRUE;
}	// HtmlItem::Draw

void HtmlItem::Serialize(CArchive& ar) {
}	// HtmlItem::Serialize

#ifdef _DEBUG
void HtmlItem::AssertValid() const {
}	// HtmlItem::AssertValid

void HtmlItem::Dump(CDumpContext& dc) const {
}	// HtmlItem::Dump
#endif //_DEBUG
