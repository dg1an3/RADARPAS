// TextItem.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include "Orbis.h"
#include "OrbDoc.h"
#include "TextItem.h"
                    
#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_SERIAL(TextItem, OrbItem, 1)

TextItem::TextItem() {
}

BOOL TextItem::Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound, CDC *pFormatDC) {
	// Update();
	// if ((state != rxing) || (state != complete))
	//	return FALSE;
	int oldBkMode = pDC->SetBkMode(OPAQUE);
	CFont *newFont = new CFont();	ASSERT(newFont != NULL);
	newFont->CreateFont(-13, 0, // -size/10, 0,	// Height, Width
		0, 0, FW_BOLD, // Escapement, Orientation, Weight (700)
		0, 0, 0, // Italic, Underline, Strikeout
		ANSI_CHARSET, OUT_STROKE_PRECIS,  // CharSet, OutPrecision
		CLIP_STROKE_PRECIS, DRAFT_QUALITY,  // ClipPrecision, Quality
		18,	// PitchAndFamily
		CString("Times New Roman"));	// FaceName 
	COLORREF bkColor = RGB(192, 192, 176);
	COLORREF oldColor = pDC->SetBkColor(bkColor);
	CBrush *rectBrush = new CBrush(RGB(224,224,208));
	CRect backRect = *lpBounds;
	pDC->FrameRect(backRect, rectBrush);
	delete rectBrush;
	backRect.InflateRect(-1, -1);
	rectBrush = new CBrush(RGB(160,160,144));
	pDC->FrameRect(backRect, rectBrush);
	delete rectBrush;
	backRect.InflateRect(-1, -1);
	rectBrush = new CBrush(bkColor);
	pDC->FillRect(backRect, rectBrush);
	delete rectBrush;
	pDC->SetTextAlign(TA_LEFT);
	CFont *oldFont = pDC->SelectObject(newFont);
	// pDC->ExtTextOut((int)wx, (int)wy, ETO_OPAQUE, bkRect, word, word.GetLength(), NULL);
	backRect.InflateRect(-2, -2);
	pDC->DrawText(data, data.GetLength(), backRect,
		DT_LEFT | DT_WORDBREAK);
	pDC->SelectObject(oldFont);
	pDC->SetBkMode(oldBkMode);
	pDC->SetBkColor(oldColor);
	delete newFont;
	return TRUE;
}	// TextItem::Draw

void TextItem::Serialize(CArchive& ar) { 
	OrbItem::Serialize(ar);
	if (ar.IsStoring())
		ar << url;
	else
		ar >> url;
}	// TextItem::Serialize

#ifdef _DEBUG
void TextItem::AssertValid() const {
}	// TextItem::AssertValid

void TextItem::Dump(CDumpContext& dc) const { 
	dc << url;
} 	// TextItem::Dump
#endif //_DEBUG



