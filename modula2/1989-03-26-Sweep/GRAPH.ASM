            TITLE Graphics Routines for EGA Card
            PAGE 60,132

RadarData   SEGMENT DATA

RedData1    DB 32 DUP(?) ; Data from first return
GrnData1    DB 32 DUP(?)
RedData2    DB 32 DUP(?) ; Data from second return
GrnData2    DB 32 DUP(?)
RedData3    DB 32 DUP(?) ; Data from third return
GrnData3    DB 32 DUP(?)
AvgRed      DB 32 DUP(?) ; Averaged data, ready to be written
AvgGrn      DB 32 DUP(?)
Return      DB ?         ; Current return
Step        DW ?         ; Current radial step
WriteProc   DW ?         ; Current write procedure

RadarData   ENDS


RadarCode   SEGMENT CODE

Init        PROC FAR
Init        ENDP

RadarInt    PROC NEAR
; Procedure called by an interrupt from the data acquisition board.
; Stores three returns and then processes and writes the data.
            CALL Average
            CALL WriteRadial
            MOV Step,AX
            INC AX
            CMP AX,MaxStep
            MOV AX,Step

RadarInt    ENDP

Average     PROC NEAR
; Averages the three returns stored by RadarInt, storing the averaged
; data in AvgRed and AvgGrn.
Average     ENDP

WriteRadial PROC NEAR
; Writes the current radial, using the data in AvgRed and AvgGrn.
; If SweepOn<>0, then erases the sweep line on the white plane.
WriteRadial ENDP

WriteSweep  PROC NEAR
; If SweepOn<>0, then writes the sweep line on the white plane.
; Regardless of SweepOn, erases the data under the current radial.
WriteSweep  ENDP

