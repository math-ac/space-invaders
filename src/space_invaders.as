; Space Invaders implementation using the P3 Assembly
; Author: Matheus A. Constancio
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; General purpose constants
;------------------------------------------------------------------------------
SPACE           EQU     32d ; Space character
IO_READ         EQU     FFFFh
IO_WRITE        EQU     FFFEh
IO_STATUS       EQU     FFFDh
INITIAL_SP      EQU     FDFFh
CURSOR          EQU     FFFCh
CURSOR_INIT     EQU     FFFFh

;------------------------------------------------------------------------------
; Screen boundries (P3 Simulator defined)
;------------------------------------------------------------------------------
SCREEN_C_MIN    EQU     0d
SCREEN_C_MAX    EQU     80d
SCREEN_R_MIN    EQU     0d
SCREEN_R_MAX    EQU     23d

;------------------------------------------------------------------------------
; Player constants
;------------------------------------------------------------------------------
PLAYER_C_I      EQU     39d ; Initial Column position at the start of the game
PLAYER_ROW      EQU     22d ; Constant row position
PLAYER_SIZE     EQU     5d
PLAYER_BODY     EQU     '='

;------------------------------------------------------------------------------
; General purpose variables
;------------------------------------------------------------------------------
                ORIG    8000h
PlayerColumnI   WORD    PLAYER_C_I

;------------------------------------------------------------------------------
; Interruptions
;------------------------------------------------------------------------------
                ORIG    FE00h
INT0            WORD    MovePlayerL
INT1            WORD    MovePlayerR

;------------------------------------------------------------------------------
; Instructions
;------------------------------------------------------------------------------
                ORIG    0000h
                JMP     Main

;------------------------------------------------------------------------------
; Function to draw the player body
;------------------------------------------------------------------------------
DrawPlayer:     PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R2, M[PlayerColumnI]
                MOV     R3, PLAYER_BODY
                MOV     R4, 1d

DrawLoop:       MOV     R1, PLAYER_ROW
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     M[IO_WRITE], R3
                CMP     R4, PLAYER_SIZE
                BR.Z    EndDraw
                INC     R2
                INC     R4
                BR      DrawLoop

EndDraw:        POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to clean a line on the screen
;------------------------------------------------------------------------------
CleanLine:      PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R2, 0d
                MOV     R3, SPACE
                MOV     R4, 1d

CleanLoop:      MOV     R1, PLAYER_ROW
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     M[IO_WRITE], R3
                CMP     R4, 80d
                BR.Z    EndClean
                INC     R2
                INC     R4
                BR      CleanLoop

EndClean:       POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to move the player to the left
;------------------------------------------------------------------------------
MovePlayerL:    PUSH    R1

                MOV     R1, SCREEN_C_MIN
                CMP     R1, M[PlayerColumnI]
                BR.Z    EndMoveL
                DEC     M[PlayerColumnI]
                CALL    CleanLine
                CALL    DrawPlayer

EndMoveL:       POP     R1
                RTI

;------------------------------------------------------------------------------
; Function to move the player to the right
;------------------------------------------------------------------------------
MovePlayerR:    PUSH    R1

                MOV     R1, SCREEN_C_MAX
                SUB     R1, PLAYER_SIZE
                CMP     R1, M[PlayerColumnI]
                BR.Z    EndMoveR
                INC     M[PlayerColumnI]
                CALL    CleanLine
                CALL    DrawPlayer

EndMoveR:       POP     R1
                RTI

;------------------------------------------------------------------------------
; Main function
;------------------------------------------------------------------------------
Main:           ENI

                MOV     R1, INITIAL_SP
                MOV     SP, R1 ; Stack initialization
                MOV     R1, CURSOR_INIT ; Cursor initialization
                MOV     M[CURSOR], R1
                CALL    DrawPlayer
Halt:           BR      Halt
