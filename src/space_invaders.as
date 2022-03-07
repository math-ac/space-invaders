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
ASCII_BASE      EQU     48d ; ASCII base value for integers

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
PLAYER_C_I      EQU     39d ; Initial column position at the start of the game
PLAYER_ROW      EQU     22d ; Constant row position for the player
PLAYER_SIZE     EQU     5d
PLAYER_SHAPE    EQU     '='
PLAYER_LIVES    EQU     3d

LIVES_C_I       EQU     70d
LIVES_ROW_I     EQU     0d
LIVES_VALUE_C   EQU     77d
LIVES_VALUE_R   EQU     0d

;------------------------------------------------------------------------------
; Bullets constants
;------------------------------------------------------------------------------
BULLET_C_I      EQU     39d ; Initial column position for the bullet shoot
BULLET_ROW_I    EQU     21d ; Initial row position for the bullet shoot
BULLET_SHAPE    EQU     'M'

;------------------------------------------------------------------------------
; Enemies constants
;------------------------------------------------------------------------------
ENEMY1_C_I      EQU     21d ; Initial column position for the enemy 1
ENEMY1_ROW_I    EQU     2d ; Initial row position for the enemy 1

ENEMY2_C_I      EQU     21d ; Initial column position for the enemy 2
ENEMY2_ROW_I    EQU     3d ; Initial row position for the enemy 2

ENEMY3_C_I      EQU     21d ; Initial column position for the enemy 3
ENEMY3_ROW_I    EQU     4d ; Initial row position for the enemy 3

ENEMY_TIME      EQU     2d ; Cycles for the next enemy movement

ENEMY_R_MOV     EQU     1d ; Flag for right movement
ENEMY_L_MOV     EQU     2d ; Flag for left movement
ENEMY_D_MOV     EQU     3d ; Flag for down movement

ENEMY_SIZE      EQU     9d ; Size of a row of enemies

;------------------------------------------------------------------------------
; Score constants
;------------------------------------------------------------------------------
POINTS_I        EQU     0d ; Initial score
POINTS_C_I      EQU     7d
POINTS_ROW_I    EQU     0d

SCORE_C_I       EQU     0d
SCORE_ROW_I     EQU     0d

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
PlayerLives     WORD    PLAYER_LIVES

LivesString     STR     'Lives:', END_STRING
LivesCollumn    WORD    LIVES_C_I
LivesRow        WORD    LIVES_ROW_I
ValueLiveC      WORD    LIVES_VALUE_C
ValueLiveR      WORD    LIVES_VALUE_R

;------------------------------------------------------------------------------
; Bullet variables
;------------------------------------------------------------------------------
BulletColumn    WORD    BULLET_C_I
BulletRow       WORD    BULLET_ROW_I
BulletStatus    WORD    OFF

;------------------------------------------------------------------------------
; Enemies variables
;------------------------------------------------------------------------------
RowEnemies1     STR     'V V V V V', END_STRING
Enemie1ColumnI  WORD    ENEMY1_C_I
Enemie1RowI     WORD    ENEMY1_ROW_I

RowEnemies2     STR     'Y Y Y Y Y', END_STRING
Enemie2ColumnI  WORD    ENEMY2_C_I
Enemie2RowI     WORD    ENEMY2_ROW_I

RowEnemies3     STR     'W W W W W', END_STRING
Enemie3ColumnI  WORD    ENEMY3_C_I
Enemie3RowI     WORD    ENEMY3_ROW_I

EnemieMovement  WORD    ENEMY_R_MOV

;------------------------------------------------------------------------------
; Score variables
;------------------------------------------------------------------------------
Points          WORD    POINTS_I
PointsColumn    WORD    POINTS_C_I
PointsRow       WORD    POINTS_ROW_I

ScoreString     STR     'Score:', END_STRING
ScoreColumn     WORD    SCORE_C_I
ScoreRow        WORD    SCORE_ROW_I

;------------------------------------------------------------------------------
; String variables
;------------------------------------------------------------------------------
StringRow       WORD    1d
StringColumn    WORD    1d
StringToPrint   WORD    0d
StringSize      WORD    0d ; Used to clean a string only

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

;----------------------------------- Time -------------------------------------

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
                CALL    DrawPoints
                CALL    DrawLivesValue

EndTimer:       MOV     R1, M[ETimeUnits]
                MOV     R2, ENEMY_TIME ; Enemies Time to move
                DIV     R1, R2
                CMP     R2, R0 ; Compare the division rest with 0
                CALL.Z  MoveEnemies
                ;CALL.Z  DrawEnemies
                CALL    TimerOn

                POP     R2
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

