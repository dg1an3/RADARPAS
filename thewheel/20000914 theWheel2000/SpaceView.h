	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// SpaceView.h
//
// Contains the declaration of the CSpaceView class.
//
// Copyright (C) 2000, DG Lane
/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////
// Multiple-inclusion macro
//
/////////////////////////////////////////////////////////////////////////////
#if !defined(_SpaceView_h_)
#define _SpaceView_h_

/////////////////////////////////////////////////////////////////////////////
// Disables long-identifier compiler warning
//
/////////////////////////////////////////////////////////////////////////////
#pragma warning(disable: 4768)

/////////////////////////////////////////////////////////////////////////////
// STL includes
//
/////////////////////////////////////////////////////////////////////////////
#include <map>
using namespace std;

/////////////////////////////////////////////////////////////////////////////
// Application includes
//
/////////////////////////////////////////////////////////////////////////////
#include "Space.h"
#include "NodeView.h"


/////////////////////////////////////////////////////////////////////////////
// Class CSpaceView 
//
// A class that represent the view of a CSpace object; in particular, the 
// CNodes inside the CSpace object.
//
// Maintains a collection of CNodeViews, one for each displayed node.
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985A517032C
class CSpaceView : public CWnd
{
public:

	// Constructs a default CSpaceView with no CSpace to display
	//##ModelId=3985A5170343
	CSpaceView();

	//##ModelId=3985A5170339
	virtual ~CSpaceView();

	// accessors for the CSpace reference to be displayed

	//##ModelId=3989B24B03AC
	CSpace* GetSpace();

	//##ModelId=3989B1DD008D
	void SetSpace(CSpace * pSpace);

	// Normalizes all child CNodeViews (adjusts sum of activations 
	//		to be equal to a pre-set maximum) 
	//##ModelId=3985F3F10260
	void NormalizeAll();

	// Lays out all children, spacing them based on interation fields
	//		to be equal to a pre-set maximum) 
	//##ModelId=3985F6FC017A
	void LayoutAll();

	// Centers layout of all children
	//##ModelId=39A6BB8E007E
	void CenterAll();

	// Adds a new node to this space
	//##ModelId=39A6BB8E0056
	void AddNodeToSpace(CNode *pNewNode);

	//{{AFX_VIRTUAL(CSpaceView)
	protected:
	//##ModelId=3985A5170340
	virtual BOOL PreCreateWindow(CREATESTRUCT& cs);
	//}}AFX_VIRTUAL

	// allows run-time construction of CSpaceView objects
	DECLARE_DYNCREATE(CSpaceView)

protected:

	//
	// Generated message map functions
	//

	//{{AFX_MSG(CSpaceView)
	//##ModelId=3985A5170337
	afx_msg void OnPaint();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

private:
	//##ModelId=39A5A36C0331
	CSpace* m_pSpace;

	//##ModelId=3985DCB40284
	vector<CNodeView *>   m_arrNodeViews;
};

/////////////////////////////////////////////////////////////////////////////


//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(_SpaceView_h_)
