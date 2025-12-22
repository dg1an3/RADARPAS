	  TITLE Sweep -- High-Performance Radar Sweep Routine
	  SUBTITLE Author: DGL  Date: July 15, 1987
	  PAGE 60,132
	  .SALL

SweepOn   = 0

DataSeg   SEGMENT PARA 'DATA'
Palette   DB 00H,24H,32H,36H,3FH,3FH,3FH,3FH
          DB 09H,09H,09H,09H,09H,09H,09H,09H

RadData   DB 32 DUP(?)                  ; Current radar data in use
XInc      DB 32 DUP(?)                  ; Current X increment data
YInc      DB 32 DUP(?)                  ; Current Y increment data
                                        ; Note that the above three
                                        ; tables are loaded backwards -
                                        ;   Word 0 is at +30,
                                        ;   Word 1 is at +28, etc.
RedData   DB 11 DUP(0FFH)               ; Red data
          DB 11 DUP(0FFH)
          DB 10 DUP(0FFH)

GrnData   DB 11 DUP(0FFH)               ; Green data
          DB 11 DUP(0FFH)
          DB 10 DUP(0FFH)

RotTable  DB 64 DUP(0) ; 01111111 = 0     Rotate table
          DB 32 DUP(1) ; 10111111 = 1
          DB 16 DUP(2) ; 11011111 = 2
          DB 8 DUP(3)  ; 11101111 = 3
          DB 4 DUP(4)  ; 11110111 = 4
          DB 2 DUP(5)  ; 11111011 = 5
          DB 6         ; 11111101 = 6
          DB 7         ; 11111110 = 7

NumInc    = 400                           ; Number of entries in inc table
SizeInc   = 32                            ; Size of each inc table entry

CurrInc   DW 100                          ; Counter of current increment table
					  ; entrys

CurrDir   DW SizeInc                      ; Direction of sweep
                                          ;  SizeInc = clockwise
                                          ; -SizeInc = counterclockwise

          EXTRN IncTableX:NEAR            ; X increment table
          EXTRN IncTableY:NEAR            ; Y increment table

CurrDraw  DW ?

SweepCount DB ?
PrevSweep DW ?

DataSeg   ENDS

StackSeg  SEGMENT PARA STACK 'STACK'
          DW 512 DUP(?)
StackSeg  ENDS

Sweep     MACRO N,XDir,YDir
;; Macro which expands into code to draw one radial.  The first parameter
;; specifies the number to use for labels.  The last two parameters can
;; be either '+' or '-', to specify for x and y whether to increment or
;; decrement.  On entry, it assumes that AX contains the offset to the
;; appropriate entry in the increment table.

          ; Move the X increment data to data area
          MOV SI,OFFSET IncTableX
          ADD SI,CurrInc
          MOV DI,OFFSET XInc            ; Load the destination pointer
          MOV CX,16D                    ; Load the counter
          CLD                           ; Clear direction flag
          REP MOVSW                     ; Move the data
          ; Move the Y increment data to data area
          MOV SI,OFFSET IncTableY
          ADD SI,CurrInc                ; Load the source pointer
          MOV DI,OFFSET YInc            ; Load the destination pointer
          MOV CX,16D                    ; Load the counter
          REP MOVSW                     ; Move the data

          ; Transfer red data to data area
          MOV SI,OFFSET RedData         ; Load the source pointer
          MOV DI,OFFSET RadData         ; Load the destination pointer
          MOV CX,16D                    ; Load the counter
          REP MOVSW                     ; Move the data

          ; Set the red plane for writing
          MOV DX,3C4H                   ; Port[3C4H] = 02H Write Map Select
          MOV AL,02H
          OUT DX,AL
          MOV DX,3C5H                   ; Port[3C5H] = 0001B
          MOV AL,0001B
          OUT DX,AL
          ; Set the red plane for reading
          MOV DX,3CEH                   ; Port[3CEH] = 04H Read Map Select
          MOV AL,04H
          OUT DX,AL
          MOV DX,3CFH                   ; Port[3CFH] = 00H
          MOV AL,00H
          OUT DX,AL
          CALL DrawRad&N

          ; Transfer green data to data area
          MOV SI,OFFSET GrnData         ; Load the source pointer
          MOV DI,OFFSET RadData         ; Load the destination pointer
          MOV CX,16D                    ; Load the counter
          REP MOVSW                     ; Move the data

          ; Set the green plane for writing
          MOV DX,3C4H                   ; Port[3C4H] = 02H Write Map Select
          MOV AL,02H
          OUT DX,AL
          MOV DX,3C5H                   ; Port[3C5H] = 0010B
          MOV AL,0010B
          OUT DX,AL
          ; Set the green plane for reading
          MOV DX,3CEH                   ; Port[3CEH] = 04H Read Map Select
          MOV AL,04H
          OUT DX,AL
          MOV DX,3CFH                   ; Port[3CFH] = 01H
          MOV AL,01H
          OUT DX,AL
          CALL DrawRad&N

          MOV AX,DataSeg
          MOV DS,AX
          RET


