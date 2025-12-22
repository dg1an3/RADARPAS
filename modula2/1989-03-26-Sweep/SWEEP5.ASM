; Register assignment:
;
; AX = Data: Radar (Source)
; BX = Data: Delta proc
; DX = Data: Screen (Dest)
; CX = Screen Rotate Count
; SI = Ptr: Radar (Source)
; DI = Ptr: Screen (Dest)
; BP = Ptr: Delta proc
;
; Init SI, DI, BP, AX, BX, CX, DX
; JumpFunction (BX,BP)
;
; Functions
;
;  Num  Name
;   0   N_N
;   1   N_X
;   2   N_XS
;   3   N_Y
;   4   N_XY
;   5   N_XSY

;   6   X_N
;   7   X_X
;   8   X_XS
;   9   X_Y
;   10  X_XY
;   11  X_XSY

;   12  XS_N
;   13  XS_X
;   14  XS_XS
;   15  XS_Y
;   16  XS_XY
;   17  XS_XSY

;   18  Y_N
;   19  Y_X
;   20  Y_XS
;   21  Y_Y
;   22  Y_XY
;   23  Y_XSY

;   24  XY_N
;   25  XY_X
;   26  XY_XS
;   27  XY_Y
;   28  XY_XY
;   29  XY_XSY


;   30  XSY_N
;   31  XSY_X
;   32  XSY_XS
;   33  XSY_Y
;   34  XSY_XY
;   35  XSY_XSY

;   36  LoadRadarData
;   37  EndRadial

PlotRadPt MACRO                        ; Plots the next radar point
          RCX AX,1
          RCX DX,1
          ENDM

NextWord  MACRO Rot,Dir                ; Writes the current word and
                                       ; moves to the next one.
                                       ; Dir: -82D = NW
                                       ;      -80D = N
                                       ;      -78D = NE
                                       ;      -2D  = W
                                       ;      2D   = E
                                       ;      78D  = SW
                                       ;      80D  = S
                                       ;      82D  = SE
IF        Rot = 1

ELSE

ENDIF
          MOV [DI],DX
          ADD DI,Dir

Inc       MACRO XDir, YDir, ScrPtr

IFIDN <YDir>,<+>                       ; ---*
                                       ;    |
IFIDN <XDir>,<+>                       ; -* |
                                       ;  | |
ELSE                                   ; -* |
                                       ;  | |
END IFIDN                              ; -* |
                                       ;    |
ELSE                                   ; ---*
                                       ;    |
IFIDN <XDir>,<+>                       ; -* |
                                       ;  | |
ELSE                                   ; -* |
                                       ;  | |
END IFIDN                              ; -* |
                                       ;    |
ENDIF                                  ; ---*