;--------------------------------- String -------------------------------------

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
; Function to print string
;------------------------------------------------------------------------------
PrintString:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R1, M[StringRow]
                MOV     R2, M[StringColumn]
                MOV     R3, M[StringToPrint]

PrintStrLoop:   MOV     R4, R1
                SHL     R4, 8d
                OR      R4, R2
                MOV     M[CURSOR], R4
                MOV     R5, M[R3]
                MOV     M[IO_WRITE], R5
                MOV     R5, M[R3 + 1]
                CMP     R5, END_STRING
                JMP.Z   EndStrPrint
                INC     R2
                INC     R3
                JMP     PrintStrLoop

EndStrPrint:    POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to clean a string of given size
;------------------------------------------------------------------------------
CleanString:    PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R1, M[StringRow]
                MOV     R2, M[StringColumn]
                MOV     R3, R0

CleanStrLoop:   MOV     R4, R1
                SHL     R4, 8d
                OR      R4, R2
                MOV     M[CURSOR], R4
                CALL    CleanSpace
                CMP     R3, M[StringSize]
                JMP.Z   EndStrPrint
                INC     R2
                INC     R3
                JMP     CleanStrLoop

EndStrClean:    POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to reset screen variables
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
                DEC     R2
                DEC     R2

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
                INC     R2
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

                MOV    R1, M[ScoreRow]
                MOV    R2, M[ScoreColumn]
                MOV    M[StringRow], R1
                MOV    M[StringColumn], R2
                MOV    R3, ScoreString
                MOV    M[StringToPrint], R3
                CALL   PrintString
                CALL   DrawPoints
                JMP    EndDScore

EndDScore:      POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to draw points
;------------------------------------------------------------------------------
DrawPoints:     PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R1, M[PointsRow]
                MOV     R2, M[PointsColumn]
                MOV     R3, M[Points]

Digits:         MOV     R4, 10d
                DIV     R3, R4
                CMP     R3, R0
                JMP.Z   PrePointLoop ; Single digit number
                INC     R2 ; For each digit, increase column
                JMP     Digits

PrePointLoop:   MOV     R3, M[Points] ; Load actual point value again
                JMP     PointLoop

PointLoop:      MOV     R4, 10d
                DIV     R3, R4
                MOV     R5, ASCII_BASE
                ADD     R5, R4 ; Add to rest
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     M[IO_WRITE], R5
                CMP     R3, R0
                JMP.Z   EndPoints
                DEC     R2
                MOV     R1, M[PointsRow] ; Maintain the row
                JMP     PointLoop

EndPoints:      POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to draw lives
;------------------------------------------------------------------------------
DrawLives:      PUSH    R1
                PUSH    R2
                PUSH    R3

                MOV     R1, M[LivesRow]
                MOV     R2, M[LivesCollumn]
                MOV     M[StringRow], R1
                MOV     M[StringColumn], R2
                MOV     R3, LivesString
                MOV     M[StringToPrint], R3
                CALL    PrintString
                CALL    DrawLivesValue
                JMP     EndDScore

EndDLives:      POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to draw lives value
;------------------------------------------------------------------------------
DrawLivesValue: PUSH    R1
                PUSH    R2
                PUSH    R3

                MOV     R1, M[ValueLiveR]
                MOV     R2, M[ValueLiveC]
                MOV     R3, M[PlayerLives]
                ADD     R3, ASCII_BASE
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                MOV     M[IO_WRITE], R3
                JMP     EndLivesV

EndLivesV:      POP     R3
                POP     R2
                POP     R1
                RET

;-------------------------------- Shoot ---------------------------------------

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
                ;INC     M[Points] ;TODO only for tests, can be removed

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
                ADD     R1, R2 ; Middle of the ship
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

MBulletEnd:     CALL    Collision
                POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to check collision with enemies
;------------------------------------------------------------------------------
Collision:      PUSH    R1
                PUSH    R2
                PUSH    R3
                PUSH    R4
                PUSH    R5

                MOV     R1, M[BulletRow]
                MOV     R2, M[BulletColumn]
                MOV     R3, M[Enemie1ColumnI]
                MOV     R4, R0

                CMP     R1, M[Enemie1RowI]
                JMP.Z   Collision1 ; Possible collision with row 1 of enemies
                CMP     R1, M[Enemie2RowI]
                JMP.Z   Collision2 ; Possible collision with row 2 of enemies
                CMP     R1, M[Enemie3RowI]
                JMP.Z   Collision3 ; Possible collision with row 3 of enemies

