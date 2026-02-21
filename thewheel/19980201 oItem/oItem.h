// oItem.h : interface of the oItem class
//

#if !defined _oItem_h_
#define _oItem_h_

#if _MSC_VER >= 1000
#pragma once
#endif // _MSC_VER >= 1000

class oDocument;
class oView;
class oChildWnd;

class oItem : public COleClientItem {

	DECLARE_SERIAL(oItem)

// Constructors
public:
	oItem(oDocument* pContainer = NULL);
		// Note: pContainer is allowed to be NULL to enable IMPLEMENT_SERIALIZE.
		//  IMPLEMENT_SERIALIZE requires the class have a constructor with
		//  zero arguments.  Normally, OLE items are constructed with a
		//  non-NULL document pointer.
	~oItem();

// Attributes
public:
	void OnSizing(DWORD time, CPoint mouse);
	void UpdateFromServerExtent();
	void InvalidateItem();
	CRect myRect;
	oChildWnd *myWnd;
	oDocument *GetDocument()
		{ return (oDocument*)COleClientItem::GetDocument(); }
	oView     *GetActiveView()
		{ return (oView*)COleClientItem::GetActiveView(); }

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(oItem)
	public:
	virtual void OnChange(OLE_NOTIFICATION wNotification, DWORD dwParam);
	virtual void OnActivate();
	protected:
	virtual void OnGetItemPosition(CRect& posRect);
	virtual void OnDeactivateUI(BOOL bUndoable);
	virtual BOOL OnChangeItemPosition(const CRect& rectPos);
	//}}AFX_VIRTUAL

// Implementation
#ifdef _DEBUG
	virtual void AssertValid() const;
	virtual void Dump(CDumpContext& dc) const;
#endif

	virtual void Serialize(CArchive& ar);
};

/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Developer Studio will insert additional declarations 
// immediately before the previous line.

#endif // !defined _oItem_h_
