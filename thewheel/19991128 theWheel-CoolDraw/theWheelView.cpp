// theWheelView.cpp : implementation of the theWheelView class
//

#include "stdafx.h"
#include "theWheel.h"

#include <cmath>

#include "theWheelDoc.h"
#include "theWheelView.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// theWheelView

IMPLEMENT_DYNCREATE(theWheelView, CView)

BEGIN_MESSAGE_MAP(theWheelView, CView)
	//{{AFX_MSG_MAP(theWheelView)
	ON_WM_SIZE()
	ON_WM_PAINT()
	ON_WM_MOUSEMOVE()
	//}}AFX_MSG_MAP
	// Standard printing commands
	ON_COMMAND(ID_FILE_PRINT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_DIRECT, CView::OnFilePrint)
	ON_COMMAND(ID_FILE_PRINT_PREVIEW, CView::OnFilePrintPreview)
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// theWheelView construction/destruction

theWheelView::theWheelView()
	: m_aspectRatio(0.75)
{
	m_arrNodes.push_back(CRect(200, 100, 300, 175));
	m_arrNodes.push_back(CRect(300, 150, 400, 225));
	m_arrNodes.push_back(CRect(200, 300, 300, 375));
}

theWheelView::~theWheelView()
{
}

BOOL theWheelView::PreCreateWindow(CREATESTRUCT& cs)
{
	HCURSOR hCursor = LoadCursor(AfxGetInstanceHandle(), MAKEINTRESOURCE(IDC_CURSOR2));
	LPCTSTR lpszTheWheelViewClass = AfxRegisterWndClass(CS_HREDRAW | CS_VREDRAW,
		hCursor);

	cs.lpszClass = lpszTheWheelViewClass;

	return CView::PreCreateWindow(cs);
}

/////////////////////////////////////////////////////////////////////////////
// theWheelView drawing

#define COLOR_BACK RGB(92, 92, 92)
#define COLOR_NODE_FILL RGB(192, 192, 192)
#define COLOR_NODE_BORDER_OUTER RGB(0, 0, 0)
#define COLOR_NODE_BORDER_INNER_UPPER RGB(255, 255, 255)
#define COLOR_NODE_BORDER_INNER_LOWER RGB(128, 128, 128)

void theWheelView::OnPaint() 
{
	theWheelDoc* pDoc = GetDocument();
	ASSERT_VALID(pDoc);

	CRect rectUpdate;
	GetUpdateRect(&rectUpdate);

	m_memDC.FillSolidRect(&rectUpdate, COLOR_BACK);

	for (int nAt = 0; nAt < m_arrNodes.size(); nAt++)
	{
		CBrush brush(COLOR_NODE_FILL);
		CBrush *pBrushOld = m_memDC.SelectObject(&brush);
		CPen penOuter(PS_SOLID, 1, COLOR_NODE_BORDER_OUTER);
		CPen *pPenOld = m_memDC.SelectObject(&penOuter);

/*		m_memDC.Ellipse(m_arrNodes[nAt]);
		m_memDC.SelectObject(pPenOld);
		m_memDC.SelectObject(pBrushOld);
		penOuter.DeleteObject();
		brush.DeleteObject(); */

		CRect rectVert(m_arrNodes[nAt]);
		double height = rectVert.Height();
		height = height * height * height * height / 2000000.0;
		rectVert.InflateRect(0, height);
		{
			CPoint ptArcStart(m_arrNodes[nAt].right, m_arrNodes[nAt].bottom);
			CPoint ptArcEnd(m_arrNodes[nAt].right, m_arrNodes[nAt].top);
			m_memDC.Arc(&rectVert, ptArcStart, ptArcEnd);
		}
		{
			CPoint ptArcStart(m_arrNodes[nAt].left, m_arrNodes[nAt].top);
			CPoint ptArcEnd(m_arrNodes[nAt].left, m_arrNodes[nAt].bottom);
			m_memDC.Arc(&rectVert, ptArcStart, ptArcEnd);
		}

		CRect rectHoriz(m_arrNodes[nAt]);
		// double width = rectVert.Width();
		// width = width * width * width * width / 2500000.0;
		rectHoriz.InflateRect(height /* width */, 0);
		{
			CPoint ptArcStart(m_arrNodes[nAt].right, m_arrNodes[nAt].top);
			CPoint ptArcEnd(m_arrNodes[nAt].left, m_arrNodes[nAt].top);
			m_memDC.Arc(&rectHoriz, ptArcStart, ptArcEnd);
		}
		{
			CPoint ptArcStart(m_arrNodes[nAt].left, m_arrNodes[nAt].bottom);
			CPoint ptArcEnd(m_arrNodes[nAt].right, m_arrNodes[nAt].bottom);
			m_memDC.Arc(&rectHoriz, ptArcStart, ptArcEnd);
		}

		m_memDC.SelectObject(pPenOld);
		m_memDC.SelectObject(pBrushOld);
		penOuter.DeleteObject();
		brush.DeleteObject();

/*		CRect rectNodeInner(m_arrNodes[nAt]);
		rectNodeInner.DeflateRect(1, 1);
		CPoint ptArcStart(rectNodeInner.right, rectNodeInner.top);
		CPoint ptArcEnd(rectNodeInner.left, rectNodeInner.bottom);

		CPen penUpper(PS_SOLID, 1, COLOR_NODE_BORDER_INNER_UPPER);
		pPenOld = m_memDC.SelectObject(&penUpper);
		m_memDC.Arc(&rectNodeInner, ptArcStart, ptArcEnd);
		m_memDC.SelectObject(pPenOld);
		penUpper.DeleteObject();

		CPen penLower(PS_SOLID, 1, COLOR_NODE_BORDER_INNER_LOWER);
		pPenOld = m_memDC.SelectObject(&penLower);
		m_memDC.Arc(&rectNodeInner, ptArcEnd, ptArcStart);
		m_memDC.SelectObject(pPenOld);
		penLower.DeleteObject(); */
	}

	CPaintDC dc(this); // device context for painting
	dc.BitBlt(m_rectClient.left + rectUpdate.left, 
		m_rectClient.top + rectUpdate.top, 
		rectUpdate.Width(), rectUpdate.Height(), 
		&m_memDC, rectUpdate.left, rectUpdate.top, SRCCOPY);

	// Do not call CView::OnPaint() for painting messages
}