Collision1:     MOV     R5, R3
                CMP     R5, R2
                JMP.Z   HadCollision1 ; Collision confirmed with row 1
                INC     R3
                CMP     R4, ENEMY_SIZE
                JMP.Z   EndCollision ; Collision didn't occur
                INC     R4
                JMP     Collision1

HadCollision1:  MOV     R5, RowEnemies1
                ADD     R5, R4 ; The actual position within the array of enemies
                MOV     R1, SPACE
                CMP     M[R5], R1
                JMP.Z   EndCollision ; It was just a space
                MOV     M[R5], R1 ; Update the array, enemy destroyed
                INC     M[Points]
                MOV     R1, OFF
                MOV     M[BulletStatus], R1
                JMP     EndCollision

Collision2:     MOV     R5, R3
                CMP     R5, R2
                JMP.Z   HadCollision2 ; Collision confirmed with row 2
                INC     R3
                CMP     R4, ENEMY_SIZE
                JMP.Z   EndCollision ; Collision didn't occur
                INC     R4
                JMP     Collision2

HadCollision2:  MOV     R5, RowEnemies2
                ADD     R5, R4 ; The actual position within the array of enemies
                MOV     R1, SPACE
                CMP     M[R5], R1
                JMP.Z   EndCollision ; It was just a space
                MOV     M[R5], R1 ; Update the array, enemy destroyed
                INC     M[Points]
                MOV     R1, OFF
                MOV     M[BulletStatus], R1
                JMP     EndCollision

Collision3:     MOV     R5, R3
                CMP     R5, R2
                JMP.Z   HadCollision3 ; Collision confirmed with row 3
                INC     R3
                CMP     R4, ENEMY_SIZE
                JMP.Z   EndCollision ; Collision didn't occur
                INC     R4
                JMP     Collision3

HadCollision3:  MOV     R5, RowEnemies3
                ADD     R5, R4 ; The actual position within the array of enemies
                MOV     R1, SPACE
                CMP     M[R5], R1
                JMP.Z   EndCollision ; It was just a space
                MOV     M[R5], R1 ; Update the array, enemy destroyed
                INC     M[Points]
                MOV     R1, OFF
                MOV     M[BulletStatus], R1
                JMP     EndCollision

EndCollision:   POP     R5
                POP     R4
                POP     R3
                POP     R2
                POP     R1
                RET

;--------------------------------- Player -------------------------------------

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

;--------------------------------- Enemies ------------------------------------

;------------------------------------------------------------------------------
; Function to print enemies
;------------------------------------------------------------------------------
DrawEnemies:    PUSH    R1
                PUSH    R2
                PUSH    R3

                MOV    R1, M[Enemie1RowI]
                MOV    R2, M[Enemie1ColumnI]
                MOV    M[StringRow], R1
                MOV    M[StringColumn], R2
                MOV    R3, RowEnemies1
                MOV    M[StringToPrint], R3
                CALL   PrintString

                MOV    R1, M[Enemie2RowI]
                MOV    R2, M[Enemie2ColumnI]
                MOV    M[StringRow], R1
                MOV    M[StringColumn], R2
                MOV    R3, RowEnemies2
                MOV    M[StringToPrint], R3
                CALL   PrintString

                MOV    R1, M[Enemie3RowI]
                MOV    R2, M[Enemie3ColumnI]
                MOV    M[StringRow], R1
                MOV    M[StringColumn], R2
                MOV    R3, RowEnemies3
                MOV    M[StringToPrint], R3
                CALL   PrintString

                JMP    EndDEnemies

EndDEnemies:    POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to move enemies
;------------------------------------------------------------------------------
MoveEnemies:    PUSH     R1
                PUSH     R2
                PUSH     R3

                CALL    EnemyLimit
                MOV     R1, M[EnemieMovement]
                CMP     R1, ENEMY_R_MOV
                JMP.Z   MoveEnemiesR
                CMP     R1, ENEMY_L_MOV
                JMP.Z   MoveEnemiesL
                CMP     R1, ENEMY_D_MOV
                JMP.Z   MoveEnemiesD

