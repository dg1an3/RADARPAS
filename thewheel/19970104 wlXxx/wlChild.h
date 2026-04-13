// wlChild.h  Copyright (C) 1996  DG Lane

#ifndef _wlChild_h_
#define _wlChild_h_

class wlChild :
	public CMDIChildWnd
{
	public:
		wlChild();
	   ~wlChild();
		void PostNcDestroy();

		DECLARE_DYNCREATE(wlChild);

		BOOL Draw(CDC* pDC, LPCRECT lpBounds,         
    			LPCRECT lpWBound = NULL, 
    			CDC *pFormatDC = NULL);
                                                         
		void SetSize(int dx, int dy);

	public:
		double		activation;
		// wlSpring	sizeSpring;                    
		UINT		sizeTimer;

		//{{AFX_MSG(wlChild)
		afx_msg LONG OnUpdateSize(UINT nFlags, LONG lParam);
		afx_msg void OnTimer(UINT nIDEvent);
		afx_msg void OnMouseMove(UINT nFlags, CPoint point);
		afx_msg void OnPaint();
		//}}AFX_MSG
   
		DECLARE_MESSAGE_MAP()	                                       
};
                                               
// user interface messages
#define WM_UPDATESIZE (WM_USER + 101)

#endif
