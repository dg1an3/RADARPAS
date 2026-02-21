#include <afxwin.h>
#include "resource.h"

#include "trio.h"

/////////////////////////////////////////////////////////////////////////////

// theApp:
// Just creating this application object runs the whole application.
//
TrioApp theApp;

/////////////////////////////////////////////////////////////////////////////

// TrioWindow constructor:
// Create the window with the appropriate style, size, menu, etc.
//
TrioWindow::TrioWindow()
{
	LoadAccelTable( "MainAccelTable" );
	Create( NULL, "Trio Application",
		WS_OVERLAPPEDWINDOW, rectDefault, NULL, "MainMenu" );
}

// OnPaint:
// This routine draws the string "Hello, Windows!" in the center of the
// client area.  It is called whenever Windows sends a WM_PAINT message.
// Note that creating a CPaintDC automatically does a BeginPaint and
// an EndPaint call is done when it is destroyed at the end of this
// function.  CPaintDC's constructor needs the window (this).
//
void TrioWindow::OnPaint()
{
	CString s = "WELCOME TO TRIO!";
	CString s2 = "Not much here, yet!";
	CPaintDC dc( this );
	CRect rect;

	GetClientRect( rect );
	dc.SetTextAlign( TA_BASELINE | TA_CENTER );
	dc.SetTextColor( ::GetSysColor( COLOR_WINDOWTEXT ) );
	dc.SetBkMode(TRANSPARENT);
	dc.TextOut( ( rect.right / 2 ), ( rect.bottom / 3 ),
				s, s.GetLength() );
	dc.TextOut( ( rect.right / 2 ), ( rect.bottom / 3 * 2 ),
				s2, s2.GetLength() );
}

// OnAbout:
// This member function is called when a WM_COMMAND message with an
// IDM_ABOUT code is received by the TrioWindow class object.  The
// message map below is responsible for this routing.
//
// We create a CModalDialog object using the "AboutBox" resource (see
// hello.rc), and invoke it.
//
void TrioWindow::OnAbout()
{
	CModalDialog about( "AboutBox", this );
	about.DoModal();
}

// TrioWindow message map:
// Associate messages with member functions.
//
// It is implied that the ON_WM_PAINT macro expects a member function
// "void OnPaint()".
//
// It is implied that members connected with the ON_COMMAND macro
// receive no arguments and are void of return type, e.g., "void OnAbout()".
//
BEGIN_MESSAGE_MAP( TrioWindow, CFrameWnd )
	ON_WM_PAINT()
	ON_COMMAND( IDM_ABOUT, OnAbout )
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// TrioApp

// InitInstance:
// When any TrioApp object is created, this member function is automatically
// called.  Any data may be set up at this point.
//
// Also, the main window of the application should be created and shown here.
// Return TRUE if the initialization is successful.
//
BOOL TrioApp::InitInstance()
{
	m_pMainWnd = new TrioWindow();
	m_pMainWnd->ShowWindow( m_nCmdShow );
	m_pMainWnd->UpdateWindow();

	return TRUE;
}
