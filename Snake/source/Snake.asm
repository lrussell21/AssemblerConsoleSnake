TITLE Snake (Snake.asm)
; Author: Levi Russell
; Date: 12/5/2018
; Description: Console Snake Game
INCLUDE Irvine32.inc

.data
W = 60 ; Width of play area.
H = 20 ; Height of play area.
speed DWORD ?
death DWORD ?
score DWORD ?
incAmount DWORD ?
borderOutputCheck DWORD ?
borderOutputWhiteCheck DWORD ?
colorTest BYTE 0h
charTest BYTE ?
charStore BYTE ?
blank BYTE " ",0
snakex BYTE W*W DUP(?)
snakey BYTE H*H DUP(?)
foodx BYTE ?
foody BYTE ?
gameover BYTE "GAME OVER!",0
scoreOutput BYTE "Score:",0
topTitle BYTE "CONSOLE SNAKE made by: Levi Russell",0

.code
main proc
RESET:
call randomize ; Generates a seed so random numbers are random.
; http://kipirvine.com/asm/4th/instructor/4thEdition/moreprojects/bouncingBall.asm
;----- hides the cursor ----------------------------------------
.data
cursorInfo CONSOLE_CURSOR_INFO <>
outHandle  DWORD ?
.code
	INVOKE GetStdHandle, STD_OUTPUT_HANDLE
	mov  outHandle,eax
	INVOKE GetConsoleCursorInfo, outHandle, ADDR cursorInfo
	mov  cursorInfo.bVisible,0
	INVOKE SetConsoleCursorInfo, outHandle, ADDR cursorInfo
;---------------------------------------------------------------

    call startingProcedure

    mov esi, 1
    gameLoop:
        call moveSnake
        mov eax, speed      ; Simulate frames using delay.
        call Delay
        call outputBorderAnimation   ; Output border each frame to cover green animation.
        mov esi, death
    mov eax, esi
    cmp eax, 1
    je gameLoop

    call outputBorderAnimation

    mov dl, W/2
    sub dl, 6
    mov dh, H/4
    call gotoxy
    mov edx, offset gameover
    call writeString

    mov ecx, 5
    gameOverRetry:
        mov dl, W/2
        mov dh, H/4
        sub dl, 2
        add dh, 2
        call gotoxy
        mov eax, ecx
        call writeDec
        mov eax, 1000
        call delay
    loop gameOverRetry

    jmp RESET
exit

moveSnake PROC
    ; ReadKey puts key ascii into al.
    call Readkey
    stay:

    mov charTest, al
    cmp al, 77h ; TEST W
    je UP
    mov al, charTest
    cmp al, 73h ; TEST S
    je DOWN
    mov al, charTest
    cmp al, 64h ; TEST D
    je RIGHT
    mov al, charTest
    cmp al, 61h ; TEST A
    je LEFT

    mov al, charStore
    jmp stay ; Makes snake move when key isnt being held down

    UP:
        mov al, charTest
        mov charStore, al
        call follow
        sub snakey, 1
        jmp stuff
    DOWN:
        mov al, charTest
        mov charStore, al
        call follow
        add snakey, 1
        jmp stuff
    LEFT:
        mov al, charTest
        mov charStore, al
        call follow
        sub snakex, 1
        jmp stuff

    RIGHT:
        mov al, charTest
        mov charStore, al
        call follow
        add snakex, 1
        jmp stuff

    stuff:
        call checkSnakeCollision
        call checkFood
        call checkBorder
        call drawSnake
        ret
moveSnake ENDP

drawSnake PROC
    mov eax,white + (black * 16)
    call SetTextColor

    mov ecx, score
    mov dl, snakex[TYPE BYTE * ecx]
    mov dh, snakey[TYPE BYTE * ecx]
    call gotoxy
    mov edx, offset blank
    call writeString


    mov colorTest, 25h
    mov ecx, score
    dec ecx
    L1:


        ;mov ah, white
        ;mov al, colorTest
        mov eax,white + (red * 16)
        call SetTextColor
        mov dl, snakex[TYPE BYTE * ecx]
        mov dh, snakey[TYPE BYTE * ecx]
        call gotoxy
        mov edx, offset blank
        call writeString

        ;mov bl, colorTest
        ;add bl, 01h
        ;mov colorTest, bl


        dec ecx
    mov eax, ecx
    cmp eax, -1
    jne L1

    mov eax,white + (black * 16)
    call SetTextColor
    ret
