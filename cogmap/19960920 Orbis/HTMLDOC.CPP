// HtmlDoc.cpp	Copyright (C) 1996 DG Lane
 
#include "stdafx.h"
#include "Orbis.h"
#include "HtmlDoc.h"
#include "TextView.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_SERIAL(HtmlDoc, ItemView, 1)

void HtmlDoc::SkipSpace(CString raw, int *pat) {
	while ((raw[*pat] == ' ') || (raw[*pat] =='\t') ||
			(raw[*pat] == '\n') || (raw[*pat] == '\r'))
		(*pat)++;
}	// HtmlDoc::SkipSpace

int HtmlDoc::NextHtmlField(CString raw, int *pat) {
	SkipSpace(raw, pat);
	if (raw[*pat] == '<')	// labeled field
		return raw.Mid(*pat).Find('>');
	else	// text field
		return raw.Mid(*pat).Find('<');	// TODO: handle <<
}	// HtmlDoc::NextHtmlField

void HtmlDoc::Process() {
	int at = 0;
	int len;
	body = "";
	while (at < data.GetLength()) {
		len = NextHtmlField(data, &at);
		if ((data.Mid(at, 6) == "<title") || (data.Mid(at, 6) == "<TITLE")) {
			at += len;
			len = NextHtmlField(data, &at);
			title = data.Mid(at, len);
		} else if (data[at] != '<') {	// body
			body += data.Mid(at, len);
		}	// if
		at += len;
	}	// while
}	// HtmlDoc::Parse

BOOL HtmlDoc::Draw(CDC* pDC, LPCRECT lpBounds,
		LPCRECT lpWBound, CDC *pFormatDC) {
	if (data == "") {
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
	// if (title != "");
	//	pDC->DrawText(title, title.GetLength(), backRect, DT_CENTER | DT_WORDBREAK);
	pDC->DrawText(data, data.GetLength(), backRect,
		DT_LEFT | DT_WORDBREAK);
	pDC->SelectObject(oldFont);
	pDC->SetBkMode(oldBkMode);
	pDC->SetBkColor(oldColor);
	delete newFont;
	return TRUE;
}	// HtmlDoc::Draw

#ifdef _DEBUG
void HtmlDoc::AssertValid() const {
}	// HtmlDoc::AssertValid

void HtmlDoc::Dump(CDumpContext& dc) const {
}	// HtmlDoc::Dump
#endif //_DEBUG
