; Space Invaders implementation using the P3 Assembly
; Author: Matheus A. Constancio
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; General purpose constants
;------------------------------------------------------------------------------
SPACE           EQU     32d ; Space character
END_STRING      EQU     '@'
IO_READ         EQU     FFFFh
IO_WRITE        EQU     FFFEh
IO_STATUS       EQU     FFFDh
INITIAL_SP      EQU     FDFFh
CURSOR          EQU     FFFCh
CURSOR_INIT     EQU     FFFFh
TIMER_UNITS     EQU     FFF6h
TIMER_ACTIVATE  EQU     FFF7h
TIMER_INIT      EQU     2d ; Total time for one cycle of the timer in [ms]
ON              EQU     1d
OFF             EQU     0d

;------------------------------------------------------------------------------
; Screen boundaries (P3 Simulator defined)
;------------------------------------------------------------------------------
SCREEN_C_MIN    EQU     0d
SCREEN_C_MAX    EQU     80d
SCREEN_R_MIN    EQU     0d
SCREEN_R_MAX    EQU     23d

;------------------------------------------------------------------------------
; Player constants
;------------------------------------------------------------------------------
PLAYER_C_I      EQU     39d ; Initial Column position at the start of the game
PLAYER_ROW      EQU     22d ; Constant row position for the player
PLAYER_SIZE     EQU     5d
PLAYER_SHAPE    EQU     '='

;------------------------------------------------------------------------------
; Bullets constants
;------------------------------------------------------------------------------
BULLET_C_I      EQU     39d ; Constant row column for the bullet shoot
BULLET_ROW_I    EQU     22d ; Constant row position for the bullet shoot
BULLET_SHAPE    EQU     '|'

;------------------------------------------------------------------------------
; Enemies constants
;------------------------------------------------------------------------------
ENEMY1_C_I      EQU     2d ; Constant row column for the bullet shoot
ENEMY1_ROW_I    EQU     2d ; Constant row position for the bullet shoot
ENEMY1_SHAPE    EQU     'V'

;------------------------------------------------------------------------------
; General purpose variables
;------------------------------------------------------------------------------
                ORIG    8000h

;------------------------------------------------------------------------------
; Player variables
;------------------------------------------------------------------------------
PlayerColumnI   WORD    PLAYER_C_I

;------------------------------------------------------------------------------
; Bullet variables
;------------------------------------------------------------------------------
BulletColumnI   WORD    BULLET_C_I
BulletRowI      WORD    BULLET_ROW_I
BulletStatus    WORD    OFF

;------------------------------------------------------------------------------
; Enemies variables
;------------------------------------------------------------------------------
Enemies         STR     'V  V  V  V', END_STRING
Enemie1ColumnI  STR     ENEMY1_C_I
Enemie1RowI     STR     ENEMY1_ROW_I

;------------------------------------------------------------------------------
; Interruptions
;------------------------------------------------------------------------------
                ORIG    FE00h
INT0            WORD    MovePlayerL
INT1            WORD    MovePlayerR
INT2            WORD    Shoot

                ORIG    FE0Fh
INT15           WORD    Timer

;------------------------------------------------------------------------------
; Instructions
;------------------------------------------------------------------------------
                ORIG    0000h
                JMP     Main

;------------------------------------------------------------------------------
; Function to simulate the bullet time
;------------------------------------------------------------------------------
Timer:          PUSH    R1

                MOV     R1, M[BulletStatus]
                CMP     R1, OFF
                JMP.Z   EndTimer
                CALL    MoveBullet
                CALL    TimerOn

EndTimer:       POP     R1
                RTI

;------------------------------------------------------------------------------
; Function to shoot
;------------------------------------------------------------------------------
Shoot:          PUSH    R1

                MOV     R1, M[BulletStatus]
                CMP     R1, ON
                JMP.Z   EndShoot
                MOV     R1, ON
                MOV     M[BulletStatus], R1
                ;CALL    ShootPosition
                CALL    Timer

EndShoot:       POP     R1
                RTI

;------------------------------------------------------------------------------
; Function to find the column position for the shoot NOT WORKING
;------------------------------------------------------------------------------
ShootPosition:  PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R1, M[BulletColumnI]
                MOV     R2, PLAYER_SIZE
                MOV     R3, 2d
                DIV     R2, R3
                ADD     R1, R2
                MOV     R4, R1
                MOV     M[BulletColumnI], R4

                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to move the bullet