drawSnake ENDP


follow PROC
    ; Sets array of points to the one in front then updates last one to blank so snake appears to move each frame.
    mov ecx, score
    Snake:
        mov dl, snakex[(TYPE BYTE * ecx) - TYPE BYTE]
        mov dh, snakey[(TYPE BYTE * ecx) - TYPE BYTE]
        mov snakex[TYPE BYTE * ecx], dl
        mov snakey[TYPE BYTE * ecx], dh
        dec ecx
    mov eax, ecx
    cmp eax, 0
    jne Snake
    ret
follow ENDP

outputFood PROC
    ; Outputs food while making sure not to output food where the snake currently is.
    retry:
    mov eax, W
    sub eax, 2
    call randomRange
    inc eax
    mov foodx, al
    mov eax, H
    call randomRange
    add eax, 3
    mov foody, al


    mov ecx, score
    dec ecx
    L:
        mov eax, 0

        mov dl, snakex[TYPE BYTE * ecx]
        cmp dl, foodx
        je addOne1
        L1:

        mov dh, snakey[TYPE BYTE * ecx]
        cmp dh, foody
        je addOne2
        L2:
        cmp eax, 2
        je retry
        dec ecx
    mov eax, ecx
    cmp eax, 0
    jge L

    jmp outputThis
    
    addOne1:
    inc eax
    jmp L1

    addOne2:
    inc eax
    jmp L2

    outputThis:

    mov eax,red + (cyan * 16)
    call SetTextColor

    mov dl, foodx
    mov dh, foody
    call gotoxy
    mov edx, offset blank
    call writeString

    mov eax,white + (black * 16)
    call SetTextColor
    ret
outputFood ENDP

checkFood PROC
    mov al, snakex
    mov ah, snakey
    cmp al, foodx
    jne return
    cmp ah, foody
    jne return

    ; Increases score by incAmount so you can change amount snake grows with 1 variable.
    mov eax, score
    add eax, incAmount
    mov score, eax


    ; This is so new addition to tail starts at back
    mov ecx, eax
    sub eax, incAmount
    tailAdd:
        mov dl, snakex[TYPE BYTE * eax]
        mov dh, snakey[TYPE BYTE * eax]
        mov snakex[TYPE BYTE * ecx], dl
        mov snakey[TYPE BYTE * ecx], dh
        dec ecx
    mov edx, ecx
    cmp edx, eax
    jne tailAdd

    ; Makes it to where border is green for 3 frames.
    ; But really only 2 because we want to change green when food is picked
    ; up and not after delay when function is called every frame.
    mov eax, borderOutputCheck
    add eax, 3
    mov borderOutputCheck, eax
    call outputBorderAnimation
    
    call outputFood
    call speedChange

    mov dl, 6
    mov dh, 1
    call gotoxy
    mov eax, score
    sub eax, 6
    call writeDec
    ret
    return:
    ret
checkFood ENDP

checkBorder PROC
    ; Checks if snake it hitting the border and if it is makes game end.
    ; Left
    mov dl, snakex
    cmp dl, 0
    je dead
    ; Right
    mov dl, snakex
    mov dh, W
    dec dh
    cmp dl, dh
    je dead
    ; Top
    mov dl, snakey
    cmp dl, 2
    je dead
    ; Bottom
    mov dl, snakey
    mov dh, H
    add dh, 3
    cmp dl, dh
    je dead

    ret

    dead:
    mov death, 0
    ret
checkBorder ENDP

