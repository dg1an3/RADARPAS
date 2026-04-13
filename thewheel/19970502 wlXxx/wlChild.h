// wlChildView.h  Copyright (C) 1996, 97 DG Lane

#ifndef _wlChildView_h_
#define _wlChildView_h_

#include "wlObject.h"

class wlChild : public CMDIChildWnd {
public:
		wlObject *myObject;
		CPoint myPosition;
		double myArea;

public:
		wlChildView();

		DECLARE_DYNCREATE(wlChildView);

		BOOL Draw(CDC* pDC, LPCRECT lpBounds,         
   				LPCRECT lpWBound = NULL, 
	   			CDC *pFormatDC = NULL);

		void updatePos();                                                         
		void updateSize(CPoint mouseAt);

		//{{AFX_MSG(wlChildView)
		afx_msg void OnPaint();
		//}}AFX_MSG
		DECLARE_MESSAGE_MAP()	                                       

		void PostNcDestroy();
   		virtual ~wlChildView();
};
                                               
#endif
