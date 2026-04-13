MODULE E250Edit;


IMPORT
    ASCII,
    ExtendKey,
    Graph,
    Graphics,
    IO,
    MATHLIB,
    SYSTEM;


CONST
    CenterX  =  320;
    CenterY  =  175;

    MaxText  =  256;


VAR
    (* Cursor status variables *)
    CursX, CursY  :  CARDINAL;
    MemX, MemY  :  CARDINAL;
    StepSize  :  CARDINAL;
    EditMode, EscapeFlag  :  BOOLEAN;
    CurrRange, CurrTilt  :  CARDINAL;


TYPE
    CommentRec  =  RECORD
        AtX, AtY  :  CARDINAL;
        Text  :  ARRAY [ 0..MaxText ] OF CHAR;
    END (* RECORD *);

    Rect  =  ARRAY [ 0..3 ] OF CARDINAL;

VAR
    Comment  :  ARRAY [ 0..9 ] OF CommentRec;
    CurrComm  :  CARDINAL;
    TextAt  :  CARDINAL;



PROCEDURE WriteRangeBear;

CONST
    ER  =  3956.56;
    Pi  =  3.141592654;

VAR
    RX, RY,
    Range,
    Bear,
    Height  :  LONGREAL;

BEGIN

      RX := LONGREAL( CursX ) - 320.0;   (* adjusted for EGA screen *)
      RY := ( 175.0 - LONGREAL( CursY ) ) * 48.0 / 35.0;
      Range := MATHLIB.Sqrt( RX*RX + RY*RY ) *
          LONGREAL( CurrRange ) / 256.0;

      IF RY # 0.0 THEN
          Bear := MATHLIB.ATan2( RY, RX ) * 180.0 / Pi;

      ELSIF RX > 0.0 THEN
          Bear := 90.0;

      ELSIF RX < 0.0 THEN
          Bear := 270.0;

      ELSE
          Bear := 0.0;

      END (* IF *);

      IF Bear < 0.0 THEN
          Bear := Bear + 360.0;

      END (* IF *);

      Height := ( LONGREAL( CurrTilt+90 ) * Pi / 180.0 );
      Height := ( MATHLIB.Sqrt( ER*ER + Range*Range - 2.0*ER*Range*
          MATHLIB.Cos( Height ) ) - ER ) * 52.80;

      Graphics.SetWindow( 0, 0, 639, 349 );

      Graphics.GotoXY( 568, 238 );            (* Position internal cursor *)
      SYSTEM.DI;                       (* Prevent write from interrupting *)
      Graphics.SetPlane( {3} );                        (* Set white plane *)
      Graphics.SetFunc( Graphics.clr, 0 );   (* Set clear function on EGA *)
      IO.WrCard( TRUNC(Range), 3 );                  (* Write range miles *)
      IO.WrStr( '.' );
      IO.WrCard( TRUNC(Range * 10.0) MOD 10, 1 );
      IO.WrStr( ' mi' );
      Graphics.SetPlane( {} );                        (* Reset EGA planes *)
      SYSTEM.EI;                                     (* Enable interrupts *)

      Graphics.GotoXY( 584, 252 );
      SYSTEM.DI;
      Graphics.SetPlane( {3} );
      Graphics.SetFunc( Graphics.clr, 0 );
      IO.WrCard( TRUNC(Bear), 3 );
      IO.WrStr( 'ø' );
      Graphics.SetPlane( {} );
      SYSTEM.EI;

      Graphics.GotoXY( 544, 266 );
      SYSTEM.DI;
      Graphics.SetPlane( {3} );
      Graphics.SetFunc( Graphics.clr, 0 );
      IO.WrLngReal( LONGREAL( TRUNC( Height ) ), 0, 6 );
      IO.WrStr( '00 ft' );
      Graphics.SetPlane( {} );
      SYSTEM.EI;

END WriteRangeBear;



PROCEDURE DrawCursor;

BEGIN
    Graphics.SetFunc( Graphics.xor, 0 );
    IF EditMode THEN
        Graph.Line( CursX, CursY-5, CursX, CursY+5, 15 );
        Graph.Line( CursX-3, CursY-5, CursX+3, CursY-5, 15 );
        Graph.Line( CursX-3, CursY+5, CursX+3, CursY+5, 15 );

    ELSE
        Graph.Line( CursX-5, CursY, CursX+5, CursY, 15 );
        Graph.Line( CursX, CursY-5, CursX, CursY+5, 15 );

    END (* IF *);