;------------------------------------------------------------------------------
MoveBullet:     PUSH    R1
                PUSH    R2
                PUSH    R3

                MOV     R1, M[BulletRowI]
                MOV     R2, M[BulletColumnI]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                DEC     M[BulletRowI] ; Update bullet position
                MOV     R1, M[BulletRowI]
                CMP     R1, SCREEN_R_MIN
                JMP.Z   BScreen ; Screen limit for the bullet reached

                MOV     R1, M[BulletRowI]
                MOV     R2, M[BulletColumnI]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     R3, BULLET_SHAPE
                MOV     M[IO_WRITE], R3 ; Print the bullet
                JMP     MBulletEnd

BScreen:        MOV     R1, OFF
                MOV     M[BulletStatus], R1
                MOV     R1, BULLET_ROW_I
                MOV     M[BulletRowI], R1
                JMP     MBulletEnd

MBulletEnd:     POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to draw the player body
;------------------------------------------------------------------------------
DrawPlayer:     PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R2, M[PlayerColumnI]
                MOV     R3, PLAYER_SHAPE
                MOV     R4, 1d

PlayerLoop:     MOV     R1, PLAYER_ROW
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     M[IO_WRITE], R3
                CMP     R4, PLAYER_SIZE
                JMP.Z   PlayerEnd
                INC     R2
                INC     R4
                JMP     PlayerLoop

PlayerEnd:      POP     R4
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
                JMP.Z   EndClean
                INC     R2
                INC     R4
                JMP     CleanLoop

EndClean:       POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to print enemies NOT WORKING
;------------------------------------------------------------------------------
DrawEnemies:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R1, M[Enemie1ColumnI]
                MOV     R2, M[Enemie1RowI]
                MOV     R3, M[Enemies]

DEnemiesLoop:   SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     M[IO_WRITE], R3
                INC     R3
                CMP     R3, END_STRING
                JMP.Z   EndDEnemies
                INC     R2
                JMP     DEnemiesLoop

EndDEnemies:    POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to clean a single space on the screen,
; assuming the cursor is already in place
;------------------------------------------------------------------------------
CleanSpace:     PUSH    R1

                MOV     R1, SPACE
                MOV     M[IO_WRITE], R1

                POP     R1
                RET


;------------------------------------------------------------------------------
; Function to move the player to the left
;------------------------------------------------------------------------------
MovePlayerL:    PUSH    R1
                PUSH    R2

                MOV     R1, SCREEN_C_MIN
                CMP     R1, M[PlayerColumnI] ; Check screen boundaries
                JMP.Z   EndMoveL
                MOV     R1, PLAYER_ROW
                MOV     R2, M[PlayerColumnI]
                ADD     R2, PLAYER_SIZE
                DEC     R2 ; Update player position
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position
                DEC     M[PlayerColumnI]
                CALL    DrawPlayer ; Draw the player

EndMoveL:       POP     R2
                POP     R1
                RTI

;------------------------------------------------------------------------------
; Function to move the player to the right
;------------------------------------------------------------------------------
MovePlayerR:    PUSH    R1
                PUSH    R2

                MOV     R1, SCREEN_C_MAX
                SUB     R1, PLAYER_SIZE
                CMP     R1, M[PlayerColumnI] ; Check screen boundaries
                JMP.Z   EndMoveR
                MOV     R1, PLAYER_ROW
                MOV     R2, M[PlayerColumnI]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position
                INC     M[PlayerColumnI] ; Update player position
                CALL    DrawPlayer

EndMoveR:       POP     R2
                POP     R1
                RTI

;------------------------------------------------------------------------------
; Function to activate the timer
;------------------------------------------------------------------------------
TimerOn:        PUSH    R1

                MOV     R1, TIMER_INIT
                MOV     M[TIMER_UNITS], R1
                MOV     R1, ON
                MOV     M[TIMER_ACTIVATE], R1

                POP     R1
                RET

;------------------------------------------------------------------------------
; Main function
;------------------------------------------------------------------------------
Main:           ENI

                MOV     R1, INITIAL_SP
                MOV     SP, R1 ; Stack initialization
                MOV     R1, CURSOR_INIT ; Cursor initialization
                MOV     M[CURSOR], R1
                CALL    DrawPlayer
                ;CALL    DrawEnemies
                CALL    TimerOn

Halt:           JMP     Halt