; DrawRad does the actual drawing of the radial.
; REGISTER ASSIGNMENTS:
;   AL = Current screen word
;   BX = Current radar data word
;   CH = Increment counter
;   CL = Screen counter
;   DX = Current X increment word
;   BP = Current Y increment word
;   ES:[SI] = Radar data entry
;   DS:[DI] = Screen position
;
; On entry, assumed ES=DS
;
DrawRad&N:MOV AX,0A000H                 ; Set the DS register to the
          MOV DS,AX                     ;   video segment
          MOV SI,32D                    ; Set the entry counter
          MOV DI,Center                 ; Set the first screen position
IFIDN     <XDir>,<+>
          MOV CL,CentBit                ; Set the first bit
ELSE
          MOV CL,17-CentBit             ; Set the first bit
ENDIF

;          MOV AL,CentMask               ;   and mask
          MOV AX,[DI]                   ; Set the current screen word
;          XCHG AH,AL
IFIDN     <&XDir>,<+>
          RCL AX,CL
ELSE
          RCR AX,CL
ENDIF
          MOV CH,1                      ; Set up the data counter to
                                        ;   load new data immediately

; Check to see if new increment data needs to be loaded
Loop&N:   DEC CH                        ; Next increment bit          2
          JNZ WrData&N                  ;                             4/16
          DEC SI                        ; Decrement data pointer      2
          DEC SI                        ;                             2
          JZ EndLoop&N                  ; Jump to exit
;          XOR AH,AH                     ; Set AH=0                    3
;          MOV BX,OFFSET RotTable-127    ; Set up the translation      4
;          ADD BX,AX                     ;  table to get rotation      3
;          MOV CL,ES:[BX]                ;  for radar data             16
          MOV BX,ES:[SI+OFFSET RadData] ; Get radar data              19
;          ROR BX,CL                     ; Rotate to proper position   15
          MOV DX,ES:[SI+OFFSET XInc]    ; Get the next XInc word      19
          MOV BP,ES:[SI+OFFSET YInc]    ; Get the next YInc word      19
          MOV CH,16                     ; Set up the data counter     4
                                        ;                      TOTAL  110 (Reload Inc)







                                        ;           CLOCKS TO ARRIVE  18
WrData&N: RCR DX,1                      ; Check for X increment       2
          JNC NoIncX&N                  ; No                          4/16
          RCR BP,1                      ; Check for Y increment       2
          JNC IncX&N                    ; No                          4/16
; Case 1: X and Y both need to be incremented
          RCR BX,1                      ; Load next radar data bit    2
IFIDN     <&XDir>,<+>
          RCL AX,CL
          DEC CL                        ; Dec screen bit counter      2
ELSE
          RCR AX,CL
          DEC CL                        ; Dec screen bit counter      2
ENDIF
          JZ IncDI&N                    ; If zero, move diagonally    4/16

          XCHG AH,AL
          MOV [DI],AX                   ; Write screen data           14
IFIDN     <&YDir>,<+>
          ADD DI,80D                    ; Screen data below           4
ELSE
          SUB DI,80D                    ; Screen data above           4
ENDIF
          MOV AX,[DI]                   ; Get next screen byte        13
          XCHG AH,AL
IFIDN     <&XDir>,<+>
          RCR AX,CL                     ; Rotate to position          2
ELSE
          RCL AX,CL                     ; Rotate to position          2
