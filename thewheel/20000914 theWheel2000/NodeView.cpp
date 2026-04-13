	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// NodeView.cpp
//
// Contains the implementation of the CNodeView class.
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
// Standard C/C++ includes
//
/////////////////////////////////////////////////////////////////////////////
#include <math.h>

/////////////////////////////////////////////////////////////////////////////
// Application includes
//
/////////////////////////////////////////////////////////////////////////////
#include "Node.h"
#include "NodeView.h"
#include "SpaceView.h"


/////////////////////////////////////////////////////////////////////////////
// Windows Debug declarations
//
/////////////////////////////////////////////////////////////////////////////
#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif



/////////////////////////////////////////////////////////////////////////////
// Class CNodeView Implementation
//
// A class that represent the view of an individual CNode object
//
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// CNodeView::CNodeView
//
// Constructs a new node view for the node passed in as a parameter.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=398F34AE01C5
CNodeView::CNodeView(CNode * pNode)
	: m_pNode(pNode),
		m_activation(0.1f)
{
}


/////////////////////////////////////////////////////////////////////////////
// CNodeView::GetCenter
//
// Returns the center (in Parent coordinates) of this node view
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A6C1990155
CPoint CNodeView::GetCenter()
{
	// retrieve the window rectangle
	CRect rectWnd;
	GetWindowRect(&rectWnd);

	// get the parent window and transform to its coordinates
	CSpaceView *pSpaceView = (CSpaceView *)GetParent();
	pSpaceView->ScreenToClient(&rectWnd);

	// compute and return the center of the rectangle
	return CPoint(rectWnd.left + rectWnd.Width() / 2, 
		rectWnd.top + rectWnd.Height() / 2);
}


/////////////////////////////////////////////////////////////////////////////
// CNodeView::SetCenter
//
// Sets the center (in Parent coordinates) of this node view while keeping
// its size constant.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39A6C1A20071
void CNodeView::SetCenter(CPoint ptCenter)
{
	// compute the offset
	CPoint ptOffset = GetCenter() - ptCenter;

	// retrieve the window rectangle
	CRect rectWnd;
	GetWindowRect(&rectWnd);

	// get the parent window and transform to its coordinates
	CSpaceView *pSpaceView = (CSpaceView *)GetParent();
	pSpaceView->ScreenToClient(&rectWnd);

	// offset the rectangle
	rectWnd += ptOffset;

	// now move the window
	MoveWindow(rectWnd);
}


/////////////////////////////////////////////////////////////////////////////
// CNodeView::GetActivation
// 
// Returns the current activation value of this CNodeView.
// Activations = fraction of total available window area that this child 
//		will occupy. 
// Total activations for all node views = 0.65 
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39B6C8D1017E
float CNodeView::GetActivation()
{
	return m_activation;
}


/////////////////////////////////////////////////////////////////////////////
// CNodeView::SetActivation
//
// Sets the desired activation value for this CNodeView by changing its
// height and width.
//
// Setting an activation 
//		Desired area = available window area * new activation 
//		Aspect ratio = width/height, so height * aspect ratio = width 
//		Area = height * height * aspect radio = aspect ratio * height ^ 2, so 
//			height = sqrt(area / aspect ratio) 
//		SetWindowWidthHeight - sets width and height while keeping center of window stationary 
//
// Propagation Algorithm 
//		Increase target activation by delta source activation * link weight 
//		Normalize all 
//
// Learning Alorithm 
//		delta link weight = delta * ((Aa * Ab) / (Aa + Ab)) - (Aa + Ab)/8 
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985EEE0020B
void CNodeView::SetActivation(float activation)
{
	// set the activation member variable
	m_activation = activation;

	CRect rect;
	GetWindowRect(&rect);

	CSpaceView *pParent = (CSpaceView *)GetParent();
	CRect rectParent;
	pParent->GetWindowRect(&rectParent);

	// compute the area interpreting activation as the fraction of the 
	//		parent's total area
	float area = GetActivation() * (rectParent.Width() * rectParent.Height());

	// compute the desired aspect ratio (maintain the current aspect ratio)
	float aspectRatio = 0.75f - 0.375f * exp(-8.0f * GetActivation());
		// (float) rect.Height() / (float) rect.Width();

	// compute the new width and height from the desired area and the desired
	//		aspect ratio
	int nWidth = (int) sqrt(area / aspectRatio);
	int nHeight = (int) sqrt(area * aspectRatio);

	// set the width and height of the window, keeping the center constant
	CPoint ptCenter = GetCenter();
	rect.left = ptCenter.x - nWidth / 2;
	rect.right = ptCenter.x + nWidth / 2;
	rect.top = ptCenter.y - nHeight / 2;
	rect.bottom = ptCenter.y + nHeight / 2;

	// and move the window
	MoveWindow(&rect);

	// TODO: propagation algorithm

	// TODO: learning algorithm
}


