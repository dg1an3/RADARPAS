// OrbFrame.h  Copyright (C) 1996  DG Lane

#ifndef OrbFrame_h
#define OrbFrame_h

class OrbFrame : public CMDIFrameWnd {
public:
	OrbFrame();
	virtual ~OrbFrame();
	DECLARE_DYNAMIC(OrbFrame);
	
	BOOL OnCommand(UINT wParam, LONG lParam);

	OrbDoc *map;		// The map associated with the frame
	CObList children;		// List of MDIChildWnd (ItemView-derived)
	CStatusBar m_wndStatusBar;		// Control bar embedded objects
	CToolBar m_wndToolBar;

	//{{AFX_MSG(OrbFrame)
	afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct);
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP();
	
#ifdef _DEBUG
	virtual	void AssertValid() const;
	virtual	void Dump(CDumpContext& dc) const;
#endif
};	// class OrbFrame

#endif