ENDIF
          JMP Loop&N                    ; Loop                        15
                                        ;                      TOTAL  103 (X+,Y+)

                                        ;           CLOCKS TO ARRIVE  77
IncDI&N:
IFIDN     <&YDir>,<+>

IFIDN     <&XDir>,<+>
          ADD DI,82D
ELSE
          ADD DI,78D
ENDIF

ELSE

IFIDN     <&XDir>,<+>
          SUB DI,78D
ELSE
          SUB DI,82D
ENDIF

ENDIF
          MOV AX,[DI]                   ; Get next screen byte        13
          XCHG AH,AL
IFIDN     <&XDir>,<+>
          RCL AX,1                      ; Rotate to position          13
ELSE
          RCR AX,1                      ; Rotate to position          13
ENDIF

          MOV CL,16                     ; Reset screen bit counter    4
          JMP Loop&N                    ; Loop                        15
                                        ;                      TOTAL  122 (X+,Y+,DI+)






                                        ;           CLOCKS TO ARRIVE  36
NoIncX&N: RCR BP,1                      ; Check for Y increment       2
          JNC Loop&N                    ; No, do nothing              4/16
; Case 2: Y needs to be incremented
          RCR BX,1                      ; Load next radar data bit    2
IFIDN     <&XDir>,<+>
          RCL AX,CL                     ; into the screen data        13
ELSE
          RCR AX,CL                     ; into the screen data        13
ENDIF
          XCHG AH,AL
          MOV [DI],AX                   ; Write screen data           14
          ADD DI,80D                    ; Screen data above           4
          MOV AX,[DI]                   ; Get next screen byte        13
          XCHG AH,AL
IFIDN     <&XDir>,<+>
          RCR AX,CL                     ; Rotate to position          13
ELSE
          RCL AX,CL                     ; Rotate to position          13
ENDIF
          JMP Loop&N                    ; Loop                        15
                                        ;                      TOTAL  116 (Y+)

; Case 3: X needs to be incremented                 CLOCKS TO ARRIVE  42
IncX&N:   RCR BX,1                      ; Load next radar data bit    2
IFIDN     <&XDir>,<+>
          RCL AX,1                      ; into the screen pointer     2
ELSE
          RCR AX,1                      ; into the screen pointer     2
ENDIF
          DEC CL                        ; Dec screen bit counter      2
          JNZ Loop&N                    ; If not zero, just loop      4/16
                                        ;                      TOTAL  64  (X+)
                                        ;
          XCHG AH,AL
          MOV [DI],AX                   ; Write screen data           14
IFIDN     <&XDir>,<+>
          INC DI                        ; Screen data to the right    2
          INC DI
ELSE
          DEC DI                        ; Screen data to the right    2
          DEC DI
ENDIF
          MOV AX,[DI]                   ; Get next screen byte        13
          XCHG AH,AL
IFIDN     <&XDir>,<+>
          RCR AX,1                      ; Rotate to position          2
ELSE
          RCL AX,1                      ; Rotate to position          2
ENDIF
          MOV CL,16                     ; Reset bit counter           4
          JMP Loop&N                    ; Loop                        15
                                        ;                      TOTAL  102  (X+,DI+)

EndLoop&N:RET



; CASE      TIME  FREQ
; -------------------------
; X+,Y+     103 x 21.875% = 22.53125
; X+,Y+,DI+ 122 x  3.125% =  3.8125
; Y+        116 x 25.000% = 29.0
; X+         64 x 21.875% = 14.0
; X+,DI+    102 x  3.125% =  3.1875
; none       54 x 25.000% = 13.5
; Load Inc  110 x  6.250% =  6.875
;                   TOTAL = 92.90625 x 256 = 23784

          ENDM


CodeSeg   SEGMENT PARA 'CODE'

          ASSUME CS:CodeSeg,DS:DataSeg,SS:StackSeg,ES:DataSeg

