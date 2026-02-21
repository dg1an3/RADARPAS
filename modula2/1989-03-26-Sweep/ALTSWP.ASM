; SWEEP LINE
; Check to see if new increment data needs to be loaded
;Loop2&N:  DEC CH                        ; Next increment bit          2
;          JNZ WrData2&N                 ;                             4/16
;          DEC SI                        ; Decrement data pointer      2
;          DEC SI                        ;                             2
;          XOR AH,AH                     ; Set AH=0                    3
;          MOV BX,OFFSET RotTable-127    ; Set up the translation      4
;          ADD BX,AX                     ;  table to get rotation      3
;          MOV CL,ES:[BX]                ;  for radar data             16
;          MOV BX,ES:[SI+OFFSET RadData] ; Get radar data              19
;          ROR BX,CL                     ; Rotate to proper position   15
;          MOV DX,ES:[SI+OFFSET XInc]    ; Get the next XInc word      19
;          MOV BP,ES:[SI+OFFSET YInc]    ; Get the next YInc word      19
;          MOV CH,16                     ; Set up the screen counter   4
;                                        ;                      TOTAL  110 (Reload Inc)
;
;
;
;   
;    
;     
;                                        ;           CLOCKS TO ARRIVE  18     
;WrData2&N:RCR DX,1                      ; Check for X increment       2     
;          JNC NoIncX&N                  ; No                          4/16     
;          RCR BP,1                      ; Check for Y increment       2  
;          JNC IncX&N                    ; No                          4/16     
;; Case 1: X and Y both need to be incremented     
;          OR AL,CL                      ; Set screen data bit         3     
;          MOV [DI],AL                   ; Write screen data           14     
;          RCR CL,1                      ; Dec screen bit counter      2     
;          JC IncDI2&N                   ; If zero, move diagonally    4/16     
;          ADD DI,80                     ; Screen data above           4     
;          MOV AL,[DI]                   ; Set EGA register            13     
;          MOV CL,0F0H                   ; Reset screen bit counter    4     
;          XOR AL,AL                     ; Clear screen data           3     
;          JMP Loop2&N                   ; Loop                        15     
;                                        ;                      TOTAL  91 (X+,Y+)    
;
;     
;                                        ;           CLOCKS TO ARRIVE  77     
;IncDI2&N: ADD DI,81                     ; Screen data above and to right 4
;          MOV AL,[DI]                   ; Set EGA register            13     
;          XOR AL,AL                     ; Clear                       3     
;          JMP Loop2&N                   ; Loop                        15     
;                                        ;                      TOTAL  112 (X+,Y+,DI+)
;
; 
;  
;   
;    
;  
;                                        ;           CLOCKS TO ARRIVE  36     
;NoIncX2&N:RCR BP,1                      ; Check for Y increment       2     
;          JNC Loop2&N                      ; No, do nothing              4/16     
;; Case 2: Y needs to be incremented     
;          OR AL,CL                      ; Set screen data bit         3     
;          MOV [DI],AL                   ; Write screen data           14     
;          ADD DI,80                     ; Screen data above           4     
;          MOV AL,[DI]                   ; Get next screen byte        13     
;          XOR AL,AL                     ; Rotate to position          3     
;          JMP Loop2&N                   ; Loop                        15     
;                                        ;                      TOTAL  94 (Y+)     
;     
;; Case 3: X needs to be incremented                 CLOCKS TO ARRIVE  42
;IncX2&N:  OR AL,CL                      ; Load next radar data bit    3     
;          RCR CL,1                      ; Dec screen bit counter      2     
;          JNC Loop2&N                   ; If not zero, just loop      4/16     
;                                        ;                      TOTAL  63  (X+)     
;                                        ;     
;          MOV [DI],AL                   ; Write screen data           14     
;          INC DI                        ; Screen data to the right    2     
;          MOV AL,[DI]                   ; Get next screen byte        13     
;          MOV CL,0F0H                   ; Reset bit counter           4     
;          XOR AL,AL                     ; Rotate to position          3  
;          JMP Loop2&N                   ; Loop                        15     
;                                        ;                      TOTAL  102  (X+,DI+) 
;
; 
;  
;   
;     
;; CASE      TIME  FREQ     
;; -------------------------     
;; X+,Y+      91 x 21.875% = 19.90625     
;; X+,Y+,DI+ 112 x  3.125% =  3.5     
;; Y+         94 x 25.000% = 23.5     
;; X+         63 x 21.875% = 13.78125
;; X+,DI+    102 x  3.125% =  3.1875     
;; none       54 x 25.000% = 13.5     
;; Load Inc  110 x  6.250% =  6.875     
;;                   TOTAL = 84.25 x 256 = 21568     
;     
;; This is the routine which loads the next word of data from     
;; memory.  It is only called for every 16 pixels processed,     
;; so its time is multiplied by 16 (256/16) to calculate the     
;; time it takes to process a complete 256 bit line of data.     
;Loop3&N:  DEC SI                        ; Set pointer to next word    2     
;          DEC SI                        ;                             2     
;          JNE Cont&N                    ; If not zero, continue       4/16  
;     
;          MOV AX,ES                     ; Restore DS register to data segment     
;          MOV DS,AX     
;          RET                           ; Return     
;     
;Cont&N:   XOR AH,AH                     ; Set AH=0                    3     
;          MOV BX,OFFSET RotTable-127    ; Set up the translation      4     
;          ADD BX,AX                     ;  table to get rotation      3     
;          MOV CL,ES:[BX]                ;  for radar data             16     
;          MOV BX,ES:[SI+OFFSET RadData] ; Get radar data              19     
;          ROR BX,CL                     ; Rotate to proper position   15
;          MOV DX,ES:[SI+OFFSET XInc]    ; Get the next XInc word      19     
;          MOV BP,ES:[SI+OFFSET YInc]    ; Get the next YInc word      19     
;          MOV CH,16                     ; Set up the screen counter   4     
;                                        ;                      TOTAL  110     
;     
;          RCR DX,1                      ; Check for X increment       2     
;          JNC NoIncX&N                  ; No                          4/16     
;          RCR BP,1                      ; Check for Y increment       2     
;          JNC IncX&N                    ; No                          4/16     
;          ; This is case 1 : Both X and Y need to be incremented     
;          RCR BX,1                      ; Transfer the next bit to    2     
;          RCL AL,1                      ; the screen byte.            2  
;          DEC CL                        ; Decrease the screen counter 2     
;          JZ IncDI3&N                   ; See if screen data is gone  4/16     
;          ROR AL,CL                     ; Yes, rotate screen data     13     
;          MOV [DI],AL                   ; and write it                14     
;          ADD DI,81                     ; Increment DI diagonally     4     
;          MOV AL,[DI]                   ; Get next screen byte        13     
;          RCR AL,CL                     ; Rotate to proper position   13     
;          DEC CH                        ; One less increment bit      3     
;          JNZ WrData&N                  ; Out of increment bits?      16     
;          JMP Loop3&N                   ; Yes, load the next word     
;
;          ; This is the routine to increment X and Y, and increment DI too     
;IncDI3&N: MOV [DI],AL                   ;                             14     
;          ADD DI,80                     ;                             4     
;          MOV AL,[DI]                   ;                             13     
;          DEC CH                        ; One less increment bit      3     
;          JNZ WrData&N                  ; Out of increment bits?      16     
;          JMP Loop3&N                 ; Yes, load the next word     
;     
;          ; Took 18 clocks to get here     
;NoIncXY&N:     
;; This routine does the processing for every pixel, so its time     
;; is multiplied by 256.  
;WrData3&N:MOV AH,[DI]                   ; Get the screen data         13     
;          AND AH,AL                     ; AND with screen mask        3     
;          MOV CH,AL                     ; Get the screen mask         2     
;          NOT CH                        ; Invert it                   3     
;          AND CH,BL                     ; AND it with radar data      3     
;          OR  CH,AH                     ; Radar bit OR screen data    2     
;          MOV [DI],CH                   ; Write back to screen        14     
;          OR [DI],CH     
;     
;          RCR DX,1                      ; Check the next XInc bit     2     
;          JNC NoIncX&N                  ; Increment the X?            4/16
;IFIDN     <&XDir>,<+>     
;          ROR BX,1                      ; Yes, rotate radar data      2     
;          ROR AL,1                      ; Rotate screen mask          2     
;ELSE     
;          ROL BX,1                      ; Yes, rotate radar data      2     
;          ROL AL,1                      ; Rotate screen mask          2     
;ENDIF     
;          JNC IncDI&N                   ; Need to increment byte?     4/16     
;     
;NoIncX3&N:RCR BP,1                      ; Check the next YInc bit     2     
;          JNC NoIncY&N                  ; Increment the Y?            4/16     
;IFIDN     <&YDir>,<+>  
;          ADD DI,80                     ; Yes, do it                  4     
;ELSE     
;          SUB DI,80     
;ENDIF     
;     
;NoIncY&N: ROL BX,1                      ; Move to next radar bit      2     
;          DEC CL                        ; Decrease counter            2     
;          JNZ WrData&N                  ; Used all 16 data bits?      4/16     
;          JMP Loop&N                    ; Yes, load new ones          15     
;                                        ;                      TOTAL  96     
;
;; This routine moves to the next byte horizontally.  Since it     
;; is only called for every eight bits processed, its time is     
;; multiplied by 32 (256/8) to calculate the time it requires.     
;; Note that 12 is added to the time, as this is the time it     
;; takes to jump into this routine from the JNC instruction right     
;; before label "NoIncX".                                              12     
;IncDI4&N:     
;IFIDN     <&XDir>,<+>     
;          INC DI                        ;                             2     
;ELSE     
;          DEC DI     
;ENDIF  
;          XCHG BH,BL                    ;                             4     
;                                        ;                       TOTAL 18     
;     
;; This is a repeat of the above routine.  This saves the 15 clock cycles     
;; to jump back into the above routine.     
;          RCR BP,1                      ; Check the next YInc bit     2     
;          JNC NoIncY2&N                 ; Increment the Y?            4/16     
;IFIDN     <&YDir>,<+>     
;          ADD DI,80                     ; Yes, do it                  4     
;ELSE     
;          SUB DI,80
;ENDIF     
;     
;     
;NoIncY2&N:ROL BX,1                      ; Move to next radar bit      2     
;          DEC CL                        ; Decrease counter            2     
;          JNZ WrData&N                  ; Used all 16 data bits?      4/16     
;          JMP Loop&N                    ; Yes, load new ones          15     
;                                        ;                      TOTAL  96  
;                                        ;  
;                                        ;  
;                                        ;              110 x  16 =  1760  
;                                        ;               96 x 256 = 24576  
;                                        ;               18 x  32 =   576  
;                                        ;                          -----  
;                                        ;              TOTAL TIME  26912  
