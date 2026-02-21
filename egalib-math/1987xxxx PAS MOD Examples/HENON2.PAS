PROGRAM HENON2;
{$I GRAPH.P}
CONST
   MAX= 1E10;   {used in main loop to X and Y values in range}
   MAXORBIT= 48; {maximum size of arrays used to store orbits}
   BUFSIZE= 128;  {used below to define graphics screen buffer}
   RECSIZE= 128;
TYPE
  HENONPLOT = RECORD  {these are the parameters of a plot}
		RA     :REAL;	 {phase angle A}
		RAXIS  :INTEGER;  {chioce of axis for increments}
		RXOLD0 :REAL;	 {initial starting point XOLD0,YOLD0}
		RYOLD0 :REAL;
		RDXY   :REAL;	 {increment for starting points}
		RORBITN:INTEGER; {# of orbits in plot}
		RPOINTS:INTEGER; {# of points per orbit}
		RL     :REAL;	 {window values,LEFT,RIGHT,BOTTOM,TOP}
		RR     :REAL;
		RB     :REAL;
		RT     :REAL;
		RX: ARRAY[1..MAXORBIT] OF REAL;   {orbits of plot-only}
		RY: ARRAY[1..MAXORBIT] OF REAL;   {essential if AXIS=4}
	       END;
VAR
  I,J,K,P1,P2,TP2,TQ2,TP1,TQ1,Q1,Q2,ORBITN,DECN,TEMP,ORBITN2: INTEGER;
  ORBITL,RESPONSE,RESPON,AXIS,OPTION,POINTS:INTEGER;
  R,L,T,B,A,XOLD,YOLD,XNEW,YNEW,XOLD0,YOLD0,DXY,BETA: REAL;
  XSCALE,YSCALE,HALFW,COSA,SINA,COSB,SINB :REAL;
  GRD,MARK,MNU,MEN,TXT,CHANGE,FIRSTTIME: BOOLEAN;
  BLANKLINE: STRING[80]; CH: CHAR;
  X,Y,XL,YL : ARRAY [1..MAXORBIT] OF REAL;   {for storing orbits}
  CURRENT,PREVIOUS,STORED: HENONPLOT;	     {for storing plot parameters}
  BUFFER: ARRAY[1..RECSIZE,1..BUFSIZE] OF BYTE;  {temporay storage of screens}
								    
PROCEDURE INTRO;
BEGIN
   CLRSCR;  {clear screen}
   WRITELN('                  HENON MAPPING PROGRAM');
   WRITELN('                  BY GORDON HUGHES, MATH DEPT');
   WRITELN('                  CALIFORNIA STATE UNIVERSITY');
   WRITELN('                  CHICO, CA , 95926');
   WRITELN;
   WRITELN('This program will create a Henon mapping to your specifications.');
   WRITELN('A Henon mapping is an iterative mapping of the plane defined by:');
   WRITELN;
   WRITELN('      Xnew = Xold*Cos(A) - (Yold - Xold*Xold)*Sin(A) ');
   WRITELN('      Ynew = Xold*Sin(A) + (Yold - Xold*Xold)*Cos(A) ');
   WRITELN('  (where A is a given parameter, called the phase angle)');
   WRITELN('After you finish a plot you can save your plot parameters or the actual plot.');
   WRITELN('The program also allows you to modify existing plots.');
   WRITELN;
   WRITELN('You will be asked to input the following general types of information:');
   WRITELN('(1): The phase angle A');
   WRITELN('(2): The starting point (Xold,Yold) for each orbit of the plot.');
   WRITELN('     These can be computed automatically by the program from an initial point');
   WRITELN('     and an increment.');
   WRITELN('(3): The number of points to be plotted for each orbit.');
   WRITELN('(4): The window on the plot');
   WRITELN;
   WRITELN('Please hit any key to continue');
   REPEAT UNTIL KEYPRESSED;
END; {procedure intro}							

PROCEDURE DISPLAYOPTIONS;

BEGIN
   CLRSCR;
   WRITELN;
   WRITELN('THIS IS A LIST OF THE CURRENT SETTINGS. TO CHANGE ANY OF THESE');
   WRITELN('ENTER THE NUMBER OF THE OPTION FOLLOWED BY A CARRIGE RETURN');
   WRITELN;
   IF GRD THEN WRITELN('(1) CO-ORDINATE GRID IS ON')
   ELSE WRITELN('(1) CO-ORDINATE GRID IS OFF');
   WRITELN;
   IF TXT THEN WRITELN('(2) DISPLAY OF PLOT TEXT IS ON')
   ELSE WRITELN('(2) DISPLAY OF PLOT TEXT IS OFF');
   WRITELN;
   IF MEN THEN WRITELN('(3) MENU DISPLAY IS ON')
   ELSE WRITELN('(3) MENU DISPLAY IS OFF');
   WRITELN;
   IF MARK THEN WRITELN('(4) CROSS MARK AT STARTING POINT IS ON')
   ELSE WRITELN('(4) CROSS MARK AT STARTING POINT IS OFF');
   WRITELN;
   WRITELN('(5) NUMBER OF DECIMAL PLACES FOR DISPLAY IS   ',DECN);
   GOTOXY(1,23);
   WRITELN('CARRIGE RETURN TO QUIT');
   GOTOXY(1,15);
END;  {procedure displayoptions}				     

PROCEDURE CHANGEOPTIONS;

BEGIN

   REPEAT
    OPTION:= 0;
    READLN(OPTION);
    CASE OPTION OF
       1:  IF GRD THEN GRD:=FALSE ELSE GRD:= TRUE;
       2:  IF TXT THEN TXT:= FALSE ELSE TXT:= TRUE;
       3:  IF MEN THEN MEN:= FALSE ELSE MEN:= TRUE;
       4:  IF MARK THEN MARK:=FALSE ELSE MARK:= TRUE;
       5:  BEGIN
	      WRITELN;
	      WRITELN('HOW MANY PLACES WOULD YOU LIKE (2-11 WITHOUT 8087,2-16 WITH)');
	      READLN(DECN);
	   END;
     END;
    UNTIL OPTION = 0;

END; {procedure changeoptions}					      

PROCEDURE SEARCH;     {interactive search using cursor keys}
BEGIN
HIRES;HIRESCOLOR(0);
PUTPIC(BUFFER,0,199);   {restore last plot}
P1:= ROUND((X[1]-L)*XSCALE); Q1:= ROUND((T- Y[1])*YSCALE);
FOR K:= -6 TO 6 DO    {draw initial cross}
BEGIN
  PLOT(P1+K,Q1,1);
  PLOT(P1,Q1+K,1);
END;

GOTOXY(1,20);
WRITELN('USE ARROW KEYS TO POSITION CROSS AT LOWER LEFT OF SEARCH AREA AND PRESS ESC');
FIRSTTIME:= TRUE;  {used for erase routine}
REPEAT
   READ(KBD,CH);
   IF (CH = #27) AND KEYPRESSED THEN
   BEGIN
      IF FIRSTTIME THEN
    FOR K:= -6 TO 6 DO	  {erase initial cross}
BEGIN
  PLOT(P1+K,Q1,0);
  PLOT(P1,Q1+K,0);
END;
       READ(KBD,CH);
       CASE CH OF
	   #75: X[1]:= X[1]-0.1*DXY; {left}
	   #77: X[1]:= X[1]+ 0.1*DXY; {RIGHT}
	   #72: Y[1]:= Y[1]+ 0.1*DXY; {up}
	   #80: Y[1]:= Y[1]-0.1*DXY; {down}
	END; {CASE}

     P1:= ROUND((X[1]-L)*XSCALE); Q1:= ROUND((T- Y[1])*YSCALE);
     IF NOT FIRSTTIME THEN  {erase old cross}
     FOR K:= -4 TO 4 DO
      BEGIN
	  PLOT(TP1+K,TQ1,0);
	  PLOT(TP1,TQ1+K,0);
      END;

      FOR K:= -4 TO 4 DO
      BEGIN
		PLOT(P1+K,Q1,1);
		PLOT(P1,Q1+K,1);
      END;
      TP1:= P1;TQ1:= Q1;  {save old values for erasure}
     FIRSTTIME:= FALSE;
     END;
 UNTIL (CH =#27) AND NOT KEYPRESSED;					 

 P1:= ROUND((X[1]-L)*XSCALE); Q1:= ROUND((T- Y[1])*YSCALE);
GOTOXY(1,20);
WRITELN('USE ARROW KEYS TO MOVE TO UPPER RIGHT CORNER OF SEARCH AREA AND PRESS ESC     ');
FIRSTTIME:= TRUE;
X[2]:= X[1];Y[2]:= Y[1];
REPEAT
   READ(KBD,CH);
   IF (CH =#27) AND KEYPRESSED THEN
   BEGIN
       READ(KBD,CH);
       CASE CH OF
	   #75: X[2]:= X[2]-0.1*DXY; {left}
	   #77: X[2]:= X[2]+ 0.1*DXY; {RIGHT}
	   #72: Y[2]:= Y[2]+ 0.1*DXY; {up}
	   #80: Y[2]:= Y[2]-0.1*DXY; {down}
	END;
     P2:= ROUND((X[2]-L)*XSCALE); Q2:= ROUND((T- Y[2])*YSCALE);
     IF NOT FIRSTTIME THEN
     BEGIN
     DRAW(P1,Q1,P1,TQ2,0);   {erase old box}
     DRAW(P1,TQ2,TP2,TQ2,0);
     DRAW(TP2,TQ2,TP2,Q1,0);
     DRAW(TP2,Q1,P1,Q1,0);
     END;

     DRAW(P1,Q1,P1,Q2,1);   {draw new box}
     DRAW(P1,Q2,P2,Q2,1);
     DRAW(P2,Q2,P2,Q1,1);
     DRAW(P2,Q1,P1,Q1,1);


     TP2:= P2; TQ2:= Q2;   {save old values for erasure of old box}
     FIRSTTIME:= FALSE;
    END;
 UNTIL (CH =#27) AND NOT KEYPRESSED;

END;   {procedure search}
								 

PROCEDURE DISPLAYORBITS;

BEGIN
   WINDOW(1,3,80,25);
   GOTOXY(1,2);
   FOR K:= ORBITN + 1 TO MAXORBIT DO BEGIN X[K]:= 0.0; Y[K]:= 0.0 END; {zero junk}
   IF ORBITN > 24 THEN WRITELN('THE FIRST 24 CURRENT ORBITS ARE')
   ELSE WRITELN('THE CURRENT ORBITS ARE');
   FOR K:= 1 TO 9 DO WRITELN('  ',K,'  ', X[K]:DECN:DECN-1,' ',Y[K]:DECN:DECN-1);
   FOR K:= 10 TO 12 DO WRITELN(' ',K,'  ', X[K]:DECN:DECN-1,' ',Y[K]:DECN:DECN-1);
   IF ORBITN >12 THEN
   BEGIN
      WRITELN;
      WINDOW(2*DECN+8, 4,80,20); {continue on next column}
      GOTOXY(1,1);
      WRITELN;
      FOR K:= 13 TO 24 DO WRITELN('   ', K,'  ', X[K]:DECN:DECN-1,' ',Y[K]:DECN:DECN-1);
    END;
    WINDOW(1,1,80,25);GOTOXY(1,18);
END; {procedure displayorbits}
								   
PROCEDURE DISPLAYDATA;

BEGIN
   CLRSCR;
   WRITELN('                           THE CURRENT PLOT DATA IS:');
   WRITELN('PHASE ANGLE A = ', A:5:4);
   IF AXIS <>4 THEN
   BEGIN
      WRITELN;
      WRITE('AXIS SELECTED IS: ');
      CASE AXIS OF
	 1: WRITELN('(1) AXIS OF SYMMETRY');
	 2: WRITELN('(2)  X AXIS');
	 3: WRITELN('(3)  AXIS OF CHOICE');
      END;
      WRITELN;
      WRITELN('STARTING POINT X0,Y0 IS ',X[1]:DECN:DECN-1, '  ',Y[1]:DECN:DECN-1);
      WRITELN;
      WRITELN('INCREMENT DXY = ', DXY:DECN:DECN-1);
      WRITELN;
      WRITELN('NUMBER OF ORBITS = ',ORBITN);
      WRITELN;
      WRITELN('NUMBER OF POINTS PER ORBIT = ',POINTS);
      WRITELN;
      WRITELN('WINDOW VALUES ARE:');
      WRITELN('   X-AXIS: ',L:DECN:DECN-1, ' TO ',R:DECN:DECN-1,'  YAXIS: ',B:DECN:DECN-1, ' TO ',T:DECN:DECN-1);
      WRITELN;
    END
    ELSE
    BEGIN
      DISPLAYORBITS;
      WRITELN('TOTAL NUMBER OF ACTIVE ORBITS= ',ORBITN);
      WRITELN('NUMBER OF POINTS PER ORBIT = ',POINTS);
      WRITELN('WINDOW VALUES ARE:');
      WRITELN('  X-AXIS:  ',L:DECN-2:DECN-3, ' TO ',R:DECN-2:DECN-3,'  YAXIS: ',B:DECN-2:DECN-3, ' TO ',T:DECN-2:DECN-3);
    END;
    IF XOLD0 = 0.0 THEN BETA:= PI/2    {update BETA}
    ELSE  BETA:= ARCTAN(YOLD0/XOLD0);
    XSCALE:= 640/(R-L); YSCALE:= 200/(T-B);   {update scale factors}
    GOTOXY(1,23);
    WRITELN('IF THERE ARE NO CHANGES PRESS ESCAPE TO START PLOT');
    WRITE('OTHERWISE PRESS ANY OTHER KEY TO CONTINUE');
    REPEAT UNTIL KEYPRESSED;
    BEGIN
       READ(KBD,CH);
       IF (CH = #27) AND NOT KEYPRESSED THEN CHANGE:= FALSE ELSE CHANGE:= TRUE;
     END;
    WINDOW(1,1,80,25); GOTOXY(1,1);
 END; {procedure displaydata}


									   
PROCEDURE MODIFYORBITS;

VAR
  ORBIT1,ORBIT2:INTEGER;

BEGIN
   CLRSCR;DISPLAYORBITS;
   WRITELN('PLEASE SELECT ONE:');
   WRITELN('          (1) KEEP SAME ORBITS BUT CHANGE NUMBER OF POINTS PER ORBIT');
   WRITELN('          (2) EXPAND ON A SUBSET OF THESE ORBITS');
   WRITELN('          (3) EXPAND ABOUT A SINGLE ORBIT');
   WRITELN('          (4) EXPAND INTERACTIVELY ABOUT A POINT FROM LAST PLOT');
   WRITELN('          (5) ENTER NEW ORBITS');
   WRITELN('          CARRIGE RETURN TO START PLOT');
   READLN(RESPON);
   CASE RESPON OF
   1:BEGIN

      WRITELN;
      WRITELN('INPUT THE NUMBER OF POINTS TO BE PLOTTED PER ORBIT. MAX IS 32000');
      READLN(POINTS);
     END;
   2:
     BEGIN
     AXIS:= 4;
      ORBIT1:=1;ORBIT2:=ORBITN;  {defaults}
      WRITELN('INPUT THE STARTING ORBIT # AND FINAL ORBIT # FOR NEW PLOT');
      READLN(ORBIT1,ORBIT2);
      WRITELN('INPUT NUMBER OF ORBITS IN THE NEW PLOT');
      READLN(ORBITN);
      X[1]:= X[ORBIT1]; Y[1]:= Y[ORBIT1];X[ORBITN]:= X[ORBIT2];Y[ORBITN]:= Y[ORBIT2];
      DXY:= SQRT( SQR (X[ORBIT2] -X[ORBIT1]) + SQR(Y[ORBIT2]-Y[ORBIT1]))/(ORBITN-1);
      WRITELN('INPUT THE NUMBER OF POINTS FOR EACH ORBIT');
      READLN(POINTS);
      BETA:= ARCTAN(Y[1]/X[1]);

      FOR K:= 2 TO ORBITN-1 DO	   {generate new orbits}
      BEGIN
	 X[K]:= X[K-1]+ DXY*COS(BETA);
	 Y[K]:= Y[K-1]+ DXY*SIN(BETA);
      END;
      XOLD0:= X[1];YOLD0:= Y[1];
     END;
								  
  3: BEGIN
 AXIS:= 4;
	WRITELN('PLEASE ENTER THE CO-ORDINATES OF THE POINT OF INTEREST');
	READLN(XNEW,YNEW);
	WRITELN('PLEASE ENTER THE INCREMENT DXY'); READLN(DXY);

	WRITELN('PLEASE ENTER THE NUMBER OF ORBITS DESIRED ON EACH SIDE OF THE POINT');
	WRITELN('OF INTEREST: ORBITS TOWARD THE ORIGIN AND ORBITS AWAY FROM IT');
	READLN(ORBIT1,ORBIT2);
	ORBITN:= ORBIT1 + ORBIT2 + 1;
 IF XNEW <> 0.0 THEN
	BETA:= ARCTAN(YNEW/XNEW)
 ELSE BETA:= 0.0;
	X[1]:= XNEW - ORBIT1*DXY*COS(BETA);
	Y[1]:= YNEW - ORBIT1*DXY*SIN(BETA);
	FOR K:= 2 TO ORBITN DO
	BEGIN
	   X[K]:= X[K-1]+ DXY*COS(BETA);
	   Y[K]:= Y[K-1]+ DXY*SIN(BETA);
	END;
	X[ORBIT1+1]:= XNEW;Y[ORBIT1+1]:= YNEW;	{to make sure this point is included}
	WRITELN('PLEASE INPUT THE NUMBER OF POINTS PER ORBIT');
	READLN(POINTS);
      END;

     4: BEGIN
   AXIS:= 4;
	  SEARCH;  {now X[1],Y[1], X[2],Y[2] contain lower left and upper right of search area}
	  WRITELN('INPUT THE NUMBER OF ORBITS DESIRED');
	  READLN(ORBITN);
	  IF ORBITN <> 1 THEN DXY:= SQRT( SQR (X[2]-X[1]) + SQR(Y[2]-Y[1]))/(ORBITN-1)
   ELSE DXY:= 0.0;  {only one orbit desired}
	  WRITELN('INPUT THE NUMBER OF POINTS FOR EACH ORBIT');
	  READLN(POINTS);
	  IF X[2] <> X[1] THEN BETA:= ARCTAN(Y[2]-Y[1])/(X[2]-X[1])
   ELSE BETA:= PI/2;
	  FOR K:= 2 TO ORBITN DO     {generate new orbits}
	  BEGIN
	     X[K]:= X[K-1]+ DXY*COS(BETA);
	     Y[K]:= Y[K-1]+ DXY*SIN(BETA);
	  END;
	  XOLD0:= X[1];YOLD0:= Y[1];
	  END;

   5:BEGIN
      AXIS:= 4;
      WRITELN('EXISTING ORBITS WILL REMAIN UNLESS CHANGED. HOW MANY ORBITS');
      WRITELN('WOULD YOU LIKE TO REMAIN ?');
      READLN(ORBITN);
	 WRITELN('PLEASE ENTER ANY NEW ORBITS IN THE FORM: ORBIT#  X   Y');
	 WRITELN('WHEN FINISHED ENTER 0 ORBIT# TO TERMINATE');
	 WHILE I > 0 DO READLN(I,X[I],Y[I]);
  WRITELN('PLEASE ENTER THE NUMBER OF POINTS PER ORBIT');
  READLN(POINTS);
      END;  {item 3}
  END; {case}
  XOLD0:= X[1];YOLD0:= Y[1];
  CLRSCR;
  DISPLAYORBITS;
  GOTOXY(1,22);WRITELN('PRESS ANY KEY TO CONTINUE');
  REPEAT UNTIL KEYPRESSED;
  RESPON:= 0;
END; {procedure modifyorbits}					 

PROCEDURE OBTAINDATA;
BEGIN
   CLRSCR;
   IF (RESPONSE <> 2) THEN	{skip A and AXIS input for MENU item 2}
   BEGIN
   WRITELN('INPUT PHASE ANGLE A (IN RADIANS BETWEEN 0.0 AND PI)');
   WRITE('CURRENT VALUE IS  ');WRITE(A:DECN:DECN-1, '      ');
   READLN(A);WRITELN;
   SINA:= SIN(A); COSA:= COS(A);

   WRITELN('INCREMENT ALONG: (1) AXIS OF SYMMETRY   (2) X-AXIS');
   WRITELN('                 (3) AXIS OF CHOICE     (4) NO AXIS-ORBITS FROM ARRAYS X AND Y');
   WRITE('CURRENT VALUE IS '); WRITE(AXIS, '      ');
   READLN(AXIS);WRITELN;
   END;

   CASE AXIS OF
      1: BEGIN
	    BETA:= A/2;
	    IF BETA < PI/4 THEN
	    BEGIN
	       WRITELN('INPUT STARTING POINT X0');
	       WRITE('CURRENT VALUE IS ');WRITE(XOLD0:DECN:DECN-1, '      ');
	       READLN(XOLD0); WRITELN;
	       YOLD0:= SIN(BETA)*XOLD0/COS(BETA);
	    END ELSE
	    BEGIN
	       WRITELN('INPUT STARTING POINT Y0');
	       WRITE('CURRENT VALUE IS ');WRITE(YOLD0:DECN:DECN-1,'      ');
	       READLN(YOLD0); WRITELN;
	       XOLD0:= COS(BETA)*YOLD0/SIN(BETA)
	    END; {if A}
	 END; {item 1}
      2: BEGIN
	    BETA:= 0.0;
	    WRITELN('INPUT STARTING POINT X0');
	    WRITE('CURRENT VALUE IS  ');WRITE(XOLD0:DECN:DECN-1, '    ');
	    READLN(XOLD0); WRITELN;
	    YOLD0:= 0.0;
	 END;
      3: BEGIN
	    WRITELN('INPUT X AND Y CO-ORDINATES OF ANY POINT ON THE DESIRED AXIS');
	    WRITE('CURRENT VALUE IS  ');WRITE(XOLD0:DECN:DECN-1,'  ',YOLD0:DECN:DECN-1,'    ');
	    READLN(XOLD0,YOLD0); WRITELN;
	    IF XOLD0 = 0.0 THEN
	    BEGIN
	       BETA:= PI/2;
	       WRITELN('INPUT STARTING POINT Y0') ;
	       WRITE('CURRENT VALUE IS  ');WRITE(YOLD0:DECN:DECN-1,'       ');
	       READLN(YOLD0);WRITELN;
	    END
	    ELSE
	    BEGIN
	       BETA:= ARCTAN(YOLD0/XOLD0);
	       WRITELN('INPUT STARTING POINT X0');
	       WRITE('CURRENT VALUE IS  '); WRITE(XOLD0:DECN:DECN-1,'       ');
	       READLN(XOLD0); WRITELN; YOLD0:= XOLD0*SIN(BETA)/COS(BETA);
	    END;
	 END;
       4: MODIFYORBITS;
   END;   {case}						  

   IF AXIS <> 4 THEN
   BEGIN
      WRITELN('INPUT INCREMENT DXY');
      WRITE('CURRENT VALUE IS '); WRITE(DXY:DECN:DECN-1, '     ');
      READLN(DXY);WRITELN;
      WRITELN('INPUT NUMBER OF ORBITS');
      WRITE('CURRENT VALUE IS ');WRITE(ORBITN, '        ');
      READLN(ORBITN); WRITELN;
      WRITELN('INPUT NUMBER OF POINTS FOR EACH ORBIT');
      WRITE('CURRENT VALUE IS '); WRITE(POINTS, '        ');
      READLN(POINTS); WRITELN;
      X[1]:= XOLD0; Y[1]:= YOLD0;
      X[ORBITN]:= X[1]+ DXY*ORBITN*COS(BETA); {these might be needed for automatic calculation}
      Y[ORBITN]:= Y[1]+ DXY*ORBITN*SIN(BETA); {of window below}
    END;

   WRITELN('INPUT LEFT AND RIGHT WINDOW VALUES (ENTER 0.0,0.0 FOR AUTO CALCULATION) ');
      WRITE('CURRENT VALUE IS  ');WRITE(L:DECN:DECN-1, '  ',R:DECN:DECN-1, '      ');
      READLN(L,R);
      IF L = R THEN { perform auto calculation of window}
      BEGIN    {first find largest leg of final orbits}
	  IF ABS(X[ORBITN]-X[1]) > ABS(Y[ORBITN]-Y[1]) THEN HALFW:= X[ORBITN]-X[1] ELSE HALFW:=Y[ORBITN]-Y[1];
	  L:= X[1]- HALFW; R:= X[1]+ 1.1*HALFW;
	  B:= Y[1]- HALFW; T:= Y[1]+ 1.1*HALFW;
      END
      ELSE
      BEGIN
	 WRITELN;
	 WRITELN('INPUT BOTTOM AND TOP WINDOW VALUES');
	 WRITE('CURRENT VALUE IS  ');WRITE(B:DECN:DECN-1, '  ',T:DECN:DECN-1, '     ');
	 READLN(B,T);
      END;
XSCALE:= 640/(R-L);YSCALE:= 200/(T-B);
END; {procedure obtaindata}
									 


PROCEDURE DRAWGRID;

VAR
  ZX,ZY:INTEGER;  { zx,zy is the origin of the plot}

BEGIN
   IF (ABS(L*XSCALE) < 30000) AND (ABS(T*YSCALE) < 30000) THEN
   BEGIN
   ZX:= ROUND((0.0-L)*XSCALE);	 {compute origin (ZX,ZY)}
   ZY:= ROUND((T - 0.0)*YSCALE)
   END
   ELSE
   BEGIN
    ZX:= 639;
    ZY:= 199
   END;
   DRAW(0,ZY,640,ZY, 1);	     {draw X and Y axes}
   DRAW(ZX,0,ZX,200, 1);

   IF (L > 0.0)  AND (B > 0.0)	THEN	{if origin off screen}
   BEGIN ZX:=639;ZY:=199 END;		{set it to edge to retain grid marks}
   FOR J:=-10 TO 10 DO	   {draw grid marks starting at origin}
   BEGIN
      DRAW(ZX+64*J,ZY+3,ZX+ 64*J,ZY-3,1);
      DRAW(ZX+5,ZY+20*J,ZX-5,ZY+20*J,1);
   END;
 END;  {procedure drawgrid}

PROCEDURE  DRAWTEXT;
BEGIN
   IF AXIS = 4 THEN
   BEGIN XOLD0:= X[1]; YOLD0:= Y[1] END;
   GOTOXY(1,1); 	       {display plot parameters}
   WRITELN('A = ',A:5:4);
   WRITELN;
   WRITELN('INITIAL ORBIT:');
   WRITELN('X0,Y0 = ',XOLD0:DECN:DECN-1,',',YOLD0:DECN:DECN-1);
   WRITELN;
   IF AXIS <> 4 THEN
   BEGIN
      WRITELN('INCREMENT ALONG:');
      CASE AXIS OF
	 1: WRITELN('AXIS OF SYMMETRY');
	 2: WRITELN('X AXIS');
	 3: WRITELN('AXIS OF CHOICE');
      END;
    END
    ELSE
    WRITELN('ORBITS FROM ARRAYS');
    WRITELN;
    IF (RESPON <> 2) AND (RESPONSE <> 8) THEN WRITELN('INCREMENT DXY = ',DXY:DECN:DECN-1);
    GOTOXY(1,14);
    IF GRD THEN
    BEGIN
       WRITELN('X SCALE: ',L:DECN:DECN-1,' TO ',R:DECN:DECN-1);
       WRITELN('Y SCALE: ',B:DECN:DECN-1,' TO ',T:DECN:DECN-1);
       WRITELN('XGRID MARK: ',(R-L)/(640/64):DECN:DECN-1);
       WRITELN('YGRID MARK: ', (T-B)/(200/20):DECN:DECN-1);
    END;
    GOTOXY(1,20);
    WRITELN('PRESS ANY KEY TO ADVANCE ORBITS MANUALLY');
END; {procedure drawtext}
									  
PROCEDURE PLOTORBITS;

CONST  MAXREAL: REAL = 1E+30;

VAR
  P1,P2:INTEGER;

BEGIN
SINB:= SIN(BETA); COSB:= COS(BETA);
SINA:=SIN(A);COSA:= COS(A);
FOR J:= 1 TO ORBITN  DO   {generate starting points Xold0,yold0 for each orbit}
BEGIN
   GOTOXY(1,11);
   IF TXT THEN
   WRITELN('ORBIT #',J, ' OF ',ORBITN,':');
   IF AXIS = 4 THEN
   BEGIN XOLD0:= X[J]; YOLD0:= Y[J] END;  {use arrays in no-axis option}
   IF J <= MAXORBIT THEN
   BEGIN X[J]:= XOLD0; Y[J]:= YOLD0 END;  {update matrix}
   IF TXT THEN
   WRITELN('X0,Y0 = ', XOLD0:DECN:DECN-1, '  ',YOLD0:DECN:DECN-1);
   XOLD:= XOLD0; YOLD:= YOLD0;	 {set starting point to xold0,yold0}
   IF MARK THEN {draw a mark at the initial point XOLD0,YOLD0}
   BEGIN
      P1:= ROUND((XOLD-L)*XSCALE); P2:= ROUND((T- YOLD)*YSCALE);
      FOR K:= -2 TO 2  DO
      BEGIN
	 PLOT(P1+K,P2,1);
	 PLOT(P1,P2+K,1)
      END;
      IF RESPONSE= 8 THEN  {for merged plots use two values of POINTS}
      IF J > PREVIOUS.RORBITN THEN POINTS:=STORED.RPOINTS;

  END;
  I:= 1;
  WHILE I <= POINTS DO
  BEGIN

      IF (ABS(XOLD) < MAX) AND (ABS(YOLD) < MAX) THEN  {check for out of range}
      BEGIN
	 XNEW:=  XOLD*COSA -(YOLD-XOLD*XOLD)*SINA;  {The Henon mapping}
	 YNEW:=  XOLD*SINA + (YOLD-XOLD*XOLD)*COSA;
	 IF (ABS(XNEW-L) < MAXINT/XSCALE) AND (ABS(T-YNEW) < MAXINT/YSCALE) THEN
	 BEGIN
	    P1:= ROUND((XNEW-L)*XSCALE);  {scale the new point for plotting}
	    P2:= ROUND((T-YNEW)*YSCALE);
	    PLOT(P1,P2,1);
	 END;
	 XOLD:= XNEW;
	 YOLD:= YNEW;
  END;
	 IF KEYPRESSED THEN I:= POINTS+1 ELSE I:= I+ 1;
  END;	{WHILE I. End of orbit plot}

   XOLD0:= XOLD0 + COSB*DXY; {increment along chosen axis}
   YOLD0:= YOLD0 + SINB*DXY;

END;  {For J. Start next orbit}
END;  {procedure plotorbits}
									   

PROCEDURE MENU;

VAR
   FIL: FILE;  {untyped file for storing screen images}
   FIL2: TEXT; {text file for storing parameters}
   PICNAME,FNAME: STRING[14];
   MNU: BOOLEAN;

BEGIN
   MNU:= TRUE;
   GETPIC(BUFFER,0,0,639,199); {store screen in buffer}
   WITH CURRENT DO    {save plot parameters in record CURRENT}
   BEGIN
      RA:= A;RAXIS:= AXIS;RXOLD0:= X[1];RYOLD0:= Y[1];
      RDXY:= DXY;RORBITN:= ORBITN;RPOINTS:= POINTS;RL:=L;
      RR:= R;RB:= B; RT:= T;
      FOR K:= 1 TO MAXORBIT DO
      BEGIN
	 RX[K]:= X[K]; RY[K]:= Y[K];
      END;
    END;

 WHILE MNU DO
 BEGIN
   RESPONSE:= 0;
   GOTOXY(1,19);
   FOR I:= 1 TO 6 DO WRITELN(BLANKLINE);
   GOTOXY(1,19);
   WRITELN('SELECT ONE: (F1) NEW PLOT (CARRIGE RETURNS WILL REPEAT CURRENT VALUES)');
   WRITELN('(F2) REVISE ORBITS OF CURRENT PLOT        (F3) RESTORE PREVIOUS PLOT');
   WRITELN('(F4) SAVE PARAMETERS OF CURRENT PLOT      (F5) SAVE SCREEN OF CURRENT PLOT');
   WRITELN('(F6) RETRIEVE STORED PARAMETERS           (F7) RETRIEVE STORED SCREEN  ');
   WRITELN('(F8) MERGE CURRENT PLOT WITH STORED PLOT  (F9) CHANGE OPTIONS  (F10) QUIT');
   REPEAT UNTIL KEYPRESSED;	{detect whether any of the 10 function keys are pressed}
   READ(KBD,CH);
   IF (CH = #27) AND KEYPRESSED THEN  READ(KBD,CH);  {function keys generate two characters}

   CASE CH OF
	#59: BEGIN     {F1 pressed- New Plot}
      RESPONSE:= 1;
	     MNU:= FALSE; {do not repeat menu}
	     PREVIOUS:= CURRENT;   {save current parameters}
	     XOLD0:=X[1];YOLD0:= Y[1];
	  END;
	#60: BEGIN
      RESPONSE:= 2;    {F2 pressed-Modify orbits}
	     MNU:= FALSE; {do not repeat menu}
	     PREVIOUS:= CURRENT;
	     AXIS:= 4;
	  END;								    

	#61: BEGIN     {F3 pressed-restore previous plot}

       RESPONSE:= 3;
	      MNU:= FALSE;
	      WITH PREVIOUS DO
	      BEGIN
		 A:= RA;AXIS:= RAXIS;XOLD0:=RXOLD0;YOLD0:= RYOLD0;
		 DXY:= RDXY; ORBITN:= RORBITN;POINTS:= RPOINTS;
		 L:= RL;R:=RR;B:=RB;T:=RT;
		 FOR K:= 1 TO MAXORBIT DO
		 BEGIN
		    X[K]:= RX[K]; Y[K]:= RY[K];
		 END;
	      END;
	      PREVIOUS:= CURRENT;
	    END;
	#62: BEGIN
       RESPONSE:= 4;   {F4 pressed-save plot parameters in text file}
	      MNU:= TRUE;
       TEMP:= DECN; {to restore current decimal places}
	      DECN:= 16;  {change this to 11 without 8087 support}
	      GOTOXY(1,23);WRITE(BLANKLINE);GOTOXY(1,23);
	      WRITE('INPUT NAME OF FILE TO CONTAIN PARAMETERS    ');READ(FNAME);
	      ASSIGN(FIL2, FNAME); REWRITE(FIL2);
	      WRITELN(FIL2,A:DECN:DECN-1);WRITELN(FIL2,AXIS);WRITELN(FIL2,X[1]:DECN:DECN-1);
	      WRITELN(FIL2,Y[1]:DECN:DECN-1);WRITELN(FIL2,DXY:DECN:DECN-1);WRITELN(FIL2,ORBITN);
	      WRITELN(FIL2,POINTS);WRITELN(FIL2,L:DECN:DECN-1);WRITELN(FIL2,R:DECN:DECN-1);
	      WRITELN(FIL2,B:DECN:DECN-1);WRITELN(FIL2,T:DECN:DECN-1);
	      FOR K:= 1 TO MAXORBIT DO	WRITELN(FIL2,X[K]:DECN:DECN-1,' ',Y[K]:DECN:DECN-1);
			     {use formatted write for compatability without 8087}
			     {note single space between X[K] & Y[K]-seems necessary}
			     {for Pascal to read these properly}
	      CLOSE(FIL2);
       DECN:= TEMP;
	   END;
	#63: BEGIN
       RESPONSE:= 5;   {F5 pressed-save graphics plot in untyped file}
	      MNU:= TRUE;
	      GOTOXY(1,23); WRITE(BLANKLINE);GOTOXY(1,23);
	      WRITE('INPUT NAME OF FILE TO CONTAIN PLOT    ');READ(PICNAME);
	      ASSIGN(FIL,PICNAME); REWRITE(FIL);
	      BLOCKWRITE(FIL,BUFFER,127);  CLOSE(FIL);
	      GOTOXY(1,18) ; WRITELN('COPY COMPLETE.PLEASE CHOOSE FROM MENU');
	   END;
	#64: BEGIN
       RESPONSE:= 6;	{F6 pressed-retrieve stored parameters}
	      MNU:= FALSE;
	      PREVIOUS:= CURRENT;  {save old parameters}
	      GOTOXY(1,23);WRITE(BLANKLINE);GOTOXY(1,23);
	      WRITE('INPUT NAME OF FILE WHERE PARAMETERS ARE STORED     ');
	      READLN(FNAME);
	      ASSIGN(FIL2,FNAME);RESET(FIL2);
	      READLN(FIL2,A); READLN(FIL2,AXIS); READLN(FIL2,XOLD0);
	      READLN(FIL2,YOLD0);READLN(FIL2,DXY);READLN(FIL2,ORBITN);
	      READLN(FIL2,POINTS);READLN(FIL2,L);READLN(FIL2,R);
	      READLN(FIL2,B);READLN(FIL2,T);
	      FOR K:= 1 TO MAXORBIT DO	READLN(FIL2,X[K],Y[K]);
	      CLOSE(FIL2);
       IF ORBITN <= MAXORBIT THEN AXIS:= 4 ;  {use existing arrays}
	      WITH CURRENT DO	 {store plot parameters in record CURRENT}
	      BEGIN
		 RA:= A;RAXIS:= AXIS;RXOLD0:= X[1];RYOLD0:= Y[1];
		 RDXY:= DXY;RORBITN:= ORBITN;RPOINTS:= POINTS;RL:=L;
		 RR:= R;RB:= B; RT:= T;
		 FOR K:= 1 TO ORBITN DO
		 BEGIN
		    RX[K]:= X[K];RY[K]:= Y[K];
		 END;
	      END;
	   END; 						  
	#65: BEGIN     {F7 pressed-retrieve graphics screen}
       RESPONSE:= 7;
	      GOTOXY(1,23); WRITE(BLANKLINE);GOTOXY(1,23);
	      WRITE('INPUT NAME OF FILE WHERE SCREEN IS STORED     ');
	      READLN(PICNAME);
	      ASSIGN(FIL,PICNAME);RESET(FIL);BLOCKREAD(FIL,BUFFER,127);
       HIRES;HIRESCOLOR(0);
	      PUTPIC(BUFFER,0,199); CLOSE(FIL);
	      GOTOXY(1,23);
	      WRITELN('TO MODIFY THIS PLOT,ENTER THE PARAMETERS USING ITEM(1) OF THE MENU');
	      WRITE('PRESS ANY KEY TO CONTINUE');
	      REPEAT UNTIL KEYPRESSED;
	   END;

	#66: BEGIN
	RESPONSE:= 8;	{F8 pressed-merge orbits of current plot with stored plot}
	       MNU:=FALSE;
	       PREVIOUS:= CURRENT;
	       GOTOXY(1,23);WRITE(BLANKLINE);GOTOXY(1,23);
	       WRITE('INPUT NAME OF FILE WHERE PARAMETERS ARE STORED   ');
	       READLN(FNAME);
	       ASSIGN(FIL2,FNAME);RESET(FIL2);
	       WITH STORED DO	{put parameters in record STORED}
	       BEGIN
		  READLN(FIL2,RA); READLN(FIL2,RAXIS); READLN(FIL2,RXOLD0);
		  READLN(FIL2,RYOLD0);READLN(FIL2,RDXY);READLN(FIL2,RORBITN);
		  READLN(FIL2,RPOINTS);READLN(FIL2,RL);READLN(FIL2,RR);
		  READLN(FIL2,RB);READLN(FIL2,RT);
		  FOR K:= 1 TO MAXORBIT DO READLN(FIL2,RX[K],RY[K]);
		  CLOSE(FIL2);

		  FOR K:= 1 TO	(MAXORBIT-ORBITN) DO  {merge arrays-including}
		  BEGIN 			    {any zero elements}
		     X[ORBITN+K]:= RX[K];Y[ORBITN +K]:= RY[K];
		  END;

		  IF ORBITN+RORBITN <MAXORBIT THEN
		  ORBITN:=ORBITN+RORBITN ELSE ORBITN:= MAXORBIT;
		END;  {with stored}
		AXIS:= 4;

	    END;
	#67: BEGIN    {F9 pressed-change options such as TEXT,GRID,MARK}
	       RESPONSE:= 9;
	       DISPLAYOPTIONS;
	       CHANGEOPTIONS
	    END;
	#68: BEGIN   {F10 pressed-quit}
		RESPONSE:= 10;
		MNU:=FALSE;
	     END;
      END;  {Case}
    END; {while}
 END;  {procedure menu}

								   
BEGIN  {main program}

   GRD:= TRUE; MARK:= TRUE;TXT:= TRUE;MEN:= TRUE;    {defaults}
   L:=-1.2;R:= 1.2; B:= -1.2; T:= 1.2;
   ORBITN:=25; POINTS:= 500;DECN:= 5;
   BLANKLINE:= '                                                                               ';
   FOR K:= 1 TO 40 DO BEGIN X[K]:= 0.0; Y[K]:= 0.0;XL[K]:= 0.0;YL[K]:= 0.0 END;
   A:= 1.111; RESPONSE:= 0;
   AXIS:= 1;XOLD0:=0.098;YOLD0:=0.061; DXY:= 0.05;

   INTRO;
   REPEAT

      DISPLAYDATA;
      IF CHANGE THEN
      OBTAINDATA;
      HIRES; HIRESCOLOR(0);
      IF GRD THEN
      DRAWGRID;
      IF TXT THEN
      DRAWTEXT;
      PLOTORBITS;
      IF MEN THEN
      MENU
      ELSE
      BEGIN
	GOTOXY(1,24);WRITELN('PRESS ANY KEY FOR MENU');
	REPEAT UNTIL KEYPRESSED;
	MENU
      END;

   UNTIL RESPONSE = 10;
END.
