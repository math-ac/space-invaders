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
SCREEN_C_MIN    EQU     20d ; 0 is the min.
SCREEN_C_MAX    EQU     60d ; 80 is the max.
SCREEN_C_SHAPE  EQU     '|'
SCREEN_R_MIN    EQU     1d ; 0 is the min.
SCREEN_R_MAX    EQU     23d ; 23 is the max.
SCREEN_R_SHAPE  EQU     '-'

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
BULLET_ROW_I    EQU     21d ; Constant row position for the bullet shoot
BULLET_SHAPE    EQU     'M'

;------------------------------------------------------------------------------
; Enemies constants
;------------------------------------------------------------------------------
ENEMY1_C_I      EQU     2d ; Constant row column for the bullet shoot
ENEMY1_ROW_I    EQU     2d ; Constant row position for the bullet shoot
ENEMY1_SHAPE    EQU     'V'
ENEMY_TIME      EQU     20d ; Cycles for the next enemy movement

;------------------------------------------------------------------------------
; Score constants
;------------------------------------------------------------------------------
SCORE_C_I       EQU     0d
SCORE_ROW_I     EQU     0d
SCORE_P_I       EQU     0d ; Initial score

;------------------------------------------------------------------------------
; General purpose variables
;------------------------------------------------------------------------------
                ORIG    8000h

;------------------------------------------------------------------------------
; Time variables
;------------------------------------------------------------------------------
ETimeUnits      WORD    0d; Elapsed Time

;------------------------------------------------------------------------------
; Screen variables
;------------------------------------------------------------------------------
ScreenColumn    WORD    SCREEN_C_MIN
ScreenRow       WORD    SCREEN_R_MIN

;------------------------------------------------------------------------------
; Player variables
;------------------------------------------------------------------------------
PlayerColumnI   WORD    PLAYER_C_I

;------------------------------------------------------------------------------
; Bullet variables
;------------------------------------------------------------------------------
BulletColumn    WORD    BULLET_C_I
BulletRow       WORD    BULLET_ROW_I
BulletStatus    WORD    OFF

;------------------------------------------------------------------------------
; Enemies variables
;------------------------------------------------------------------------------
RowEnemies1     STR     ENEMY1_SHAPE, ' ', ENEMY1_SHAPE, ' ', END_STRING
Enemie1ColumnI  STR     ENEMY1_C_I
Enemie1RowI     STR     ENEMY1_ROW_I

;------------------------------------------------------------------------------
; Score variables
;------------------------------------------------------------------------------
ScorePoints     WORD    SCORE_P_I
ScoreString     STR     'Score:', END_STRING
ScoreColumn     WORD    SCORE_C_I
ScoreRow        WORD    SCORE_ROW_I

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
                PUSH    R2

                INC     M[ETimeUnits]
                MOV     R1, M[BulletStatus]
                CMP     R1, OFF
                JMP.Z   EndTimer
                CALL    MoveBullet
                CALL    DrawScore

EndTimer:       MOV     R1, M[ETimeUnits]
                MOV     R2, ENEMY_TIME ; Enemies Time to move
                DIV     R1, R2
                CMP     R2, R0 ; Compare the division rest with 0
                ;CALL.Z  MoveEnemies
                ;CALL.Z  DrawEnemies
                CALL    TimerOn

                POP     R2
                POP     R1
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
                CALL    ShootPosition
                INC     M[ScorePoints] ;TODO only for tests, can be removed

EndShoot:       POP     R1
                RTI

;------------------------------------------------------------------------------
; Function to find the column position for the shoot
;------------------------------------------------------------------------------
ShootPosition:  PUSH    R1
                PUSH    R2
                PUSH    R3

                MOV     R1, M[PlayerColumnI]
                MOV     R2, PLAYER_SIZE
                MOV     R3, 2d
                DIV     R2, R3
                ADD     R1, R2
                MOV     M[BulletColumn], R1

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

                MOV     R1, M[BulletRow]
                MOV     R2, M[BulletColumn]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                DEC     M[BulletRow] ; Update bullet position
                MOV     R1, M[BulletRow]
                CMP     R1, SCREEN_R_MIN
                JMP.Z   BScreen ; Screen limit for the bullet reached

                MOV     R1, M[BulletRow]
                MOV     R2, M[BulletColumn]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     R3, BULLET_SHAPE
                MOV     M[IO_WRITE], R3 ; Print the bullet
                JMP     MBulletEnd

BScreen:        MOV     R1, OFF
                MOV     M[BulletStatus], R1
                MOV     R1, BULLET_ROW_I
                MOV     M[BulletRow], R1
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
; Function to reset variables
;------------------------------------------------------------------------------
ResetScreen:    PUSH    R1

                MOV     R1, SCREEN_C_MIN
                MOV     M[ScreenColumn], R1
                MOV     R1, SCREEN_R_MIN
                MOV     M[ScreenRow], R1

                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to draw the screen boundaries
;------------------------------------------------------------------------------
DrawBoundaries: PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R1, M[ScreenRow]
                MOV     R2, SCREEN_C_MIN
                DEC     R2 ; So the border doesn't overlap with the ship

BLeftLoop:      MOV     R4, R1
                SHL     R4, 8d
                OR      R4, R2
                MOV     M[CURSOR], R4
                MOV     R3, SCREEN_C_SHAPE
                MOV     M[IO_WRITE], R3
                CMP     R1, SCREEN_R_MAX
                CALL.Z  ResetScreen
                JMP.Z   BPreRight
                INC     R1
                JMP     BLeftLoop

BPreRight:      MOV     R1, M[ScreenRow]
                MOV     R2, SCREEN_C_MAX
                ;INC     R2
                JMP     BRightLoop

BRightLoop:     MOV     R4, R1
                SHL     R4, 8d
                OR      R4, R2
                MOV     M[CURSOR], R4
                MOV     R3, SCREEN_C_SHAPE
                MOV     M[IO_WRITE], R3
                CMP     R1, SCREEN_R_MAX
                CALL.Z  ResetScreen
                JMP.Z   BoundariesEnd
                INC     R1
                JMP     BRightLoop

BoundariesEnd:  POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to draw score
;------------------------------------------------------------------------------
DrawScore:      PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R1, M[ScoreRow]
                MOV     R2, M[ScoreColumn]
                MOV     R3, ScoreString

ScoreLoop:      MOV     R4, R1
                SHL     R4, 8d
                OR      R4, R2
                MOV     M[CURSOR], R4
                MOV     R5, M[R3]
                MOV     M[IO_WRITE], R5
                MOV     R5, M[R3 + 1]
                CMP     R5, END_STRING
                JMP.Z   EndDScore
                INC     R2
                INC     R3
                JMP     ScoreLoop

EndDScore:      INC     R2
                MOV     R4, R1
                SHL     R4, 8d
                OR      R4, R2
                MOV     M[CURSOR], R4
                MOV     R5, M[ScorePoints] ;TODO
                MOV     M[IO_WRITE], R5

                POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to clean a line on the screen NOT USED YET
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
; Function to print enemies TODO
;------------------------------------------------------------------------------
DrawEnemies:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4

                MOV     R1, M[Enemie1ColumnI]
                MOV     R2, M[Enemie1RowI]
                MOV     R3, M[RowEnemies1]

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
; Function to move enemies TODO
;------------------------------------------------------------------------------
MoveEnemies:    RET

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
                SUB     R1, PLAYER_SIZE ; Considers the player size
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
                CALL    DrawBoundaries
                CALL    DrawScore
                ;CALL    DrawEnemies
                CALL    TimerOn

Halt:           JMP     Halt
