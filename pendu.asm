; =============================================================
;  pendu.asm - Jeu du pendu en assembleur NASM x86-64 (Linux)
;  Compilation : make      (ou voir le Makefile)
;  Lancement   : ./pendu
; =============================================================

%define SYS_READ   0
%define SYS_WRITE  1
%define SYS_EXIT   60
%define MAX_ERR    6

; -------------------------------------------------------------
section .data
; -------------------------------------------------------------
clear       db 27,"[2J",27,"[H",0                      ; efface l'ecran
title       db 27,"[1;36m=== JEU DU PENDU ===",27,"[0m",10,10,0
msg_word    db 10,"Mot : ",27,"[1m",0
msg_used    db 27,"[0m",10,"Lettres jouees : ",0
msg_err     db 10,"Erreurs : ",0
msg_max     db "/6",10,0
msg_prompt  db 10,"Ta lettre : ",0
msg_inval   db 27,"[33mEntre une lettre (a-z).",27,"[0m",10,0
msg_already db 27,"[33mLettre deja jouee !",27,"[0m",10,0
msg_win     db 10,27,"[1;32mGagne ! Le mot etait : ",0
msg_lose    db 10,27,"[1;31mPerdu ! Le mot etait : ",0
msg_reset   db 27,"[0m",10,0
msg_again   db 10,"Rejouer ? (o/n) : ",0

