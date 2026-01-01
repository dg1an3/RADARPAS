(* Turbo Pascal Program Lister version 2.00C
   Copyright (C) 1984, BORLAND International, Inc.

   **************************************************************************

   Documentation for this program can be found in the file LISTT.DOC.
   Several parameter files for a few common printers have also been included.
   These are the files with the extension of ".LTP".

   **************************************************************************

   This program is designed to work with all versions of Turbo Pascal.
   However, some parts of the program must be changed between versions.
   The symbol {!} has been used at each place where a change is necessary.
   Of course, each Tutor disk comes with these changes already made.

   This file has been modified for MS/PC-DOS.

   **************************************************************************
*)

{$C-,U-,R-}                                       (* CP/M-86 and MS-DOS *) {!}
(* {$C-,U-,R-,A-}                                               CP/M-80 *) {!}

Program ListTurbo;

  Const
    CopyrightMessage: Array [1..69] Of Char=
      'ListT version 2.00C Copyright (C) 1984, BORLAND International, Inc.'^M^J;

  Type
    FileName=String[20];
    String3=String[3];
    String10=String[10];
    Buffer=String[200];
    ParseStates=(PreKey,KeyWord,Comment,Comment2,Quoted);

  Const
    ParameterSetSize=502; { This is the size of the parameter set that will
                            be saved in a parameter file.  It is the number
                            of bytes enclosed between the variables PageLength
                            and IncludeDrive.  THIS VALUE MUST BE CORRECT!! }

  Type
    ParameterSet=Array [1..ParameterSetSize] Of Byte;
    ParameterRecord=Array [1..1000] Of Byte;

  Const
    NoList: Boolean=False;
    PageStarted: Boolean=False;
    InInclude: Boolean=False;
    CommandLineStartup: Boolean=False;
    ParseState: ParseStates=PreKey;
    YesNo: Array [False..True] Of String[3]=('No','Yes');

  Var
    PageLength: Integer;              {---------------------------------}
    LineWidth: Integer;               { If anything in this section is  }
    HiLite: String10;                 { changed, the constant           }
    LoLite: String10;                 { ParameterSetSize MUST also be   }
    InitString: String10;             { changed to agree with the       }
    ExitString: String10;             { number of bytes here!           }
    LineNumbers: Boolean;             {                                 }
    UpKeys: Boolean;                  {                                 }
    PageForIncludes: Boolean;         {                                 }
    Indent: Integer;                  {                                 }
    Heading: Buffer;                  {                                 }
    Footing: Buffer;                  {                                 }
    CurrentPageNumber: Integer;       {                                 }
    CurrentLineNumber: Integer;       {                                 }
    SavedInFileName: FileName;        {                                 }
    SavedOutFileName: FileName;       {                                 }
    IncludeDrive: Char;               {---------------------------------}

    Parms: ParameterSet Absolute PageLength; (* For MS-DOS and CP/M-86 *)
