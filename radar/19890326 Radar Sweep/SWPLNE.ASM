;; SweepLn draws a sweep line on the display.   
;; REGISTER ASSIGNMENTS:   
;;   AL = Screen mask   
;;   BL = Screen data   
;;   CL = Increment counter   
;;   DX = Current X increment word   
;;   BP = Current Y increment word   
;;   ES:[SI] = Increment entry   
;;   DS:[DI] = Screen position   
;;   
;; On entry, assumed ES=DS   
;;   
;SweepLn&N:MOV AX,0A000H                 ; Set the DS register to
the   
;          MOV DS,AX                     ;   video segment   
;          MOV SI,32D                    ; Set the entry counter 
 
;          MOV DI,Center                 ; Set the first screen
position   
;          MOV AL,080H                   ;   and mask   
;   
;; This is the routine which loads the next word of data from   
;; memory.  It is only called for every 16 pixels processed,   
;; so its time is multiplied by 16 (256/16) to calculate the   
;; time it takes to process a complete 256 bit line of data.   
;SLoop&N:  DEC SI                        ; Set pointer to next word 
  2   
;          DEC SI                        ;                       
     2   
;          JE SExit&N                    ; If zero, quit         
     4/16   
;          MOV DX,ES:[SI+OFFSET XInc]    ; Get the next XInc word 
    19   
;          MOV BP,ES:[SI+OFFSET YInc]    ; Get the next YInc word 
    19   
;          MOV CL,16                     ; Set up the counter    
     4   
;                                        ;                     
TOTAL  50   
;   
;; This routine does the processing for every pixel, so its time 
 
;; is multiplied by 256.   
;SWrData&N:;XOR BL,AL                     ; Perform the operation 
     14   
;   
;          RCR DX,1                      ; Check the next XInc bit 
   2   
;          JNC SNoIncX&N                 ; Increment the X?      
     4/16   
;IFIDN     <&XDir>,<+>   
;          XOR [DI],AL   
;          ROR AL,1                      ; Rotate screen mask    
     2   
;          ADC DI,0                      ; Add the carry bit   
;ELSE   
;          XOR [DI],AL   
;          ROL AL,1                      ; Rotate screen mask    
     2   
;          SBB DI,0                      ; Subtract carry bit   
;ENDIF   
;   
;SNoIncX&N:RCR BP,1                      ; Check the next YInc bit 
   2   
;          JNC SNoIncY&N                 ; Increment the Y?      
     4/16   
;IFIDN     <&YDir>,<+>   
;          XOR [DI],AL   
;          ADD DI,80                     ; Yes, do it            
     4   
;ELSE   
;          XOR [DI],AL   
;          SUB DI,80   
;ENDIF   
;   
;SNoIncY&N:DEC CL                        ; Decrease counter      
     2   
;          JNZ SWrData&N                 ; Used all 16 data bits? 
    4/16   
;          JMP SLoop&N                   ; Yes, load new ones    
     15   
;                                        ;                     
TOTAL  96   
;   
;                                        ;               50 x  16
=  1760   
;                                        ;               96 x 256
= 24576   
;                                        ;               18 x  32
=   576   
;                                        ;                       
  -----   
;                                        ;              TOTAL TIME 
26912   
;   
;SExit&N:  MOV AX,ES                     ; Restore DS register to
data segment   
;          MOV DS,AX   
;          RET   
;   
;          ENDM   
