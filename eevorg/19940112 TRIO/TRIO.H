#ifndef __TRIO_H__
#define __TRIO_H__

#include <afxwin.h>
/*#include "triocont.h"
#include "trioproj.h"

///////////////////////////////////////////////////////////////////////////
// Contact window and dialogs

class BrowseContacts : public CMDIChildWnd
{	// browse window for Contacts
public:
	BrowseContacts();
	BrowseContacts(ContactList& forList);
	~BrowseContacts();
};	// class BrowseContacts


class ContactDlg : public CDialog
{	// dialog for adding and editing contacts
public:
	ContactDlg();
	ContactDlg(Contact& forContact);
	~ContactDlg();
};	// class ContactDlg


///////////////////////////////////////////////////////////////////////////
// Messages window and dialogs

class BrowseMessages : public CMDIChildWnd
{	// browse window for Messages
public:
	BrowseMessages();
	BrowseMessages(MessageList& forList);
	~BrowseMessages();
};	// class BrowseMessages


class MessageDlg : public CDialog
{	// dialog for adding and editing messages
public:
	MessageDlg();
	MessageDlg(Message& forMessage);
	~MessageDlg();
};	// class MessageDlg


///////////////////////////////////////////////////////////////////////////
// Threads window and dialogs

class BrowseThreads : public CMDIChildWnd
{	// browse window for Threads
public:
	BrowseThreads();
	BrowseThreads(ThreadList& forList);
	~BrowseThreads();
};	// class BrowseThreads


class ThreadDlg : public CDialog
{	// dialog for adding and editing threads
public:
	ThreadDlg();
	ThreadDlg(Thread& forThread);
	~ThreadDlg();
};	// class ThreadDlg


///////////////////////////////////////////////////////////////////////////
// Projects window and dialogs

class BrowseProjects : public CMDIChildWnd
{	// browse window for Projects
public:
	BrowseProjects();
	BrowseProjects(ProjectList& forList);
	~BrowseProjects();
};	// class BrowseProjects


class ProjectDlg : public CDialog
{	// dialog for adding and editing Projects
public:
	ProjectDlg();
	ProjectDlg(Project& forProject);
	~ProjectDlg();
};	// class ProjectDlg


///////////////////////////////////////////////////////////////////////////
// Tasks window and dialogs

class BrowseTasks : public CMDIChildWnd
{	// browse window for Tasks
public:
	BrowseTasks();
	BrowseTasks(TaskList& forList);
	~BrowseTasks();
};	// class BrowseTasks


class TaskDlg : public CDialog
{	// dialog for adding and editing Tasks
public:
	TaskDlg();
	TaskDlg(Task& forTask);
	~TaskDlg();
};	// class TaskDlg

*/
///////////////////////////////////////////////////////////////////////////
// TrioWindow

class TrioWindow : public CFrameWnd
{
public:
	TrioWindow();

	afx_msg void OnPaint();
	afx_msg void OnAbout();

	DECLARE_MESSAGE_MAP()
};	// class TrioWindow


///////////////////////////////////////////////////////////////////////////
// TrioApp

class TrioApp : public CWinApp
{	// main application object for the Trio application
public:
	BOOL InitInstance();
};	// class TrioApp


#endif // __TRIO_H__