(*  Parms: ParameterSet Absolute IncludeDrive;  For CP/M-80 only!  *)      {!}


    ParmFile: File Of ParameterRecord;
    ParmFileName: FileName;
    InFileName: FileName;
    OutFileName: FileName;
    TimeString: String10;
    DateString: String10;
    CurrentInFileName: String[60];
    InFile: Text;
    OutFile: Text;
    Ok: Boolean;
    OutIsDevice: Boolean;
    Blanks: Buffer;
    Ch: Char;
    I: Integer;
    LinesLeft: Integer;


  Procedure ErrorMessage(Message: Buffer);

    Var
      Ch: Char;

    Begin
      WriteLn(Message);
      While KeyPressed Do Read(Kbd,Ch); { Flush input buffer }
      Write('Hit any key to continue or <ESC> to abort: ');
      Read(Kbd,Ch);
      WriteLn;
      If Ch=^[ Then Halt;
    End;


  Function CommandLineArgument(N: Integer): FileName;

    Const
      Buffered: Boolean=False;
      CommandLineBuffer: String[127]='';

    Var
      CommandLine: String[127] Absolute CSeg:$0080;  (* MS-DOS *)          {!}
(*    CommandLine: String[127] Absolute DSeg:$0080;     CP/M-86
      CommandLine: String[127] Absolute $0080;          CP/M-80     *)
      CLA: FileName;
      I,J: Integer;

    Begin
      If Not Buffered Then CommandLineBuffer:=CommandLine;
      Buffered:=True;
      J:=1;
      For I:=1 To N Do
       Begin
        CLA:='';
        While (J<=Length(CommandLineBuffer)) And (CommandLineBuffer[J]=' ') Do J:=J+1;
        While (J<=Length(CommandLineBuffer)) And (CommandLineBuffer[J]<>' ') Do
         Begin
          CLA:=CLA+CommandLineBuffer[J];
          J:=J+1;
         End;
       End;
      CommandLineArgument:=CLA;
    End;


  Procedure InitParms;


    Procedure ZeroFill(Var S: String10);

      Var
        I: Integer;

      Begin
        For I:=1 To Length(S) Do If S[I]=' ' Then S[I]:='0';
      End;


    Var
      Hour,Min,AM_PM,Month,Day,Year: String[2];
      I: Integer;
      Regs: Record Case Integer Of                       (* MS-DOS only *) {!}
                     1: (AX,BX,CX,DX,BP,DI,SI,DS,ES,Flags: Integer);
                     2: (AL,AH,BL,BH,CL,CH,DL,DH: Byte);
                   End;
(*    Nothing for CP/M-80 or CP/M-86    *)                                 {!}

    Begin { InitParms }
      PageLength:=66;            { PageLength must be greater    }
      LineWidth:=79;             { than 6; all others may take   }
      HiLite:='';                { on any reasonable value...    }
      LoLite:='';                { LineWidth is 79 to prevent    }
      InitString:='';            { line wrap on some printers.   }
      ExitString:='';
      LineNumbers:=False;
      UpKeys:=False;
      PageForIncludes:=False;
      Indent:=0;
      Heading:='Listing of %F, page %# at %T %D';
      Footing:='%F page %#';
      CurrentPageNumber:=1;
      CurrentLineNumber:=1;

      Blanks:='';
      For I:=1 To 200 Do Blanks:=Blanks+' ';

      With Regs Do                                           (* MS-DOS *) {!}
       Begin           (* Comment entire section out for CP/M-80 or 86 *) {!}
        AH:=$2C;
        Flags:=0;
        MsDos(Regs);
        AM_PM:='am';
        If CH>11 Then
         Begin
          CH:=CH-12;
          AM_PM:='pm';
         End;
        If CH=0 Then CH:=12;
        Str(CH:2,Hour);
        Str(CL:2,Min);
        TimeString:=Hour+':'+Min+AM_PM;
        ZeroFill(TimeString);

        AH:=$2A;
        Flags:=0;
        MsDos(Regs);
        Str((CX Mod 100):2,Year);
        Str(DL:2,Day);
        Str(DH:2,Month);
        DateString:=Month+'/'+Day+'/'+Year;
        ZeroFill(DateString);                                              {!}
       End; { With Regs }    (* End of commented-out area for CP/M-80 or 86 *)

   (* TimeString:='';                                                      {!}
      DateString:=''; *)       (* Comment these 2 lines out for MS-DOS *)  {!}
    End; { InitParms }


  Procedure FixString(Var St: FileName);

    Var
      I: Integer;

    Begin
      While (St[1]=' ') And (Length(St)>0) Do Delete(St,1,1);
      If Pos(' ',St)<>0 Then St[0]:=Chr(Pos(' ',St)-1);
      For I:=1 To Length(St) Do St[I]:=UpCase(St[I]);
    End;


  Procedure FixFileName(Var FN: FileName; Ext: String3);

    Begin
      FixString(FN);
      If Pos('.',FN)=0 Then FN:=FN+'.'+Ext;
    End;


  Function PercentExpand(Ing: Buffer): Buffer;

    Var
      PE: Buffer;
      I,CPN: Integer;
      PN: String[6];
      Center: (Left,Middle,Right);

    Begin
      Center:=Middle;
      PE:='';
      I:=1;
      While (I<=Length(Ing)) Do
       Begin
        If Ing[I]<>'%' Then PE:=PE+Ing[I]
        Else If I=Length(Ing) Then PE:=PE+'%'
        Else
         Begin
          Case UpCase(Ing[I+1]) Of
            '#': Begin
                   PN:='';
                   CPN:=CurrentPageNumber;
                   Repeat
                     PN:=Chr(Ord('0')+(CPN Mod 10))+PN;
                     CPN:=CPN Div 10;
                   Until CPN=0;
                   PE:=PE+PN;
                 End;
            'T': PE:=PE+TimeString;
            'D': PE:=PE+DateString;
            'F': PE:=PE+CurrentInFileName;
            '<': Center:=Left;
            '>': Center:=Right;
            '[': Begin
                   Center:=Right;
                   If Odd(CurrentPageNumber) Then Center:=Left;
                 End;
            ']': Begin
                   Center:=Left;
                   If Odd(CurrentPageNumber) Then Center:=Right;
                 End;
            Else PE:=PE+Ing[I+1];
           End; { Case Ing[I+1] }
          I:=I+1;
         End; { Else Ing[I]='%' }
        I:=I+1;
       End; { While }
      If Length(PE)>LineWidth Then PE[0]:=Chr(LineWidth);
      If Center=Middle Then
        PE:=Copy(Blanks,1,(LineWidth-Length(PE)) Div 2)+PE
      Else If Center=Right Then
        PE:=Copy(Blanks,1,LineWidth-Length(PE))+PE;
      PercentExpand:=PE;
    End; { PercentExpand }


  Procedure WLine(S: Buffer);

    Begin
      If KeyPressed Then
       Begin
        Repeat
          Read(Kbd,Ch)
        Until Not KeyPressed;
        Write(^M,'Terminate (Y/N)? ');
        Read(Kbd,Ch);
        If UpCase(Ch)='Y' Then
         Begin
          WriteLn('Y');
          Write(OutFile,ExitString);
          Close(OutFile);
          Halt;
         End
        Else Write(^M,'                ',^M);
       End; { If KeyPressed }
      If Not PageStarted Then
       Begin
        WriteLn(OutFile);
        WriteLn(OutFile,PercentExpand(Heading));
        WriteLn(OutFile);
        PageStarted:=True;
       End;
      Write(OutFile,Copy(Blanks,1,Indent));
      If LineNumbers Then
       Begin
        Write(OutFile,CurrentLineNumber:5);
        If InInclude Then Write(OutFile,'> ')
        Else Write(OutFile,': ');
       End
      Else If InInclude Then Write(OutFile,'> ');
      WriteLn(OutFile,S);
      If (OutFileName<>'CON:') And (CurrentLineNumber Mod 16=0) Then
        Write(^M,'Line ',CurrentLineNumber);
      LinesLeft:=LinesLeft-1;
      If LinesLeft=0 Then
       Begin
        WriteLn(OutFile);
        WriteLn(OutFile,PercentExpand(Footing));
        WriteLn(OutFile);
        LinesLeft:=PageLength-6;
        CurrentPageNumber:=CurrentPageNumber+1;
        PageStarted:=False;
       End;
    End; { WLine }


  Procedure NewPage;

    Var
      SaveLineNumbers: Boolean;

    Begin
      SaveLineNumbers:=LineNumbers;
      LineNumbers:=False;
      Repeat
        WLine('');
      Until Not PageStarted;
      LineNumbers:=SaveLineNumbers;
    End;


  Procedure ListIt(Var InF: Text);

    Var
      Line, Remainder: Buffer;
      WasCmd: Boolean;


    Procedure UpKeyWords;

      Const
        NKeyWords=45;
        MaxKeyLen=9;
        MaxKeyLenPlus1=10;
        KeyWords: Array [1..NKeyWords] Of String[MaxKeyLen]=
          ('ABSOLUTE','AND','ARRAY','BEGIN','CASE','CONST','DIV','DO',
           'DOWNTO','ELSE','END','EXTERNAL','FILE','FOR','FORWARD','FUNCTION',
           'GOTO','IF','IN','INLINE','LABEL','MOD','NIL','NOT','OF','OR',
           'OVERLAY','PACKED','PROCEDURE','PROGRAM','RECORD','REPEAT','SET',
           'SHL','SHR','STRING','THEN','TO','TYPE','UNTIL','VAR','WHILE',
           'WITH','XOR','');

      Var
        First, LL, LK, I, J: Integer;
        PossibleKey: String[MaxKeyLenPlus1];
        Min, Max, Guess: Integer;
        Found: Boolean;
        Line1: Buffer;


      Begin
        I:=1;
        LL:=Length(Line)+1;
        If UpKeys Then
         Begin
          Line[Length(Line)+1]:=Chr(254);
          Line[0]:=Succ(Line[0]);
          While I<=LL Do
           Begin
            Case ParseState Of
              PreKey: Case Line[I] Of
                        'A'..'Z','a'..'z','_': Begin
                          ParseState:=KeyWord;
                          First:=I;
                          LK:=1;
                         End;
                        '{': ParseState:=Comment;
                        '(': If (Line[I+1]='*') And (I+1<LL) Then
                              Begin
                               ParseState:=Comment2;
                               I:=I+1;
                              End;
                        '''': ParseState:=Quoted;
                      End; { Case Line[I] }
              KeyWord: If Line[I] In ['A'..'Z','a'..'z','0'..'9','_'] Then
                        Begin
                         If LK<10 Then LK:=LK+1;
                        End
                       Else
                        Begin
                         ParseState:=PreKey;
                         I:=I-1;
                         PossibleKey[0]:=Chr(LK);
                         For J:=1 To LK Do
                           PossibleKey[J]:=UpCase(Line[First+J-1]);
                         Found:=False;
                         Min:=1;
                         Max:=NKeyWords+1;
                         Repeat
                           Guess:=(Min+Max) Div 2;
                           If PossibleKey=KeyWords[Guess] Then Found:=True
                           Else If PossibleKey<KeyWords[Guess] Then Max:=Guess
                           Else Min:=Guess+1;
                         Until Found Or (Min=Max);
                         If Found Then
                           If (LoLite='') Or (HiLite='') Then
                             Line:=Copy(Line,1,First-1)+PossibleKey+
                                   Copy(Line,First+LK,200)
                           Else
                            Begin
                             Line:=Copy(Line,1,First-1)+HiLite+
                                   Copy(Line,First,LK)+LoLite+
                                   Copy(Line,First+LK,200);
                             LL:=Length(Line);
                             I:=I+Length(HiLite)+Length(LoLite);
                            End;
                        End; { Else Line[I] Not In keyword character set }
              Comment: If Line[I]='}' Then ParseState:=PreKey;
              Comment2: If Copy(Line,I,2)='*)' Then ParseState:=PreKey;
              Quoted: If Line[I]='''' Then ParseState:=PreKey;
             End; { Case ParseState }
            I:=I+1;
           End; { While I<=LL }
          If Line[Length(Line)]=Chr(254) Then Line[0]:=Pred(Line[0]);
         End; { If UpKeys }
        Line1:=Remainder;
        If UpKeys And (Line[Length(Line)]='*') Then Line1:='*'+Line1;
        If Not UpKeys Then Line1:=Line+Remainder;
        I:=1;
        LL:=Length(Line1)+1;
         While I<LL Do
          Begin
           Case Line1[I] Of
             '{': If ParseState<>Quoted Then ParseState:=Comment;
             '(': If (ParseState<>Quoted) And (Copy(Line1,I,2)='(*') Then
                    ParseState:=Comment2;
             '}': If ParseState=Comment Then ParseState:=PreKey;
             '*': If (ParseState=Comment2) And (Copy(Line1,I,2)='*)') Then
                    ParseState:=PreKey;
             '''': If ParseState=Quoted Then ParseState:=PreKey
                   Else If ParseState=PreKey Then ParseState:=Quoted;
            End;
           I:=I+1;
          End; { While I<LL }
        If ParseState=Quoted Then ParseState:=PreKey;
      End; { UpKeyWords }


    Procedure TruncateLine;

      Var
        Extra: Integer;

      Begin
        Extra:=Indent;
        If LineNumbers Then Extra:=Extra+7
        Else If InInclude Then Extra:=Extra+2;
        If Length(Line)+Extra>LineWidth Then
         Begin
          Remainder:=Copy(Line,LineWidth-Extra+1,200);
          Line:=Copy(Line,1,LineWidth-Extra);
         End
        Else
          Remainder:='';
      End;


    Procedure ProcessDirectives;

      Var
        Cmd: String3;
        IncludeName: FileName;
        IncludeFile: Text;
        Where, Temp, OffSet: Integer;
        RightPart: Buffer;
        Delimiter: String[2];
        WasEmpty: Boolean;


      Procedure CheckDirective(Where, Len: Integer);


        Function CmdStr: Buffer;

          Begin
            CmdStr:=Copy(Line,Where+3,Len-3);
          End;


        Function CmdVal(OldVal: Integer): Integer;

          Var
            I,Temp,Code: Integer;
            CV: FileName;

          Begin
            CV:=CmdStr;
            FixString(CV);
            Val(CV,Temp,Code);
            If Code=0 Then CmdVal:=Temp
            Else
             Begin
              CmdVal:=OldVal;
              WasCmd:=False;
             End;
          End;


        Begin { CheckDirective }
          WasCmd:=False;
          If Line[Where]='.' Then
           Begin
            Cmd:=Copy(Line,Where+1,2);
            For I:=1 To 2 Do Cmd[I]:=Upcase(Cmd[I]);
            WasCmd:=True;
            If Cmd='PL' Then
             Begin
              If PageStarted Then NewPage;
              PageLength:=CmdVal(PageLength);
              If PageLength<7 Then PageLength:=7;
              LinesLeft:=PageLength-6;
             End
            Else If Cmd='PA' Then NewPage
            Else If Cmd='CP' Then
             Begin
              If LinesLeft<CmdVal(0) Then NewPage;
             End
            Else If Cmd='PO' Then Indent:=CmdVal(Indent)
            Else If Cmd='HE' Then Heading:=CmdStr
            Else If Cmd='FO' Then Footing:=CmdStr
            Else If Cmd='HI' Then HiLite:=CmdStr
            Else If Cmd='LO' Then LoLite:=CmdStr
            Else If Cmd='L-' Then NoList:=True
            Else If Cmd='L+' Then NoList:=False
            Else If Cmd='U-' Then UpKeys:=False
            Else If Cmd='U+' Then UpKeys:=True
            Else If Cmd='N-' Then LineNumbers:=False
            Else If Cmd='N+' Then LineNumbers:=True
            Else If Cmd='P-' Then PageForIncludes:=False
            Else If Cmd='P+' Then PageForIncludes:=True
            Else If Cmd='LW' Then LineWidth:=CmdVal(LineWidth)
            Else If Cmd='PR' Then Write(OutFile,CmdStr)
            Else WasCmd:=False;
           End { If Line[Where]='.' }
          Else If (Line[Where]='$') And (UpCase(Line[Where+1])='I') And
                  Not (Line[Where+2] In ['-','+']) Then
           Begin
            IncludeName:=Copy(Line,Where+2,Len-2);
            FixFileName(IncludeName,'PAS');
            If (IncludeName[2]<>':') And (IncludeDrive<>' ') Then
              IncludeName:=IncludeDrive+':'+IncludeName;
            If InInclude Then
              Line:='-- Illegal nested include of file '+IncludeName+' --'
            Else
             Begin
              Assign(IncludeFile,IncludeName);
              {$I-} Reset(IncludeFile); {$I+}
              Ok:=(IOResult=0);
              If Not Ok Then Line:='-- Include file '+IncludeName+' not found --'
              Else
               Begin
                If PageForIncludes And PageStarted Then NewPage;
                CurrentInFileName:=InFileName+'-include file '+IncludeName;
                WLine(Line);
                WasCmd:=True;
                InInclude:=True;
                CurrentLineNumber:=CurrentLineNumber+1;
                ListIt(IncludeFile);
                CurrentLineNumber:=CurrentLineNumber-1;
                InInclude:=False;
                If PageForIncludes And PageStarted Then NewPage;
                CurrentInFileName:=InFileName;
               End; { Else include file was found }
             End; { Else not currently in include }
           End; { If include directive }
          If WasCmd Then
            Delete(Line,Where-Length(Delimiter),Len+2*Length(Delimiter));
        End; { CheckDirective }


      Begin { ProcessDirectives }
        WasEmpty:=(Line='');
        Where:=1;
        Repeat
          Delimiter:='  ';
          RightPart:=Copy(Line,Where,200);
          OffSet:=201-Where;
          Temp:=Pos('{',RightPart);
          If (Temp<>0) And (Temp<OffSet) Then
           Begin
            OffSet:=Temp;
            Delimiter:='{';
           End;
          Temp:=Pos('(*',RightPart);
          If (Temp<>0) And (Temp<OffSet) Then
           Begin
            OffSet:=Temp;
            Delimiter:='(*';
           End;
          Temp:=Pos('''',RightPart);
          If (Temp<>0) And (Temp<OffSet) Then
           Begin
            OffSet:=Temp;
            Delimiter:='''';
           End;
          Where:=Where+OffSet-1;
          Case Delimiter[1] Of
            '''': Where:=Where+Pos('''',Copy(Line,Where+1,200))+1;
            '{': Begin
                   Temp:=Pos('}',Copy(Line,Where+1,200))-1;
                   If Temp=-1 Then Temp:=Length(Copy(Line,Where+1,200));
                   CheckDirective(Where+1,Temp);
                   If Not WasCmd Then Where:=Where+Temp+2;
                 End;
            '(': Begin
                   Temp:=Pos('*)',Copy(Line,Where+2,200))-1;
                   If Temp=-1 Then Temp:=Length(Copy(Line,Where+2,200));
                   CheckDirective(Where+2,Temp);
                   If Not WasCmd Then Where:=Where+Temp+4;
                 End;
             Else Where:=0;
           End; { Case Delimiter[I] }
          If Where=201 Then Where:=0;
        Until Where=0;
        WasCmd:=Not WasEmpty And (Line='');
      End; { ProcessDirectives }


    Begin { ListIt }
      While Not Eof(InF) Do
       Begin
        ReadLn(InF,Line);
        WasCmd:=False;
        ProcessDirectives;
        TruncateLine;
        UpKeyWords;
        If Not (WasCmd And (Line='')) And Not NoList Then WLine(Line);
        CurrentLineNumber:=CurrentLineNumber+1;
       End;
    End; { ListIt }


  Procedure Say(S: Buffer);

    Var
      I: Integer;

    Begin
      I:=1;
      While I<=Length(S) Do
       Begin
        If Ord(S[I])<32 Then Write('^',Chr(Ord(S[I])+64))
        Else If S[I]<>'%' Then Write(S[I])
        Else If S[I+1]='@' Then
         Begin
          WriteLn;
          I:=I+1;
         End
        Else If S[I+1]='!' Then
         Begin
          HighVideo;         { If your screen doesn't have high/low video, }
          Write(S[I+2]);     { replace these 3 lines with:                 }
          LowVideo;          {       Write(S[I+2],')');                    }
          I:=I+2;
         End
        Else Write('%');
        I:=I+1;
       End; { While I<=Length(S) }
    End; { Say }


  Function AskString(Prompt: Buffer; Param: Buffer): Buffer;

    Var
      I: Integer;
      Skip: Boolean;
      AS: Buffer;
      Ch: Char;

    Begin
      AS:=Param;
      WriteLn;
      Say(Prompt);
      I:=0;
      Repeat
        Skip:=False;
        Read(Kbd,Ch);
        Case Ch Of
          ^H,^S,#127:
            Begin
              Skip:=True;
              If I>0 Then
               Begin
                Write(^H,' ',^H);
                If Ord(AS[I])<32 Then Write(^H,' ',^H);
                I:=I-1;
               End;
            End;
          ^A,^X:
            Begin
              Skip:=True;
              While I>0 Do
               Begin
                Write(^H,' ',^H);
                If Ord(AS[I])<32 Then Write(^H' '^H);
                I:=I-1;
               End;
            End;
          ^D: If Length(AS)>I Then Ch:=AS[I+1]
              Else Skip:=True;
          ^F,^R:
            Begin
              Skip:=True;
              While Length(AS)>I Do
               Begin
                I:=I+1;
                If Ord(AS[I])>31 Then Write(AS[I])
                Else Write('^',Chr(Ord(AS[I])+64));
               End;
            End;
          ^P: Read(Kbd,Ch);
          ^M: Skip:=True;
         End; { Case Ch }
        If Not Skip Then
         Begin
          If Ord(Ch)>31 Then Write(Ch)
          Else Write('^',Chr(Ord(Ch)+64));
          I:=I+1;
          AS[I]:=Ch;
          If I>Length(AS) Then AS[0]:=Chr(I);
         End;
      Until Skip And (Ch=^M);
      AS[0]:=Chr(I);
      AskString:=AS;
    End; { AskString }


  Procedure AskInt(Prompt: Buffer; Var Param: Integer);

    Var
      Temp: Buffer;
      P,Legal: Integer;

    Begin
      Str(Param,Temp);
      Temp:=AskString(Prompt,Temp);
      Val(Temp,P,Legal);
      If Legal=0 Then Param:=P;
    End;


  Procedure Title;

    Begin
      ClrScr;
      HighVideo;
      WriteLn('Turbo Pascal Program Lister Ver. 2.00C   Copyright (C) 1984 BORLAND Int''l Inc.');
      LowVideo;
    End;


  Procedure HardwareMenu;

    Var
      Command: Char;
      ReDraw: Boolean;

    Begin
      ReDraw:=True;
      Repeat
        If ReDraw Then
         Begin
          Title;
          Say('%@Hardware parameters:%@%@%!Page length: ');
          WriteLn(PageLength);
          Say('Line %!Width: ');
          WriteLn(LineWidth);
          Say('%@%!Hilite string: "'+HiLite+'"%@');
          Say('%!Lolite string: "'+LoLite+'"%@%@');
          Say('%!Initialization string: "'+InitString+'"%@');
          Say('%!Exit string: "'+ExitString+'"%@%@');
          Say('%!Drive for include files: '+IncludeDrive);
          If IncludeDrive<>' ' Then Write(':');
          Say('%@%@%!Quit%@%@>');
         End; { If ReDraw }
        Read(Kbd,Command);
        ReDraw:=True;
        Case Upcase(Command) Of
          'P': AskInt('New page length: ',PageLength);
          'W': AskInt('New line width: ',LineWidth);
          'H': HiLite:=AskString('New hilite string: ',HiLite);
          'L': LoLite:=AskString('New lolite string: ',LoLite);
          'I': InitString:=AskString('New printer initialization string: ',
                                     InitString);
          'E': ExitString:=AskString('New printer exit string: ',
                                     ExitString);
          'D': Begin
                 Say('%@New drive for include files: ');
                 Read(Kbd,IncludeDrive);
                 If IncludeDrive In ['A'..'Z','a'..'z'] Then
                   IncludeDrive:=Upcase(IncludeDrive)
                 Else IncludeDrive:=' ';
               End;
          Else ReDraw:=False;
         End; { Case Command }
      Until Upcase(Command)='Q';
    End; { HardwareMenu }


  Procedure FormatMenu;

    Var
      Command: Char;
      ReDraw: Boolean;
      TempBuf: Buffer;

    Begin
      ReDraw:=True;
      Repeat
        If ReDraw Then
         Begin
          Title;
          Say('%@Formatting parameters:%@%@Print line %!Numbers: '+
              YesNo[LineNumbers]);
          Say('%@Hilite %!Reserved words: '+YesNo[UpKeys]);
          Say('%@%!Start a new page for each include file: '+
              YesNo[PageForIncludes]);
          Say('%@%@%!Indent lines by: ');
          WriteLn(Indent);
          Say('%@%!Heading:   "'+Heading+'"%@');
          TempBuf:=PercentExpand(Heading);
          Say('  Example: "'+TempBuf+'"%@');
          Say('%!Footing:   "'+Footing+'"%@');
          TempBuf:=PercentExpand(Footing);
          Say('  Example: "'+TempBuf+'"%@');
          Say('%@Starting %!Page number: ');
          WriteLn(CurrentPageNumber);
          Say('Starting %!Line number: ');
          WriteLn(CurrentLineNumber);
          Say('%@%!Quit%@%@>');
         End; { If ReDraw }
        Read(Kbd,Command);
        ReDraw:=True;
        Case Upcase(Command) Of
          'N': LineNumbers:=Not LineNumbers;
          'R': UpKeys:=Not UpKeys;
          'S': PageForIncludes:=Not PageForIncludes;
          'I': AskInt('New indent: ',Indent);
          'H': Heading:=AskString('New heading: ',Heading);
          'F': Footing:=AskString('New footing: ',Footing);
          'P': AskInt('Starting page number: ',CurrentPageNumber);
          'L': AskInt('Starting line number: ',CurrentLineNumber);
          Else ReDraw:=False;
         End;
      Until Upcase(Command)='Q';
    End; { FormatMenu }


  Procedure LoadParms;

    Var
      PP: Record Case Integer Of
            1: (P1000: ParameterRecord);
            2: (Parmz: ParameterSet);
          End;

    Begin
      Assign(ParmFile,ParmFileName);
      {$I-} Reset(ParmFile); {$I+}
      If IOResult<>0 Then ErrorMessage('Parameter file not found')
      Else
       Begin
        Read(ParmFile,PP.P1000);
        Parms:=PP.Parmz;
        Close(ParmFile);
        If InFileName='' Then InFileName:=SavedInFileName;
        If (OutFileName='') Or (OutFileName='P') Or (OutFileName='S') Then
          OutFileName:=SavedOutFileName;
       End; { Else parameter file was found }
     End; { LoadParms }


  Procedure MainMenu;

    Var
      Command: Char;
      ReDraw: Boolean;
      PP: Record Case Integer Of
            1: (P1000: ParameterRecord);
            2: (Parmz: ParameterSet);
          End;

    Begin
      If OutFileName='.LIS' Then OutFileName:='P';
      CurrentInFileName:=InFileName;
      ReDraw:=True;
      Repeat
        If ReDraw Then
         Begin
          Title;
          Say('%@Main menu%@%@%!Input file:  ');
          Write(InFileName);
          Say('%@%!Output file: ');
          If OutFileName='S' Then Write('The screen')
          Else If OutFileName='P' Then Write('The printer')
          Else Write(OutFileName);
          Say('%@%@%!Load parameter file%@');
          Say('%!Save parameter file%@%@');
          Say('%!Hardware parameters%@');
          Say('%!Formatting parameters%@%@');
          Say('%!Time: ');
          WriteLn(TimeString);
          Say('%!Date: ');
          WriteLn(DateString);
          Say('%@%!Reset line and page numbers%@%@%!Quit%@%!Go%@%@>');
         End; { If ReDraw }
        Read(Kbd,Command);
        Command:=Upcase(Command);
        ReDraw:=True;
        Case Command Of
          'I': Begin
                 InFileName:=AskString('Input file name: ',InFileName);
                 If InFileName<>'' Then FixFileName(InFileName,'PAS');
                 CurrentInFileName:=InFileName;
                 If (IncludeDrive=' ') And (InFileName[2]=':') Then
                   IncludeDrive:=InFileName[1];
               End;
          'O': Begin
                 OutFileName:=AskString('Output file name (or S=the screen or P=the printer): ',OutFileName);
                 FixString(OutFileName);
                 If (OutFileName<>'P') And (OutFileName<>'S') Then
                   FixFileName(OutFileName,'LIS');
               End;
          'T': TimeString:=AskString('Current time: ',TimeString);
          'D': DateString:=AskString('Current date: ',DateString);
          'L': Begin
                 ParmFileName:=AskString('Parameter file name: ',ParmFileName);
                 FixFileName(ParmFileName,'LTP');
                 WriteLn(^M,'Parameter file name: ',ParmFileName);
                 LoadParms;
                 Delay(500);
               End;
          'S': Begin
                 ParmFileName:=AskString('Parameter file name: ',ParmFileName);
                 FixFileName(ParmFileName,'LTP');
                 WriteLn(^M,'Parameter file name: ',ParmFileName);
                 Assign(ParmFile,ParmFileName);
                 {$I-} Reset(ParmFile); {$I+}
                 Command:='Y';
                 If IOResult=0 Then
                  Begin
                   Close(ParmFile);
                   Write('Overwrite (DESTROY) old ',ParmFileName,'? ');
                   ReadLn(Command);
                   Command:=Upcase(Command);
                  End;
                 If Command='Y' Then
                  Begin
                   Assign(ParmFile,ParmFileName);
                   {$I-} Rewrite(ParmFile); {$I+}
                   If IOResult=0 Then
                    Begin
                     SavedInFileName:=InFileName;
                     SavedOutFileName:=OutFileName;
                     FillChar(PP.P1000,1000,0);
                     PP.Parmz:=Parms;
                     Write(ParmFile,PP.P1000);
                     Close(ParmFile);
                    End { If IOResult=0 }
                   Else ErrorMessage(ParmFileName+' could not be opened.');
                  End { If Command='Y' }
                 Else Command:=' ';
                End;
          'H': HardwareMenu;
          'F': FormatMenu;
          'R': Begin
                 CurrentLineNumber:=1;
                 CurrentPageNumber:=1;
               End;
          'G': If (InFileName='') Or (OutFileName='') Then
                 ErrorMessage('Both input and output filenames must be specified!');
          Else ReDraw:=False;
         End; { Case Command }
      Until (Command='Q') Or (Command='G');
      WriteLn;
      If Command='Q' Then Halt;
    End; { MainMenu }


  Begin { ListTurbo }
    InFileName:=CommandLineArgument(1);
    OutFileName:=CommandLineArgument(2);
    ParmFileName:=CommandLineArgument(3);
    If InFileName[1]='&' Then
     Begin
      CurrentInFileName:=InFileName; { Temporary }
      InFileName:=OutFileName;
      OutFileName:=ParmFileName;
      ParmFileName:=Copy(CurrentInFileName,2,20);
     End
    Else If OutFileName[1]='&' Then
     Begin
      CurrentInFileName:=OutFileName; { Temporary }
      OutFileName:=ParmFileName;
      ParmFileName:=Copy(CurrentInFileName,2,20);
     End;
    If ParmFileName[1]='&' Then Delete(ParmFileName,1,1);
    FixFileName(InFileName,'PAS');
    If InFileName='.PAS' Then InFileName:='';
    IncludeDrive:=' ';
    If InFileName[2]=':' Then IncludeDrive:=InFileName[1];
    FixString(OutFileName);
    If (OutFileName<>'S') And (OutFileName<>'P') Then
      FixFileName(OutFileName,'LIS');
    If OutFileName='.LIS' Then OutFileName:='';
    FixFileName(ParmFileName,'LTP');
    InitParms;
    If ParmFileName<>'.LTP' Then LoadParms;
    If OutFileName='' Then OutFileName:='P';
    If InFileName='' Then MainMenu
    Else CommandLineStartup:=True;
    Repeat
      Assign(InFile,InFileName);
      {$I-} Reset(InFile); {$I+}
      Ok:=(IOResult=0);
      If Not Ok Then
        ErrorMessage('File '+InFileName+' does not exist!')
      Else
       Begin
        OutIsDevice:=False;
        If (OutFileName='S') Or (OutFileName='P') Then
         Begin
          OutIsDevice:=True;
          If OutFileName='S' Then OutFileName:='CON:'
          Else OutFileName:='LST:';
         End;
        Assign(OutFile,OutFileName);
        {$I-} Reset(OutFile);
        Ok:=(IOResult<>0) Or OutIsDevice;
        Close(OutFile); {$I+}
        If Not Ok Then
         Begin
          Write('File ',OutFileName,' exists.  Replace (DESTROY) it (Y/N)? ');
          ReadLn(Ch);
          If UpCase(Ch)='Y' Then Ok:=True;
         End;
        If Ok Then
         Begin
          Assign(OutFile,OutFileName);
          {$I-} Rewrite(OutFile); {$I+}
          Ok:=(IOResult=0);
          If Not Ok Then ErrorMessage('File '+OutFileName+' could not be created.')
          Else
           Begin
            If OutFileName='LST:' Then
             Begin
              Write('Position printer at top of form and hit return: ');
              ReadLn;
             End;
            Write(OutFile,InitString);
            LinesLeft:=PageLength-6;
            CurrentInFileName:=InFileName;
            ListIt(InFile);
            If PageStarted Then NewPage;
            Write(OutFile,ExitString);
            Close(OutFile);
           End; { Else output file was succesfully created }
         End; { If Ok }
       End; { Else input file was found }
      If OutFileName='LST:' Then OutFileName:='P'
      Else If OutFileName='CON:' Then OutFileName:='S';
      If Not CommandLineStartup Then MainMenu;
    Until CommandLineStartup;
  End. { ListTurbo }
