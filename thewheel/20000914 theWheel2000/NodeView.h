	/////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////
// NodeView.h
//
// Contains the declaration of the CNodeView class.
//
// Copyright (C) 2000, DG Lane
/////////////////////////////////////////////////////////////////////////////

	/////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////
// Multiple-inclusion macro
//
/////////////////////////////////////////////////////////////////////////////
#if !defined(_NodeView_h_)
#define _NodeView_h_

/////////////////////////////////////////////////////////////////////////////
// Application includes
//
/////////////////////////////////////////////////////////////////////////////
#include "Node.h"


/////////////////////////////////////////////////////////////////////////////
// Class CNodeView 
//
// A class that represent the view of an individual CNode object
//
/////////////////////////////////////////////////////////////////////////////
//##ModelId=3985DC940300
class CNodeView : public CWnd
{
public:

	// Constructs a CNodeView object to display the passed CNode
	//##ModelId=398F34AE01C5
	CNodeView(CNode * pNode);

	// accessors for the center of this window

	//##ModelId=39A6C1990155
	CPoint GetCenter();

	//##ModelId=39A6C1A20071
	void SetCenter(CPoint ptCenter);

	// accessors for the activation value for this window

	//##ModelId=39B6C8D1017E
	float GetActivation();

	//##ModelId=3985EEE0020B
	void SetActivation(float activation);

	// accessor for the node
	//##ModelId=3985EED50010
	CNode *GetNode() { return m_pNode; }

	//{{AFX_VIRTUAL(CNodeView)
	//}}AFX_VIRTUAL

protected:

	//
	// Generated message map functions
	//

	//{{AFX_MSG(CNodeView)
	//##ModelId=39B6C8D10034
	afx_msg void OnLButtonUp(UINT nFlags, CPoint point);
	//##ModelId=3991A39F006C
	afx_msg void OnPaint();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()

private:
	//##ModelId=3985DCF00081
	CNode* m_pNode;

	//##ModelId=3985EA270252
	float m_activation;
};

/////////////////////////////////////////////////////////////////////////////


//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(_NodeView_h_)

