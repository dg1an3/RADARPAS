//////////////////////////////////////////////////////////////////////////
// trioproj.h					 Created: 1-11-94 DGL
// Copyright (C) 1994, Derek Graham Lane
// Header file for the Contact, Message, and Thread classes

#include <afx.h>
#include <afxcoll.h>

//////////////////////////////////////////////////////////////////////////
// Project classes

class Project : public CObject
{	// contains records for a project
	DECLARE_SERIAL(Project);
public:
	Project();
	Project(const Project& fromProj);
	Project(const char* name);

	int getNumber();
	void setName(const char* name);	    const CString& getName();
	void setDesc(const char* desc);	    const CString& getDesc();
	void setStartDate(const CTime start); const CTime& getStartDate();
	void defineMetric(const char* name);
	int setMetricValue(const char* forMetric, int value);
	int setMetricTarget(const char* forMetric, int target);
	int getMetricValue(const char* forMetric);
	int getMetricTarget(const char* forMetric);
	int setPath(const char* path);	    const CString& getPath();
	int addTask(const Task& forTask);
	TaskList* getTasks();

	Project& operator=(const Project& fromProj);

	virtual void Serialize(CArchive& archive);

private:
	int m_number;
	CString m_name;
	CString m_desc;
	CTime m_start;
	CStringArray m_metric;
	CWordArray m_value;
	CWordArray m_target;
	CString m_path;
};	// class Project


class ProjectList : public CObList
{	// database of projects
	DECLARE_SERIAL(ProjectList);
public:
	ProjectList();
	ProjectList(const ProjectList& fromList);
	void deleteAll();
};	// class ProjectList


//////////////////////////////////////////////////////////////////////////
// Task classes

class Task : public CObject
{	// task descriptor
	DECLARE_SERIAL(Task);
public:
	Task();
	Task(const Task& fromTask);
	Task(const char* name);

	int getNumber();
	void setName(const char* name);	    CString& getName();
	void setDesc(const char* desc);	    CString& getDesc();
	void setType(const char* type);	    CString& getType();
	void setDeadline(CTime time);	    CTime& getDeadline();
	void setEstimate(int hours, int dev);
	int getEstimate();
	int getDeviation();
	int addTime(int hours);		    int getTime();
	int Completed(int flag);
	int setRepeat(int days);	    int getRepeat();
	int setProject(int projNum);	    int getProject();

	Task& operator=(const Task& forTask);

	virtual void Serialize(CArchive& archive);

private:
	int m_number;
	CString m_name;
	CString m_desc;
	CString m_type;
	CTime m_deadline;
	int m_estHours;
	int m_estDeviation;
	int m_timeSpent;
	int m_completed;
	int m_repeat;
	int m_project;
};	// class Task


class TaskList : public CObList
{	// list of tasks
	DECLARE_SERIAL(TaskList);
public:
	TaskList();
	TaskList(const TaskList& fromList);
	void deleteAll();
};	// class TaskList
