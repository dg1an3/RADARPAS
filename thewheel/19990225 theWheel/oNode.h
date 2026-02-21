/*   
*//* oNode.h
*//* 
*//* Describes the base oNode class for all objects in theWheel.
*//*
*//* Copyright (C) 1999, Derek G. Lane
*//*
  */

#if !defined(_ONODE_H_)
#define _ONODE_H_

#include <list>
#include <string>
using namespace std;

class oNodeLink;

/*   
*//* Class oNode
*//* 
*//*
  */
class oNode
{
public:
	oNode();
	oNode(const char *name_);
	oNode(const oNode& fromNode);
	virtual ~oNode();

	const string& getName();

	void addLink(const oNodeLink& newLink);

	list<oNodeLink>::iterator linkBegin();
	list<oNodeLink>::iterator linkEnd();
	list<oNodeLink>::iterator findLink(oNode *target);

	void removeLink(list<oNodeLink>::iterator iter);

private:
	string name;
	list<oNodeLink>;
};

/*   
*//* Class oNodeLink
*//* 
*//*
  */
class oNodeLink
{
public:
	oNodeLink(oNode *toNode, double weight);
	oNodeLink(const oNodeLink& fromLink);
	virtual ~oNodeLink();

	oNode *getTarget();
	double getWeight();

private:
	oNode *target;
	double weight;
};

#endif // !defined(_ONODE_H_)