MoveEnemiesR:   MOV     R1, M[Enemie1RowI]
                MOV     R2, M[Enemie1ColumnI]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                MOV     R1, M[Enemie2RowI]
                MOV     R2, M[Enemie2ColumnI]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                MOV     R1, M[Enemie3RowI]
                MOV     R2, M[Enemie3ColumnI]
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                INC     M[Enemie1ColumnI]
                INC     M[Enemie2ColumnI]
                INC     M[Enemie3ColumnI]
                CALL    DrawEnemies
                JMP     EndMovEnemies

MoveEnemiesL:   MOV     R1, M[Enemie1RowI]
                MOV     R2, M[Enemie1ColumnI]
                ADD     R2, ENEMY_SIZE
                DEC     R2
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                MOV     R1, M[Enemie2RowI]
                MOV     R2, M[Enemie2ColumnI]
                ADD     R2, ENEMY_SIZE
                DEC     R2
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                MOV     R1, M[Enemie3RowI]
                MOV     R2, M[Enemie3ColumnI]
                ADD     R2, ENEMY_SIZE
                DEC     R2
                SHL     R1, 8d
                OR      R1, R2
                MOV     M[CURSOR], R1
                CALL    CleanSpace ; Clean the last position

                DEC     M[Enemie1ColumnI]
                DEC     M[Enemie2ColumnI]
                DEC     M[Enemie3ColumnI]
                CALL    DrawEnemies
                JMP     EndMovEnemies

MoveEnemiesD:   MOV     R1, M[Enemie1RowI]
                MOV     R2, M[Enemie1ColumnI]
                MOV     M[StringRow], R1
                MOV     M[StringColumn], R2
                MOV     R3, ENEMY_SIZE
                MOV     M[StringSize], R3
                CALL    CleanString

                MOV     R1, M[Enemie2RowI]
                MOV     R2, M[Enemie2ColumnI]
                MOV     M[StringRow], R1
                MOV     M[StringColumn], R2
                MOV     R3, ENEMY_SIZE
                MOV     M[StringSize], R3
                CALL    CleanString

                MOV     R1, M[Enemie3RowI]
                MOV     R2, M[Enemie3ColumnI]
                MOV     M[StringRow], R1
                MOV     M[StringColumn], R2
                MOV     R3, ENEMY_SIZE
                MOV     M[StringSize], R3
                CALL    CleanString

                INC     M[Enemie1RowI]
                INC     M[Enemie2RowI]
                INC     M[Enemie3RowI]
                CALL    DrawEnemies
                JMP     EndMovEnemies

EndMovEnemies:  POP     R3
                POP     R2
                POP     R1
                RET

;------------------------------------------------------------------------------
; Function to check enemies boundaries for movement
;------------------------------------------------------------------------------
EnemyLimit:     PUSH    R1
                PUSH    R2

                MOV     R1, M[EnemieMovement]
                CMP     R1, ENEMY_R_MOV
                JMP.Z   EnemyLimitR
                CMP     R1, ENEMY_L_MOV
                JMP.Z   EnemyLimitL
                CMP     R1, ENEMY_D_MOV
                JMP.Z   EnemyLimitD

EnemyLimitR:    MOV     R1, M[Enemie1ColumnI]
                ADD     R1, ENEMY_SIZE
                CMP     R1, SCREEN_C_MAX
                JMP.Z   NewDirR ; Right limit reached
                JMP     EndELimit

NewDirR:        MOV     R1, ENEMY_D_MOV
                MOV     M[EnemieMovement], R1 ; Move down next
                JMP     EndELimit

EnemyLimitL:    MOV     R1, M[Enemie1ColumnI]
                CMP     R1, SCREEN_C_MIN
                JMP.Z   NewDirL ; Left limit reached
                JMP     EndELimit

NewDirL:        MOV     R1, ENEMY_D_MOV
                MOV     M[EnemieMovement], R1 ; Move down next
                JMP     EndELimit

EnemyLimitD:    MOV     R1, M[Enemie1ColumnI]
                CMP     R1, SCREEN_C_MIN
                JMP.Z   NewDirDL ; Previous movement was left
                JMP     NewDirDR ; Previous movement was right

NewDirDR:       MOV     R1, ENEMY_L_MOV
                MOV     M[EnemieMovement], R1 ; Move left next
                JMP     EndELimit

NewDirDL:       MOV     R1, ENEMY_R_MOV
                MOV     M[EnemieMovement], R1 ; Move right next
                JMP     EndELimit

EndELimit:      POP     R2
                POP     R1
                RET

;-------------------------------- Main ----------------------------------------

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
                CALL    DrawEnemies
                CALL    DrawLives
                CALL    TimerOn

Halt:           JMP     Halt
