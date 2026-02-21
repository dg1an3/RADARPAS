// TextView.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include "Orbis.h"
#include "OrbDoc.h"
#include "TextView.h"
                    
#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNCREATE(TextView, ItemView)

BOOL TextView::Draw(CDC* pDC, LPCRECT lpBounds, 
		LPCRECT lpWBound, CDC *pFormatDC) {
	if (client->data == "") {
		TRACE("Drawing NULL data\n");
		return FALSE;
	}	// if
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
	pDC->DrawText(client->data, client->data.GetLength(), backRect,
		DT_LEFT | DT_WORDBREAK);
	pDC->SelectObject(oldFont);
	pDC->SetBkMode(oldBkMode);
	pDC->SetBkColor(oldColor);
	delete newFont;
	return TRUE;
}	// TextView::Draw

#ifdef _DEBUG
void TextView::AssertValid() const {
}	// TextView::AssertValid

void TextView::Dump(CDumpContext& dc) const {
} 	// TextView::Dump
#endif //_DEBUG