/////////////////////////////////////////////////////////////////////////////
// CNodeView Message Map
//
/////////////////////////////////////////////////////////////////////////////
BEGIN_MESSAGE_MAP(CNodeView, CWnd)
	//{{AFX_MSG_MAP(CNodeView)
	ON_WM_LBUTTONUP()
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()


/////////////////////////////////////////////////////////////////////////////
// CNodeView message handlers
//
/////////////////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////////////////
// CNodeView::OnLButtonUp
//
// Processes a mouse click by increasing the activation of this node view.
//
// Click-Activation 
//		SetActivation - increase activation threefold 
//			Propagation Algorithm (in SetActivation)
//			Learning Algorithm (in SetActivation)
//		Normalization Algorithm
//		Spacing Algorithm 
//		Centering Algorithm 
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=39B6C8D10034
void CNodeView::OnLButtonUp(UINT nFlags, CPoint point) 
{
	// compute the new activation
	float newActivation = min(0.8f, GetActivation() * 2);
	SetActivation(newActivation);

	// now normalize all children
	CSpaceView *pParent = (CSpaceView *)GetParent();
	pParent->NormalizeAll();

	// now space out all children
	pParent->LayoutAll();

	// now center all children
	pParent->CenterAll();

	// redraw the parent
	pParent->RedrawWindow();

	// propagate to base class
	CWnd::OnLButtonUp(nFlags, point);
}


/////////////////////////////////////////////////////////////////////////////
// CNodeView::OnPaint
//
// Draws the node view
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3991A39F006C
void CNodeView::OnPaint() 
{
	CPaintDC dc(this); // device context for painting

	// compute the rectangle for the text
	CRect rectOut;
	GetClientRect(&rectOut);

	CRect rectIn = rectOut;
	float r = 1.0f - (1.0f - 1.0f / sqrt(2.0f)) * exp(-8.0f * GetActivation());
	// r = 1.0f / sqrt(2.0f);

	rectIn.top = (float) (rectOut.top + rectOut.Height() / 2) - r * (float) rectOut.Height() / 2.0f;
	rectIn.bottom = (float) (rectOut.top + rectOut.Height() / 2) + r * (float) rectOut.Height() / 2.0f;
	rectIn.left = (float) (rectOut.left + rectOut.Width() / 2) - r * (float) rectOut.Width() / 2.0f;
	rectIn.right = (float) (rectOut.left + rectOut.Width() / 2) + r * (float) rectOut.Width() / 2.0f;

	// rectIn.DeflateRect(12, 12, 11, 11);

	CPen penNull(PS_NULL, 0, RGB(0, 0, 0));
	CPen *pOldPen = dc.SelectObject(&penNull);
	dc.Rectangle(rectIn);

	// compute the ellipse's b
	float rx = ((float) rectIn.Width())
			/ ((float) rectOut.Width()); 
	float bx = sqrt((float) (rectIn.Height() * rectIn.Height()) * 0.25f
			/ (1.0f - rx * rx));

	CRect rectSides = rectOut;
	rectSides.top = (rectOut.top + rectOut.Height() / 2) - bx;
	rectSides.bottom = (rectOut.top + rectOut.Height() / 2) + bx;

	dc.Chord(&rectSides, rectIn.TopLeft(), CPoint(rectIn.left, rectIn.bottom));
	dc.Chord(&rectSides, rectIn.BottomRight(), CPoint(rectIn.right, rectIn.top));

	// compute the ellipse's b
	float ry = ((float) rectIn.Height())
			/ ((float) rectOut.Height()); 
	float by = sqrt((float) (rectIn.Width() * rectIn.Width()) * 0.25f
			/ (1.0f - ry * ry));

	CRect rectCaps = rectOut;
	rectCaps.left = (rectOut.left + rectOut.Width() / 2) - by;
	rectCaps.right = (rectOut.left + rectOut.Width() / 2) + by;

	dc.Chord(&rectCaps, CPoint(rectIn.right, rectIn.top), rectIn.TopLeft());
	dc.Chord(&rectCaps, CPoint(rectIn.left, rectIn.bottom), rectIn.BottomRight());

	dc.SelectObject(pOldPen);

	dc.Arc(&rectSides, rectIn.TopLeft(), CPoint(rectIn.left, rectIn.bottom));
	dc.Arc(&rectSides, rectIn.BottomRight(), CPoint(rectIn.right, rectIn.top));

	dc.Arc(&rectCaps, CPoint(rectIn.right, rectIn.top), rectIn.TopLeft());
	dc.Arc(&rectCaps, CPoint(rectIn.left, rectIn.bottom), rectIn.BottomRight());

	// draw the ellipse containing the text
	// dc.Ellipse(rect);

	// draw the text
	dc.DrawText(GetNode()->GetName(), rectIn, 
		DT_CENTER | DT_SINGLELINE | DT_VCENTER);

	// Do not call CWnd::OnPaint() for painting messages
}