; --- Dessins du pendu (1 par nombre d'erreurs) ---
s0 db "  +---+",10,"  |   |",10,"      |",10,"      |",10,"      |",10,"      |",10,"=========",10,0
s1 db "  +---+",10,"  |   |",10,"  O   |",10,"      |",10,"      |",10,"      |",10,"=========",10,0
s2 db "  +---+",10,"  |   |",10,"  O   |",10,"  |   |",10,"      |",10,"      |",10,"=========",10,0
s3 db "  +---+",10,"  |   |",10,"  O   |",10," /|   |",10,"      |",10,"      |",10,"=========",10,0
s4 db "  +---+",10,"  |   |",10,"  O   |",10," /|\  |",10,"      |",10,"      |",10,"=========",10,0
s5 db "  +---+",10,"  |   |",10,"  O   |",10," /|\  |",10," /    |",10,"      |",10,"=========",10,0
s6 db "  +---+",10,"  |   |",10,"  O   |",10," /|\  |",10," / \  |",10,"      |",10,"=========",10,0
stages dq s0, s1, s2, s3, s4, s5, s6

; --- Liste de mots (minuscules, sans accents, < 32 lettres) ---
w0 db "ordinateur",0
w1 db "assembleur",0
w2 db "registre",0
w3 db "processeur",0
w4 db "memoire",0
w5 db "clavier",0
w6 db "pendu",0
w7 db "securite",0
w8 db "pare",0
w9 db "algorithme",0
words dq w0, w1, w2, w3, w4, w5, w6, w7, w8, w9
NB_WORDS equ ($ - words) / 8

; -------------------------------------------------------------
section .bss
; -------------------------------------------------------------
word_ptr  resq 1        ; adresse du mot secret
word_len  resq 1        ; longueur du mot
errors    resq 1        ; nombre d'erreurs
status    resq 1        ; message a afficher (0 = aucun)
found     resb 32       ; 1 si la lettre i du mot est decouverte
used      resb 26       ; 1 si la lettre a..z a deja ete jouee
inbuf     resb 64       ; saisie clavier
outc      resb 2        ; tampon pour afficher 1 caractere

; -------------------------------------------------------------
section .text
global _start
; -------------------------------------------------------------

; print_z : affiche la chaine terminee par 0 pointee par rsi
print_z:
    push rax
    push rcx
    push rdx
    push rdi
    push r11
    xor rdx, rdx
.len:
    cmp byte [rsi+rdx], 0
    je .write
    inc rdx
    jmp .len
.write:
    mov rax, SYS_WRITE
    mov rdi, 1
    syscall
    pop r11
    pop rdi
    pop rdx
    pop rcx
    pop rax
    ret

; print_char : affiche le caractere contenu dans al
print_char:
    push rsi
    mov [outc], al
    mov byte [outc+1], 0
    mov rsi, outc
    call print_z
    pop rsi
    ret

; read_line : lit une ligne dans inbuf, rax = nb d'octets lus
read_line:
    mov rax, SYS_READ
    xor rdi, rdi
    mov rsi, inbuf
    mov rdx, 64
    syscall
    ret

; new_game : choisit un mot au hasard et remet tout a zero
new_game:
    rdtsc                       ; compteur CPU -> edx:eax
    xor edx, edx
    mov ecx, NB_WORDS
    div ecx                     ; edx = eax % NB_WORDS
    mov rax, [words + rdx*8]
    mov [word_ptr], rax
    xor rcx, rcx
.len:
    cmp byte [rax+rcx], 0
    je .done
    inc rcx
    jmp .len
.done:
    mov [word_len], rcx
    xor al, al
    mov rdi, found
    mov rcx, 32
    rep stosb
    mov rdi, used
    mov rcx, 26
    rep stosb
    mov qword [errors], 0
    mov qword [status], 0
    ret

; draw : redessine tout l'ecran de jeu
draw:
    mov rsi, clear
    call print_z
    mov rsi, title
    call print_z
    mov rax, [errors]
    mov rsi, [stages + rax*8]
    call print_z

    ; mot masque : _ _ A _ _
    mov rsi, msg_word
    call print_z
    xor rbx, rbx
.word:
    cmp rbx, [word_len]
    jge .word_done
    cmp byte [found+rbx], 0
    je .hidden
    mov rax, [word_ptr]
    mov al, [rax+rbx]
    sub al, 32                  ; en majuscule
    jmp .put
.hidden:
    mov al, '_'
.put:
    call print_char
    mov al, ' '
    call print_char
    inc rbx
    jmp .word
.word_done:

    ; lettres deja jouees
    mov rsi, msg_used
    call print_z
    xor rbx, rbx
.used:
    cmp rbx, 26
    jge .used_done
    cmp byte [used+rbx], 0
    je .next
    mov al, bl
    add al, 'a'
    call print_char
    mov al, ' '
    call print_char
.next:
    inc rbx
    jmp .used
.used_done:

    ; erreurs x/6
    mov rsi, msg_err
    call print_z
    mov rax, [errors]
    add al, '0'
    call print_char
    mov rsi, msg_max
    call print_z

    ; message eventuel (lettre invalide, deja jouee...)
    mov rsi, [status]
    test rsi, rsi
    jz .end
    call print_z
.end:
    ret

; -------------------------------------------------------------
_start:
.game:
    call new_game
.loop:
    call draw
    mov rsi, msg_prompt
    call print_z
    call read_line
    test rax, rax
    jle quit                    ; Ctrl+D -> on quitte
    mov qword [status], 0

    ; --- validation de la saisie ---
    mov al, [inbuf]
    cmp al, 'A'
    jb .invalid
    cmp al, 'Z'
    jbe .upper
    cmp al, 'a'
    jb .invalid
    cmp al, 'z'
    ja .invalid
    jmp .valid
.upper:
    add al, 32                  ; majuscule -> minuscule
.valid:
    movzx rbx, al
    sub rbx, 'a'
    cmp byte [used+rbx], 0
    jne .already
    mov byte [used+rbx], 1

    ; --- recherche de la lettre dans le mot ---
    mov rsi, [word_ptr]
    xor rcx, rcx
    xor rdx, rdx                ; rdx = 1 si trouvee
.search:
    cmp rcx, [word_len]
    jge .search_done
    cmp [rsi+rcx], al
    jne .search_next
    mov byte [found+rcx], 1
    mov rdx, 1
.search_next:
    inc rcx
    jmp .search
.search_done:
    test rdx, rdx
    jnz .check_win
    inc qword [errors]
    cmp qword [errors], MAX_ERR
    jge .lose
    jmp .loop

    ; --- toutes les lettres trouvees ? ---
.check_win:
    xor rcx, rcx
.cw:
    cmp rcx, [word_len]
    jge .win
    cmp byte [found+rcx], 0
    je .loop
    inc rcx
    jmp .cw

.invalid:
    mov qword [status], msg_inval
    jmp .loop
.already:
    mov qword [status], msg_already
    jmp .loop

    ; --- fin de partie ---
.win:
    call draw
    mov rsi, msg_win
    jmp .end
.lose:
    call draw
    mov rsi, msg_lose
.end:
    call print_z
    mov rsi, [word_ptr]
    call print_z
    mov rsi, msg_reset
    call print_z
    mov rsi, msg_again
    call print_z
    call read_line
    test rax, rax
    jle quit
    mov al, [inbuf]
    or al, 32                   ; 'O' -> 'o'
    cmp al, 'o'
    je .game

quit:
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall
