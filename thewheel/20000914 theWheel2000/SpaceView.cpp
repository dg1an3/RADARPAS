	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// SpaceView.cpp
//
// Contains the implementation of the CSpaceView class.
//
// Copyright (C) 2000, DG Lane
/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////
// Common pre-compiled header include file
//
/////////////////////////////////////////////////////////////////////////////
#include "stdafx.h"

/////////////////////////////////////////////////////////////////////////////
// Standard C includes
//
/////////////////////////////////////////////////////////////////////////////
#include <math.h>

/////////////////////////////////////////////////////////////////////////////
// Application includes
//
/////////////////////////////////////////////////////////////////////////////
#include "theWheel.h"
#include "SpaceView.h"
#include "Space.h"


/////////////////////////////////////////////////////////////////////////////
// Windows Debug declarations
//
/////////////////////////////////////////////////////////////////////////////
#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif


float SPACER_SIGMA = 50.0;
float SPACER_AMPL = 40.0;

float ATTRACT_SIGMA = 400.0;
float ATTRACT_AMPL = 5.0;

float CENTER_SIGMA = 30.0;
float CENTER_AMPL = 50.0;

#define PI (atan(1.0) * 4.0)

/////////////////////////////////////////////////////////////////////////////
// dSFdX
//
// Computes the value of the X derivative of the spacer field at the given 
//		offset
//
/////////////////////////////////////////////////////////////////////////////
float dSFdX(CPoint ptField) 
{
	float d = (float) (ptField.x * ptField.x) 
		+ (float) (ptField.y * ptField.y);

	return SPACER_AMPL * -2 * (float) ptField.x * exp(-d / (2 * SPACER_SIGMA * SPACER_SIGMA))
			/ (sqrt(2 * PI) * SPACER_SIGMA);
}


/////////////////////////////////////////////////////////////////////////////
// dSFdY
//
// Computes the value of the Y derivative of the spacer field at the given 
//		offset
//
/////////////////////////////////////////////////////////////////////////////
float dSFdY(CPoint ptField) 
{
	float d = (float) (ptField.x * ptField.x) 
		+ (float) (ptField.y * ptField.y);

	return SPACER_AMPL * -2 * (float) ptField.y * exp(-d / (2 * SPACER_SIGMA * SPACER_SIGMA))
			/ (sqrt(2 * PI) * SPACER_SIGMA);
}


/////////////////////////////////////////////////////////////////////////////
// dAFdX
//
// Computes the value of the X derivative of the attraction field at the 
//		given offset
//
/////////////////////////////////////////////////////////////////////////////
float dAFdX(CPoint ptField)
{
	float d = (float) (ptField.x * ptField.x) 
		+ (float) (ptField.y * ptField.y);

	return ATTRACT_AMPL * -2 * (float) ptField.x * exp(-d / (2 * ATTRACT_SIGMA * ATTRACT_SIGMA))
			/ (sqrt(2 * PI) * ATTRACT_SIGMA);
}


/////////////////////////////////////////////////////////////////////////////
// dAFdY
//
// Computes the value of the Y derivative of the attraction field at the 
//		given offset
//
/////////////////////////////////////////////////////////////////////////////
float dAFdY(CPoint ptField)
{
	float d = (float) (ptField.x * ptField.x) 
		+ (float) (ptField.y * ptField.y);

	return ATTRACT_AMPL * -2 * (float) ptField.y * exp(-d / (2 * ATTRACT_SIGMA * ATTRACT_SIGMA))
			/ (sqrt(2 * PI) * ATTRACT_SIGMA);
}


/////////////////////////////////////////////////////////////////////////////
// dCFdX
//
// Computes the value of the X derivative of the centering field at the given 
//		offset
//
/////////////////////////////////////////////////////////////////////////////
float dCFdX(CPoint ptField) 
{
	return 2.0f * ptField.x / 60.0f;
}


/////////////////////////////////////////////////////////////////////////////
// dCFdY
//
// Computes the value of the Y derivative of the centering field at the given 
//		offset
//
/////////////////////////////////////////////////////////////////////////////
float dCFdY(CPoint ptField) 
{
	return 2.0f * ptField.y / 60.0f;
}



