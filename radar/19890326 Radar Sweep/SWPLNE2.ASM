;IF        SweepOn
;          INC SweepCount     
;          CMP SweepCount,4     
;          JB NoSweep&N     
;          ; Set the white plane for writing     
;          MOV DX,3C4H                   ; Port[3C4H] = 02H Write Map Select     
;          MOV AL,02H     
;          OUT DX,AL     
;          MOV DX,3C5H                   ; Port[3C5H] = 0100B     
;          MOV AL,0100B     
;          OUT DX,AL     
;          ; Set the white plane for reading     
;          MOV DX,3CEH                   ; Port[3CEH] = 04H Read Map Select     
;          MOV AL,04H     
;          OUT DX,AL     
;          MOV DX,3CFH                   ; Port[3CFH] = 02H     
;          MOV AL,02H     
;          OUT DX,AL     
;          CALL SweepLn&N  
;     
;          ; Move the X increment data from previous sweep to data area
;          MOV SI,OFFSET IncTableX     
;          ADD SI,PrevSweep     
;          MOV DI,OFFSET XInc            ; Load the destination pointer
;          MOV CX,16D                    ; Load the counter
;          CLD                           ; Clear direction flag
;          REP MOVSW                     ; Move the data
;          ; Move the Y increment data from previous sweep to data area
;          MOV SI,OFFSET IncTableY
;          ADD SI,PrevSweep              ; Load the source pointer
;          MOV DI,OFFSET YInc            ; Load the destination pointer
;          MOV CX,16D                    ; Load the counter
;          REP MOVSW                     ; Move the data
;          CALL SweepLn&N
;
;          MOV AX,CurrInc
;          MOV PrevSweep,AX
;          MOV SweepCount,0
;ENDIF