checkSnakeCollision PROC
    ; Checks if snake is hitting itself
    mov ecx, score
    sub ecx, 3
    L:
        mov eax, 0

        mov dl, snakex[TYPE BYTE * ecx]
        cmp dl, snakex
        je addOne1
        L1:

        mov dh, snakey[TYPE BYTE * ecx]
        cmp dh, snakey
        je addOne2
        L2:
        cmp eax, 2
        je dead
        dec ecx
    mov eax, ecx
    cmp eax, 1
    jge L

    ret
    addOne1:
    inc eax
    jmp L1

    addOne2:
    inc eax
    jmp L2

    dead:
    mov death, 0
    ret
checkSnakeCollision ENDP

outputBorderAnimation PROC
    ; Makes border green for 1 frame when snake collects food, and red when snake dies.
    mov eax, death
    cmp eax, 0
    je changeRed
    
    mov eax, borderOutputCheck
    cmp eax, 0
    jne greenJump

    mov eax, borderOutputWhiteCheck
    cmp eax, 0
    je return

    mov eax, borderOutputWhiteCheck
    mov eax, 0
    mov borderOutputWhiteCheck, eax
    mov eax,white + (white * 16)
    call SetTextColor
    jmp changeColorloop

    changeRed:
    mov eax,white + (Red * 16)
    call SetTextColor
    jmp changeColorloop 

    greenJump:
    mov eax,white + (green * 16)
    call SetTextColor
    mov eax, borderOutputCheck
    dec eax
    mov borderOutputCheck, eax
    mov eax, borderOutputWhiteCheck
    mov eax, 1
    mov borderOutputWhiteCheck, eax

    changeColorloop:
    mov ecx, W
    topBot:
        mov dl, cl
        mov dh, 2
        dec dl
        call gotoxy
        mov edx, offset blank
        call writeString

        mov dl, cl
        mov dh, H
        add dh, 3
        dec dl
        call gotoxy
        mov edx, offset blank
        call writeString
    loop topBot

    mov ecx, H
    rightLeft:
        mov dl, 0
        mov dh, cl
        add dh, 2
        call gotoxy
        mov edx, offset blank
        call writeString

        mov dl, W
        dec dl
        mov dh, cl
        add dh, 2
        call gotoxy
        mov edx, offset blank
        call writeString
    loop rightLeft

    return:
    mov eax,white + (black * 16)
    call SetTextColor
    ret
outputBorderAnimation ENDP

speedChange PROC
    mov eax, score
    cmp eax, 100
    jge fast

    mov eax, score
    cmp eax, 50
    jge medium

    mov eax, score
    cmp eax, 20
    jge slow

    starting:
    mov speed, 125
    ret
    slow:
    mov speed, 100
    ret
    medium:
    mov speed, 75
    ret
    fast:
    mov speed, 60
    ret
speedChange ENDP

startingProcedure PROC
    call clrscr

    mov score, 6
    mov incAmount, 5
    mov death, 1
    mov speed, 125
    mov snakex, W/2
    mov snakey, H/2
    mov charStore, 77h ; Start game with snake going up so game doesnt get stuck.

    mov eax, borderOutputWhiteCheck
    mov eax, 1
    mov borderOutputWhiteCheck, eax
    mov eax, borderOutputCheck
    mov eax, 0
    mov borderOutputCheck, eax
    call outputBorderAnimation

    ; Sets first 5 parts of snake to starting location so dead snake coord aren't drawn.
    mov ecx, 5
    start:
        mov dl, snakex
        mov dh, snakey
        mov snakex[TYPE BYTE * ecx], dl
        mov snakey[TYPE BYTE * ecx], dh
    loop start

    ; This part outputs title and starting score.
    mov dl, 0
    mov dh, 0
    call gotoxy
    mov edx, offset topTitle
    call writeString
    mov dl, 0
    mov dh, 1
    call gotoxy
    mov edx, offset scoreOutput
    call writeString
    mov dl, 6
    mov dh, 1
    call gotoxy
    mov eax, score
    sub eax, 6
    call writeDec

    call outputFood
    ret
startingProcedure ENDP

main endp
END