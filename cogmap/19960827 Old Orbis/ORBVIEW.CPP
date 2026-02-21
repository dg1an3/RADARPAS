// OrbView.cpp  Copyright (C) 1996  DG Lane

#include "stdafx.h"
#include "Orbis.h"
#include <math.h>

#include "OrbDoc.h"
#include "OrbView.h"
#include "OrbVwItm.h"

#include "TextItem.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

IMPLEMENT_DYNCREATE(OrbView, CView)

BEGIN_MESSAGE_MAP(OrbView, CView)
	//{{AFX_MSG_MAP(OrbView)
	ON_COMMAND(ID_OLE_INSERT_NEW, OnInsertObject)
	ON_COMMAND(ID_VIEW_FONT, OnViewFont)
	ON_COMMAND(ID_INSERT_WORD, OnInsertWord)
	ON_WM_TIMER()
	ON_WM_DESTROY()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

OrbView::OrbView() { 
}	// OrbView::OrbView

OrbView::~OrbView() { 
}	// OrbView::~OrbView

// OrbView drawing

void OrbView::OnDraw(CDC* pDC) { }   // OrbView::OnDraw

void OrbView::OnInitialUpdate() {
	// OrbDoc *pDoc = GetDocument();
	// POSITION pos = pDoc->GetStartPosition();
	// while (pos != NULL) {
    	//	OrbItem *nextItem = (OrbItem *)pDoc->GetNextItem(pos);
    	//	OrbViewItem *newItemView = new OrbViewItem(this, nextItem,
    	//		(int)((long int)rand()*200/RAND_MAX + 200),
    	//		(int)((long int)rand()*100/RAND_MAX + 100),
    	//		220);	// initial activation
    	//	iteml.AddTail(newItemView);
	// }	// while
	// currPos = NULL;
	// SetTimer(timerID, 10, NULL);
}	// OrbView::

void OrbView::OnUpdate(CView *pSender, LPARAM lHint, CObject *pHint) {
	// call UpdateSizePos for all children
	/*
	int Etot = 0;
	for (POSITION pos = iteml.GetHeadPosition(); pos != NULL;) {
		OrbViewItem *child = (OrbViewItem *)iteml.GetNext(pos);
		Etot += child->UpdateSizePos();
	}	// while
	*/
	// Invalidate(FALSE);
	// UpdateWindow();
	// CView::OnUpdate(pSender, lHint, pHint);
}	// OrbView::OnUpdate 

// OrbView printing

BOOL OrbView::OnPreparePrinting(CPrintInfo* pInfo) {
	// default preparation
	return DoPreparePrinting(pInfo);
}	// OrbView::OnPreparePrinting

void OrbView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add extra initialization before printing
}	// OrbView::OnBeginPrinting

void OrbView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) {
	// TODO: add cleanup after printing
}	// OrbView::OnEndPrinting

// OLE Client support and commands

BOOL OrbView::IsSelected(const CObject* pDocItem) const {
	// TODO: implement this function that tests for a selected OLE client item
	return FALSE;
}	// OrbView::IsSelected

void OrbView::OnInsertObject() {
	CString strTypeName;
	if (!AfxOleInsertDialog(strTypeName))
		return;		// no OLE class selected
	TRACE("Trying to Insert OLE item with type '%s'\n",
			(const char*)strTypeName);
	// TODO: create an embedded OLE object with that class name
	char szT[300];
	wsprintf(szT, "TODO: this function is not completely implemented.\n"
		"You must add code to create a COleClientItem\n"
		" with a type name of '%s'.\n"
		"See OrbView::OnInsertObject in"
			" COGMAVW.CPP for more info.", (LPCSTR)strTypeName);
	AfxMessageBox(szT);
}	// OrbView::OnInsertObject


// OrbView diagnostics

#ifdef _DEBUG
void OrbView::AssertValid() const {
	CView::AssertValid();
}	// OrbView::AssertValid

void OrbView::Dump(CDumpContext& dc) const {
	CView::Dump(dc);
}	// OrbView::Dump

OrbDoc* OrbView::GetDocument() { // non-debug version is inline
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(OrbDoc)));
	return (OrbDoc*) m_pDocument;
}	// OrbView::GetDocument
#endif //_DEBUG


// OrbView message handlers

void OrbView::OnDestroy() {
	CWnd *child; // **** use iteml instead
	while ((child = GetTopWindow()) != NULL) {
		child->DestroyWindow();
		delete child;
	}	// while
	CView::OnDestroy();
}	// OrbView::OnDestroy

void OrbView::OnViewFont() {
	LOGFONT lf;
	CHOOSEFONT cf;
	// Set all structure fields to zero.
	memset(&cf, 0, sizeof(CHOOSEFONT));
	cf.lStructSize = sizeof(CHOOSEFONT);
	cf.hwndOwner = GetSafeHwnd();
	cf.lpLogFont = &lf;
	cf.Flags = CF_SCREENFONTS | CF_EFFECTS;
	cf.rgbColors = RGB(0, 255, 255); /* light blue */
	cf.nFontType = SCREEN_FONTTYPE;

	ChooseFont(&cf);

	// OrbDoc *pDoc = (OrbDoc *)GetDocument();
	if (txtFont != NULL)
		delete txtFont;
	txtFont = new CFont();
	txtFont->CreateFontIndirect(cf.lpLogFont);
}	// OrbView::OnViewFont

void OrbView::OnInsertWord() {
/*	EditTextDlg wDlg;
	if (wDlg.DoModal() == IDOK) {
		TextItem *newWord = new TextItem(wDlg.value);
		OrbDoc *pDoc = (OrbDoc *)GetDocument();
		pDoc->AddItem(newWord);
	}	// if
*/
}	// OrbView::OnInsertWord

void OrbView::OnTimer(UINT nIDEvent){
      	TRACE("Timer tick!\n");
      	if (currPos == NULL)
      		currPos = iteml.GetHeadPosition();
	OrbViewItem *atItem = (OrbViewItem *)iteml.GetNext(currPos);
	atItem->UpdateSizePos();
	atItem->UpdateWindow();
	// CView::OnTimer(nIDEvent);
}	// OrbView::OnTimer