void theWheelView::OnDraw(CDC* pDC)
{
}

/////////////////////////////////////////////////////////////////////////////
// theWheelView printing

BOOL theWheelView::OnPreparePrinting(CPrintInfo* pInfo)
{
	// default preparation
	return DoPreparePrinting(pInfo);
}

void theWheelView::OnBeginPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add extra initialization before printing
}

void theWheelView::OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/)
{
	// TODO: add cleanup after printing
}

/////////////////////////////////////////////////////////////////////////////
// theWheelView diagnostics

#ifdef _DEBUG
void theWheelView::AssertValid() const
{
	CView::AssertValid();
}

void theWheelView::Dump(CDumpContext& dc) const
{
	CView::Dump(dc);
}

theWheelDoc* theWheelView::GetDocument() // non-debug version is inline
{
	ASSERT(m_pDocument->IsKindOf(RUNTIME_CLASS(theWheelDoc)));
	return (theWheelDoc*)m_pDocument;
}
#endif //_DEBUG

/////////////////////////////////////////////////////////////////////////////
// theWheelView message handlers

void theWheelView::OnSize(UINT nType, int cx, int cy) 
{
	CView::OnSize(nType, cx, cy);

	GetClientRect(&m_rectClient);

	// destroy the existing backbuffer
	m_buffer.DeleteObject();
	m_buffer.CreateCompatibleBitmap(GetDC(), cx, cy);

	// re-create the
	m_memDC.DeleteDC();
	m_memDC.CreateCompatibleDC(GetDC());

	m_memDC.SelectObject(m_buffer);
}

void theWheelView::OnMouseMove(UINT nFlags, CPoint point) 
{
	for (int nAt = 0; nAt < m_arrNodes.size(); nAt++)
	{
		InvalidateRect(m_arrNodes[nAt], FALSE);

		CPoint ptOffset = point - m_arrNodes[nAt].CenterPoint();

		int nDist = (int) sqrt(ptOffset.x * ptOffset.x + ptOffset.y * ptOffset.y);
		int nSize = 6000 / (nDist + 50);
		CPoint ptCenter = m_arrNodes[nAt].CenterPoint();
		m_arrNodes[nAt].left = ptCenter.x - nSize;
		m_arrNodes[nAt].right = ptCenter.x + nSize;
		m_arrNodes[nAt].top = ptCenter.y - (int)(nSize * m_aspectRatio);
		m_arrNodes[nAt].bottom = ptCenter.y + (int)(nSize * m_aspectRatio);

		InvalidateRect(m_arrNodes[nAt], FALSE);
	}
	RedrawWindow(NULL, NULL, /* RDW_INVALIDATE | */ RDW_UPDATENOW);
	CView::OnMouseMove(nFlags, point);
}