END DrawCursor;


PROCEDURE WriteComment;

BEGIN
    WITH Comment[ CurrComm ] DO
        Graphics.SetWindow( AtX, AtY, AtX+100, AtY+100 );
        Graphics.SetFunc( Graphics.clr, 0 );
        Graphics.SetPlane( {0, 1, 2, 3} );
        IO.WrStr( Text );

    END (* WITH *);

END WriteComment;


PROCEDURE ProcessKey( ForKey  :  CHAR );

BEGIN
    IF EscapeFlag THEN
        CASE ForKey OF
            ExtendKey.uarr  :  (* Cursor up *)
                DEC( CursY, StepSize );  |

            ExtendKey.darr  :  (* Cursor down *)
                INC( CursY, StepSize );  |

            ExtendKey.larr  :  (* Cursor left *)
                DEC( CursX, StepSize );  |

            ExtendKey.rarr  :  (* Cursor right *)
                INC( CursX, StepSize );  |

            ExtendKey.Home  :  (* Home cursor *)
                CursX := CenterX;
                CursY := CenterY;  |

            ExtendKey.Ins  :  (* Edit mode *)
                EditMode := ~EditMode;
                IF EditMode THEN
                    Comment[ CurrComm ].AtX := CursX;
                    Comment[ CurrComm ].AtY := CursY;
                    Comment[ CurrComm ].Text := '';
(*                    Graphics.GotoXY( CursX DIV 8, CursY DIV 14 );
                    IO.WrChar( '*' ); *)
                    TextAt := 0;
                    StepSize := 8;

                ELSE
                    StepSize := 4;

                END (* IF *);

        END (* CASE *);
        EscapeFlag := FALSE;

    ELSIF EditMode THEN
        CASE ForKey OF
            ASCII.nul  :  EscapeFlag := TRUE;  |

            ASCII.bs  :
                DEC( TextAt );
                Comment[ CurrComm ].Text[ TextAt ] := ' ';
                Comment[ CurrComm ].Text[ TextAt+1 ] := 000C;  |

            ASCII.cr  :
                Comment[ CurrComm ].Text[ TextAt ] := ASCII.cr;
                Comment[ CurrComm ].Text[ TextAt+1 ] := ASCII.lf;
                INC( TextAt, 2 );
                Comment[ CurrComm ].Text[ TextAt ] := 000C;  |

            ' '..'~'  :
                Comment[ CurrComm ].Text[ TextAt ] := ForKey;
                INC( TextAt );
                Comment[ CurrComm ].Text[ TextAt ] := 000C;  |

        END (* CASE *);
        WriteComment;

    ELSE
        CASE CAP( ForKey ) OF
            ASCII.nul  :  EscapeFlag := TRUE;  |

            'S'  :  (* Memory store *)
                MemX := CursX;
                MemY := CursY;  |

            'R'  :  (* Memory recall *)
                CursX := MemX;
                CursY := MemY;  |

(*            'C'  :  (* Calculate speed from memory *) *)

            'E'  :  (* Erase screen *)
                SYSTEM.DI;
                Graphics.SetFunc( Graphics.clr, 0 );
                Graph.Polygon( 4, Rect( 0, 639, 639, 0 ),
                    Rect( 0, 0, 349, 349 ), 15 );
                SYSTEM.EI;

        ELSE
            (* Pass through to client program *)

        END (* CASE *);

    END (* IF *);

END ProcessKey;



VAR
    Key  :  CHAR;

BEGIN

    CurrRange := 200;
    CurrTilt := 0;
    CurrComm := 0;

    Graph.InitEGA;
    Graph.GraphMode;
    Graphics.SetFont( 14 );

    StepSize := 4;
    EditMode := FALSE;
    EscapeFlag := TRUE;
    Key := ExtendKey.Home;
    REPEAT
        ProcessKey( Key );
        DrawCursor;
        WriteRangeBear;

        Key := IO.RdKey();
        DrawCursor;

    UNTIL Key = ASCII.esc;

END E250Edit.