// wlFrameView.cpp  Copyright (C) 1996, 97 DG Lane

#include "stdafx.h"
#include "theWheel.h"
#include "wlFrameV.h"

#ifdef _DEBUG
#undef THIS_FILE
static char BASED_CODE THIS_FILE[] = __FILE__;
#endif

wlFrameView::wlFrameView() : CMDIFrameWnd() {
    	for (int count = 0; count < numChildren; count++)
    			child[count] = (wlChildView *)NULL;
		totArea = 0;
}

IMPLEMENT_DYNAMIC(wlFrameView, CMDIFrameWnd)

void wlFrameView::setChild( wlChildView *newChild ) {
		int count = 0;
		while (child[count] && (++count < numChildren));
		if (count < numChildren)
				child[count] = newChild;
}

wlFrameView::~wlFrameView() {
		for (int count = 0; count < numChildren; count++)
				if (child[count])
						delete child[count];
}

#ifdef _DEBUG
void wlFrameView::AssertValid() const {
		for (int count = 0; count < numChildren; count++)
				child[count]->AssertValid();
		ASSERT(totArea >= 0.0);				
		CMDIFrameWnd::AssertValid();
}

void wlFrameView::Dump(CDumpContext& dc) const{
		for (int count = 0; count < numChildren; count++)
				child[count]->Dump(dc);
		dc << totArea;
		CMDIFrameWnd::Dump(dc);
}
#endif //_DEBUG

BEGIN_MESSAGE_MAP(wlFrameView, CMDIFrameWnd)
	//{{AFX_MSG_MAP(wlFrameView)
	ON_WM_CREATE()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

int wlFrameView::OnCreate( LPCREATESTRUCT lpCreateStruct ) {
	    int result;    
		if (CMDIFrameWnd::OnCreate(lpCreateStruct) == -1)
				result = -1;
		return result;
}