BEGIN     PROC FAR
          PUSH DS                       ; Set up return stack
          XOR AX,AX
          PUSH AX
          MOV AX,DataSeg                ; Set up DS segment register
          MOV DS,AX
          MOV ES,AX                     ; Set up ES segment register

          ; Set hires (640x350) mode
          MOV AX,0010H     
          INT 10H     
          ; Set read and write modes 0
          MOV DX,3CEH                   ; Port[3CEH] = 05H  
          MOV AL,05H  
          OUT DX,AL     
          MOV DX,3CFH                   ; Port[3CFH] = 00000000B     
          MOV AL,00000000B
          OUT DX,AL     
          ; Set function 00H
          MOV DX,3CEH                   ; Port[3CEH] = 03H     
          MOV AL,03H     
          OUT DX,AL     
          MOV DX,3CFH                   ; Port[3CFH] = 00000000B     
          MOV AL,00000000B     
          OUT DX,AL
     
          ; Set the color palette
          MOV BX,00H                    ; Load counter     
CLoop:    MOV DX,3DAH                   ; Reset EGA attribute controller
          IN AL,DX                      ;   flip-flop     
          MOV DX,3C0H                   ; Load palette address
          MOV AL,BL     
          OUT DX,AL     
          MOV AL,[BX+OFFSET Palette]    ; Load palette value
          OUT DX,AL
          INC BX     
          CMP BX,10H  
          JNE CLoop     
          MOV DX,3DAH     
          IN AL,DX
          MOV DX,3C0H     
          MOV AL,00100000B     
          OUT DX,AL     
     
     
          XOR AX,AX                     ; Set up CurrInc to be -CurrDir
          SUB AX,CurrDir     
          MOV CurrInc,AX
     
          MOV CurrDraw,OFFSET Quad1
     
Loop:     MOV AX,CurrDraw     
          CALL AX     
          MOV AH,06H
          MOV DL,0FFH
          INT 21H
          JZ Loop
          RET
     
BEGIN     ENDP  
     
Center    = 14040D
CentBit   = 16
CentMask  = 01111111B

; **************************************************************
; *                         Q U A D 1                          *
; *                Sweeps from 0 to 89 degrees                 *
; **************************************************************

Quad1     PROC NEAR
          MOV AX,CurrInc
          ADD AX,CurrDir
          MOV CurrInc,AX
          CMP AX,NumInc*SizeInc
          JL Skip1
          MOV CurrDraw,OFFSET Quad2
          JMP Quad2     
     
Skip1:    CMP AX,0     
          JGE Start1     
          MOV CurrDraw,OFFSET Quad4
          JMP Quad4     
     
Start1:   Sweep 1,+,-     
          RET

Quad1     ENDP
     
     
; **************************************************************     
; *                         Q U A D 2                          *     
; *               Sweeps from 90 to 179 degrees                *     
; **************************************************************     
     
Quad2     PROC NEAR
          MOV AX,CurrInc     
          SUB AX,CurrDir     
          MOV CurrInc,AX
          CMP AX,NumInc*SizeInc     
          JL Skip2     
          MOV CurrDraw,OFFSET Quad1
          JMP Quad1     
     
Skip2:    CMP AX,0     
          JGE Start2     
          MOV CurrDraw,OFFSET Quad3
          JMP Quad3     
     
Start2:   Sweep 2,+,+     
          RET

Quad2     ENDP
     
     
; **************************************************************     
; *                         Q U A D 3                          *     
; *               Sweeps from 180 to 269 degrees               *     
; **************************************************************     

Quad3     PROC NEAR     
          MOV AX,CurrInc
          ADD AX,CurrDir     
          MOV CurrInc,AX     
          CMP AX,NumInc*SizeInc     
          JL Skip3     
          MOV CurrDraw,OFFSET Quad4
          JMP Quad4     
     
Skip3:    CMP AX,0     
          JGE Start3     
          MOV CurrDraw,OFFSET Quad2
          JMP Quad2     
     
Start3:   Sweep 3,-,+     
          RET

Quad3     ENDP     
     
     
; **************************************************************     
; *                         Q U A D 4                          *
; *               Sweeps from 270 to 359 degrees               *
; **************************************************************

Quad4     PROC NEAR
          MOV AX,CurrInc
          SUB AX,CurrDir
          MOV CurrInc,AX
          CMP AX,NumInc*SizeInc
          JL Skip4
          MOV CurrDraw,OFFSET Quad3
          JMP Quad3

Skip4:    CMP AX,0
          JGE Start4
          MOV CurrDraw,OFFSET Quad1
          JMP Quad1

Start4:   Sweep 4,-,-
          RET

Quad4     ENDP

CodeSeg   ENDS

          END       BEGIN
