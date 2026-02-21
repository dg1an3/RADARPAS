IMPLEMENTATION MODULE Node;

FROM InOut IMPORT Write, WriteString, WriteInt, WriteLn, ReadString;
FROM NumberConversion IMPORT
  IntToString, StringToInt;
FROM RealConversions IMPORT 
  RealToString, StringToReal;
FROM Strings IMPORT Delete, Copy, Length, Pos;
FROM SYSTEM IMPORT ADR;

PROCEDURE NodeSize(ForNode : NodeRec) : CARDINAL;
BEGIN
  CASE ForNode.Type OF
    Symbol  : RETURN 6+Length(ForNode.StrV); |
    String  : RETURN 2+Length(ForNode.StrV); |
    Integer : RETURN 4; |
    Real    : RETURN 10; |
    List    : RETURN 2+ForNode.MaxElement*4; |
    Subr,
    FSubr   : RETURN 10;
  END; (* CASE *)
END NodeSize;

PROCEDURE MakeNode(ForNode : NodeRec) : NodePtr;
VAR
  TempPtr : NodePtr;
BEGIN
  ALLOCATE(TempPtr,NodeSize(ForNode));
  TempPtr^:=ForNode;
  RETURN TempPtr;
END MakeNode;

PROCEDURE WriteNode(ForNode : NodePtr) : NodePtr;
VAR
  Temp  : NodePtr;
  Count : CARDINAL;
BEGIN
  WITH ForNode^ DO
    IF ForNode<>NIL THEN
      CASE Type OF
        Symbol :
          WriteString(PName); |
        String :
          WriteString(StrV); |
        Integer :
          WriteInt(IntV,0); |
        List :
          Write('(');
          Count:=0;
          WHILE Elem[Count]<>NIL DO
            Write(' ');
            Temp:=WriteNode(Elem[Count]);
            Write(' ');
            INC(Count);
          END; (* WHILE *)
          Write(')');
        ELSE WriteString('INVALID NODE');
      END; (* CASE *)
    ELSE
      WriteString('nil');
    END; (* IF *)
  END; (* WITH *)
  WriteLn;
  RETURN ForNode;
END WriteNode;

PROCEDURE ReadNode(DummyNode : NodePtr) : NodePtr;
VAR
  At       : CARDINAL;
  Done     : BOOLEAN;
  Str      : ARRAY[0..255] OF CHAR;
  TempNode : NodeRec;
BEGIN
  ReadString(Str);
  At:=0;
  WHILE (Str[At]=' ') AND (At<=HIGH(Str)) DO INC(At) END;
  IF At>0 THEN Delete(Str,0,At-1) END;
  CASE Str[0] OF
    '0'..'9','-' : (* Real Number *)
      Copy(Str,0,Pos(' ',Str)-1,Str);
      StringToReal(Str,TempNode.RealV,Done);
      IF Done THEN
        TempNode.Type:=Real;
        Delete(Str,0,Pos(' ',Str));
      END; (* IF *) |
    '"' : (* String *)
      Copy(Str,1,Length(Str)-1,Str);
      IF Pos('"',Str)<=HIGH(Str) THEN
        Copy(Str,0,Pos('"',Str),TempNode.StrV);
        TempNode.Type:=String;
        Delete(Str,0,Pos('"',Str)+1);
      END; (* IF *) |
    '(' : (* List *)
      Copy(Str,1,Length(Str)-1,Str);
      WITH TempNode DO
        MaxElement:=0;
        REPEAT
          INC(MaxElement);
          Element[MaxElement]:=ParseNode(Str);
        UNTIL Element[MaxElement]=NIL;
      END; (* WITH *)
    ELSE (* Symbol *)
      TempNode.Type:=Symbol;
      Copy(Str,0,Pos(' ',Str),TempNode.PName);
      Delete(Str,0,Pos(' ',Str));
  END; (* CASE *)
  RETURN MakeNode(TempNode);
END ReadNode;

VAR
  TestNode1 : NodeRec;
  Temp      : NodePtr;
  Str       : ARRAY[0..12] OF CHAR;
  Size      : CARDINAL;
BEGIN
  Temp:=ADR(TestNode1);
  FromStr:='"1234"';
  Temp:=WriteNode(Temp);
END Node.