/////////////////////////////////////////////////////////////////////////////
// Class CSpaceView Implementation
//
// A class that represent the view of a CSpace object; in particular, the 
// CNodes inside the CSpace object.
//
// Maintains a collection of CNodeViews, one for each displayed node.
//
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::CSpaceView
//
// Constructs an empty CSpaceView object (with no CSpace attached to it)
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A5170343
CSpaceView::CSpaceView()
	: m_pSpace(NULL)
{
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::~CSpaceView
//
// Destroys the CSpaceView object, including all of its child CNodeViews.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A5170339
CSpaceView::~CSpaceView()
{
	int nAtView;
	for (nAtView = 0; nAtView < m_arrNodeViews.size(); nAtView++)
	{
		m_arrNodeViews[nAtView]->DestroyWindow();
		delete m_arrNodeViews[nAtView];
	}
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::GetSpace
//
// Returns the CSpace object which this CSpaceView is currently displaying
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3989B24B03AC
CSpace* CSpaceView::GetSpace()
{
	return m_pSpace;
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::SetSpace
//
// Sets the CSpace object from which CNodes are displayed.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3989B1DD008D
void CSpaceView::SetSpace(CSpace * pSpace)
{
	// delete all the current node views
	int nAtNodeView;
	for (nAtNodeView = 0; nAtNodeView < m_arrNodeViews.size(); 
			nAtNodeView++)
	{
		m_arrNodeViews[nAtNodeView]->DestroyWindow();
		delete m_arrNodeViews[nAtNodeView];
	}

	// clear the child node view array
	m_arrNodeViews.resize(0);

	// set the space
	m_pSpace = pSpace;

	// create new node views
	for (nAtNodeView = 0; nAtNodeView < m_pSpace->GetNodeCount(); 
			nAtNodeView++)
	{
		// compute the initial position for the node view
		int nX = rand() * 500 / RAND_MAX;
		int nY = rand() * 400 / RAND_MAX;

		// construct a new node view for this node
		CNodeView *pNewNodeView = 
			new CNodeView(m_pSpace->GetNode(nAtNodeView));

		// compute the initial rectangle for the node view
		CRect rect(nX - 100, nY - 75, nX + 100, nY + 75);

		// set the style for the node view
		DWORD dwStyle = WS_CHILD | WS_VISIBLE; 

		// create it
		if (pNewNodeView->CreateEx(WS_EX_TRANSPARENT, NULL, NULL, dwStyle, 
				rect, this, nAtNodeView + 1100))
		{
			// and add to the array
			m_arrNodeViews.push_back(pNewNodeView);
		}
	}

	// normalize all node views
	NormalizeAll();

	// now space out all children
	LayoutAll();

	// normalize all node views
	CenterAll();
}


////////////////////////////////////////////////////////////////////////////
// CSpaceView::NormalizeAll
//
// Normalizes the activation of all CNodeViews within this CSpaceView.
//
// Normalization algorithm 
//		Sum activations of all node views 
//		Multiply all activations by a scale factor = 0.65/sum 
//		Set new activations on all node views 
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985F3F10260
void CSpaceView::NormalizeAll()
{
	float sum = 0.0;

	int nAt = 0;
	for (nAt = 0; nAt < m_arrNodeViews.size(); nAt++)
	{
		sum += m_arrNodeViews[nAt]->GetActivation();
	}

	for (nAt = 0; nAt < m_arrNodeViews.size(); nAt++)
	{
		float newActivation = m_arrNodeViews[nAt]->GetActivation() * 0.35 / sum;
		m_arrNodeViews[nAt]->SetActivation(newActivation);
	}
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::LayoutAll
//
// Lays out all of the child CNodeViews, by calling each one's Layout
// member function in turn.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985F6FC017A
void CSpaceView::LayoutAll()
{
	// accumulates the mean center offset, to be returned
	float meanOffset = 0.0f;

	// iterate over all child node views
	int nAtNodeView;
	for (nAtNodeView = 0; nAtNodeView < m_arrNodeViews.size(); 
			nAtNodeView++)
	{
		// get convenience pointers for the current node view and node
		CNodeView *pAtNodeView = m_arrNodeViews[nAtNodeView];
		CNode *pAtNode = pAtNodeView->GetNode();

		// get the center of the current node view.  this will be offset
		//		to space the node view
		CPoint ptInitialCenter;
		CPoint ptCenter = ptInitialCenter = pAtNodeView->GetCenter();

		// iterate over the potential linked views
		int nAtLinkedView;
		for (nAtLinkedView = 0; nAtLinkedView < m_arrNodeViews.size(); 
				nAtLinkedView++)
		{
			// get convenience pointers for the linked node view and node
			CNodeView *pAtLinkedView = m_arrNodeViews[nAtLinkedView];
			CNode *pAtLinkedNode = pAtLinkedView->GetNode();

			// compute the point in the field as the offset from the linked 
			//		view's center to the current node view's center
			CPoint ptField = pAtLinkedView->GetCenter() 
				- pAtNodeView->GetCenter();

			// get the weight of the link
			CNodeLink *pLink = pAtLinkedNode->GetLink(pAtNode);

			// retrieve the link weight
			float weight = 0.5;
			if (pLink != NULL)
				weight = pLink->GetWeight();

			CRect rectLinked;
			pAtLinkedView->GetWindowRect(&rectLinked);
			SPACER_SIGMA = (rectLinked.Width() + rectLinked.Height()) / 4;
			ATTRACT_SIGMA = (rectLinked.Width() + rectLinked.Height()) / 2;

			// compute the "nudge"
			CPoint ptOffset((int)(-dSFdX(ptField) + weight * dAFdX(ptField)),
				(int)(-dSFdY(ptField) + weight * dAFdY(ptField)));

			// now "nudge" the current node view's center a bit based on the
			//		interaction fields and link weight
			ptCenter += ptOffset;
		}


		CPoint ptField = pAtNodeView->GetCenter();

		CRect rectWnd;
		GetWindowRect(&rectWnd);

		ptField -= CPoint(rectWnd.Width() / 2, rectWnd.Height() / 2);
		CPoint ptOffset(dCFdX(ptField), dCFdY(ptField));
		ptCenter += ptOffset;
		
		// now shift the node view so as to space it out
		pAtNodeView->SetCenter(ptCenter);

		// add the distance squared to the mean offset
		ptOffset = ptCenter - ptInitialCenter;
		meanOffset += ptOffset.x * ptOffset.x + ptOffset.y * ptOffset.y;
	}

	// redraw the window for this iteration
	RedrawWindow();

	// finalize calculation of the mean offset
	meanOffset = (float) sqrt(meanOffset) 
		/ (float) m_arrNodeViews.size();

	// recurse if the offset isn't yet small enough
	if (meanOffset > 2.0f)
	{
		LayoutAll();
	}
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::CenterAll
//
// Centering algorithm 
//		Compute vector mean for all node view centers 
//		Offset = mean of centers - center of window 
//		For all node views, SetWindowCenter to the offset + GetWindowCenter 
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A6BB8E007E
void CSpaceView::CenterAll()
{
	CPoint ptMeanCenter(0, 0);	// stores the computed mean center

	// compute the vector sum of all node views' centers
	int nAt = 0;
	for (nAt = 0; nAt < m_arrNodeViews.size(); nAt++)
		ptMeanCenter += m_arrNodeViews[nAt]->GetCenter();

	// divide by number of node views
	ptMeanCenter.x /= m_arrNodeViews.size();
	ptMeanCenter.y /= m_arrNodeViews.size();

	// compute the vector offset for the node views
	//		window center
	CRect rectWnd;
	GetWindowRect(&rectWnd);
	CPoint ptOffset = ptMeanCenter 
		- CPoint(rectWnd.Width() / 2, rectWnd.Height() / 2);

	// offset each node view by the difference between the mean and the 
	//		window center
	for (nAt = 0; nAt < m_arrNodeViews.size(); nAt++)
	{
		CPoint ptNewCenter = 
			m_arrNodeViews[nAt]->GetCenter() + ptOffset;

/*		// make sure it doesn't go out-of-bounds
		ptNewCenter.x = _cpp_max<LONG>(ptNewCenter.x, 0);
		ptNewCenter.x = _cpp_min<LONG>(ptNewCenter.x, 100);
		ptNewCenter.y = _cpp_max<LONG>(ptNewCenter.y, 0);
		ptNewCenter.y = _cpp_min<LONG>(ptNewCenter.y, 100);
*/
		m_arrNodeViews[nAt]->SetCenter(ptNewCenter);
	}
}


/////////////////////////////////////////////////////////////////////////////
// CSpaceView::AddNodeToSpace
//
// Adds the new node to the Space, using the current activation states of
// the currently displayed nodes as the links weights
//
// Adding New Node 
//		Set initial link weights = activation values for displayed node views 
//		Normalize link weights 
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A6BB8E0056
void CSpaceView::AddNodeToSpace(CNode *pNewNode)
{
}

/////////////////////////////////////////////////////////////////////////////
// CSpaceView::PreCreateWindow
//
// Sets certain window styles for the CSpaceView.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A5170340
BOOL CSpaceView::PreCreateWindow(CREATESTRUCT& cs) 
{
	if (!CWnd::PreCreateWindow(cs))
		return FALSE;

	cs.dwExStyle |= WS_EX_CLIENTEDGE;
	cs.style &= ~WS_BORDER;
	cs.lpszClass = AfxRegisterWndClass(CS_HREDRAW|CS_VREDRAW|CS_DBLCLKS, 
		::LoadCursor(NULL, IDC_ARROW), HBRUSH(COLOR_WINDOW+1), NULL);

	return TRUE;
}


/////////////////////////////////////////////////////////////////////////////
// IMPLEMENT_DYNCREATE Macro
//
// Allows run-time construction of CSpaceView objects
//
/////////////////////////////////////////////////////////////////////////////
IMPLEMENT_DYNCREATE(CSpaceView, CWnd)


/////////////////////////////////////////////////////////////////////////////
// CSpaceView Message Map
//
/////////////////////////////////////////////////////////////////////////////
BEGIN_MESSAGE_MAP(CSpaceView, CWnd)
	//{{AFX_MSG_MAP(CSpaceView)
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CSpaceView message handlers
//
/////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// CSpaceView::OnPaint
//
// Handles a WM_PAINT message -- used to draw links between the child 
//	CNodeViews.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A5170337
void CSpaceView::OnPaint() 
{
	CPaintDC dc(this); // device context for painting
	
	// TODO: Add your message handler code here
	
	// Do not call CWnd::OnPaint() for painting messages
}


