//////////////////////////////////////////////////////////////////////////
// triocont.h					 Created: 1-11-94 DGL
// Copyright (C) 1994, Derek Graham Lane
// Header file for the Contact, Message, and Thread classes

#include <afx.h>

//////////////////////////////////////////////////////////////////////////
// Contact class

class Contact : public CObject
{	// contains records for a contact
public:
	Contact();
	Contact(CString name);
	~Contact();

	int getNumber();
	int setName(CString name);	    CString& getName();
	int setType(CString type);	    CString& getType();
	int setAddr1(CString addr1);	    CString& getAddr1();
	int setAddr2(CString addr2);	    CString& getAddr2();
	int setCity(CString city);	    CString& getCity();
	int setState(CString state);	    CString& getState();
	int setZip(CString zip);	    CString& getZip();
	int setPhone1(CString phone1);	    CString& getPhone1();
	int setPhone2(CString phone2);	    CString& getPhone2();
	int setFax(CString fax);	    CString& getFax();
	int setEmail(CString email);	    CString& getEmail();

private:
	int m_number;
	CString m_name;
	CString m_type;
	CString m_addr1;
	CString m_addr2;
	CString m_city;
	CString m_state;
	CString m_zip;
	CString m_phone1;
	CString m_phone2;
	CString m_fax;
	CString m_email;
};	// class Contact


class ContactList : public CObList
{	// database of contacts
public:
	ContactList();
	~ContactList();

	Contact& get(CString name);
	int put(Contact forContact);
};	// class ContactList


//////////////////////////////////////////////////////////////////////////
// Message class

class Message : public CObject
{	// messages - phone, fax, e-mail, letter, conversation, etc.
public:
	Message();
	Message(CString name);
	~Message();

	int getNumber();
	int setTime(CTime time);	    CTime& getTime();
	int setType(CString type);	    CString& getType();
	int setDesc(CString desc);	    CString& getDesc();
	int setContact(int contactNum);     int getContact();
	int setFollowup(CTime followup);    CTime& getFollowup();

private:
	int m_number;
	CTime m_time;
	CString m_type;
	CString m_desc;
	int m_contact;
	CTime m_followUp;
};	// class Message


class MessageList : public CObList
{	// list of messages
public:
	MessageList();
	~MessageList();

	Message& get(CString name);
	int put(Message forMessage);
};	// class MessageList


//////////////////////////////////////////////////////////////////////////
// Thread class

class Thread : public CObject
{	// message threads
public:
	Thread();
	Thread(CString name);
	~Thread();

	int getNumber();
	int setDesc(CString desc);	    CString& getDesc();
	int setContact(int contactNum);     int getContact();
	int setProject(int projectNum);     int getProject();
	int addMessage(Message forMessage);
	MessageList& getMessages();

private:
	int m_number;
	CString m_desc;
	int m_contact;
	int m_project;
	MessageList m_messages;
};	// class Thread


class ThreadList : public CObList
{	// list of threads
public:
	ThreadList();
	~ThreadList();

	Thread& get(CString desc);
	int put(Thread forThread);
};	// class ThreadList
