.data
; = | + | / | 0-9 | a-z | A-Z
.org 300
upper_l:   .word 65     ; 'A'
lower_l:   .word 97     ; 'a'
digit_l:   .word 48     ; '0'
slash_l:   .word 47     ; '/'
plus_l:    .word 43     ; '+'
equ_l:     .word 61     ; '='

;.org 110
upper_r:   .word 90
lower_r:   .word 122
digit_r:   .word 57
slash_r:   .word 47
plus_r:    .word 43
equ_r:     .word 61

;.org 120
upper_pl:  .word -65
lower_pl:  .word -71
digit_pl:  .word 4
slash_pl:  .word 16
plus_pl:   .word 19
equ_pl:    .word 3

;   
.text
    ;.org 0x300

_start:
    movea.l 200, A7       ; стек
    movea.l 0x80, A0        ; порт ввода
    movea.l 0x84, A1        ; порт вывода
    movea.l 0, A2           ; буфер результата


    ;D4                ; счётчик выходных байт
    ;D3                ; счётчик входных символов
    ;D5                ; буфер_l декодирования входа
    ;D6                ; буфер_r декодирования входа

read_loop:
    cmp.l 64, D3            
    beq error_overflow      ; проверка на переполнение (64 символа)

    clr.l D0
    move.b (A0), D0         ; считали символ
    add.l 1, D3             ; буфер ++
    cmp.l 10, D0            ; если '\n'
    beq finish              ; Конец ввода
    jsr decode_char         ; декодирование
    cmp.l 0, D0             
    blt error               ; Если сивол не верный, то ошибочка
    move.l D0, D5           ; сохранили V1

    clr.l D0
    move.b (A0), D0         ; считали символ
    add.l 1, D3
    cmp.l 10, D0            ; это '\n'?
    beq error_nl            ; да -> длина не кратна 4, '\n' уже изъят
    jsr decode_char
    cmp.l 0, D0
    blt error
    move.l D0, D6           ; сохранили V2

    clr.l D0
    move.b (A0), D0         ; считали символ
    add.l 1, D3
    cmp.l 10, D0
    beq error_nl
    jsr decode_char
    cmp.l 0, D0
    blt error
    move.l D0, D7           ; сохранили V3

    clr.l D0
    move.b (A0), D0         ; считали символ
    add.l 1, D3
    cmp.l 10, D0
    beq error_nl
    jsr decode_char
    cmp.l 0, D0
    blt error
                            ; V4 остался в D0

    ;Сборка ответа (4 символа по 6 бит в 3 символа по 8 в блок ,если по людски)
    lsl.l 6, D5             ; Сдвиг на символ
    or.l  D6, D5            ; добавляем V2
    lsl.l 6, D5             

    cmp.l 64, D7            ; '='
    beq pad_2               ; если конец блока

    or.l  D7, D5            ; добавляем V3
    lsl.l 6, D5             ; 

    cmp.l 64, D0            ; "="
    beq pad_1               ; если конец блока

    or.l D0, D5             ; добавляем V4, D5 = готовые 24 бита

    move.l D5, D1           ; Записали результат
    lsr.l  16, D1
    move.b D1, (A2)+        ; байт 1: биты 23-16

    move.l D5, D1
    lsr.l  8, D1
    move.b D1, (A2)+        ; байт 2: биты 15-8

    move.b D5, (A2)+        ; байт 3: биты 7-0
    add.l  3, D4            ; записали 3 байта
    jmp read_loop           ; читаем следующую группу

pad_2:
    lsr.l 10, D5            ; сдвиг
    move.b D5, (A2)+        ; записываем единственный байт
    add.l 1, D4
    jmp read_loop

pad_1:
    lsr.l 8, D5             ; убираем лишние биты
    move.l D5, D1
    lsr.l  8, D1
    move.b D1, (A2)+        ; байт 1
    move.b D5, (A2)+        ; байт 2
    add.l 2, D4
    jmp read_loop

finish:
    clr.l D0
    move.b D0, (A2)         ; записали нуль-терминатор
    movea.l 0, A2           ; сбросили указатель на начало буфера

output_loop:
    move.b (A2)+, D0        ; считали байт из буфера
    beq end_output          ; если 0, заканчиваем
    move.b D0, (A1)         ; отправили байт в порт вывода
    jmp output_loop

end_output:
    halt

error_nl:
    move.l -1, (A1)         ; '\n' уже изъят -> просто пишем ошибку
    halt

error:
    move.l -1, (A1)         ; записали код ошибки
    jmp consume_nl          ; дочитываем до '\n'

error_overflow:
    move.l 0xCCCCCCCC, (A1)
    halt

consume_nl:
    clr.l D0
    move.b (A0), D0         ; читаем символ
    cmp.l 10, D0            ; '\n'
    beq do_halt             ; да -> всё прочитали
    jmp consume_nl

do_halt:
    halt

decode_char:
    movea.l 300, A3          
    movea.l 324, A4          
    movea.l 348, A5          
    move.l 7, D1

decode_loop:
    sub.l 1, D1
    beq bad_end_decode

    move.l (A3)+, D2        ; левая граница, A3 сдвигается
    cmp.l D2, D0
    bmi first_if_fail

    move.l (A4)+, D2        ; правая граница, A4 сдвигается
    cmp.l D2, D0
    bgt second_if_fail

    jmp good_end_decode

first_if_fail:
    move.l (A4)+, D2        
second_if_fail:
    move.l (A5)+, D2        
    jmp decode_loop

bad_end_decode:
    move.l -1, D0
    rts

good_end_decode:
    move.l (A5), D2        
    add.l D2, D0
    rts