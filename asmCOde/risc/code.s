.data

input_addr:      .word  0x80
output_addr:     .word  0x84

.text

_start:
    lw       t0, 0(output_addr)
    lw       t1, 0(t0)               ; Загрузка n

    addi     t3, zero, 1
    bgt      t3, t1, invalid_input   ; Если n < 1, то записываем ошибку


valid_input:
    add      t1, t1, t3              ; n+1

    addi     t4, zero, 2             ; Записали 2

    div      t2, t1, t4              ; n+1 / 2

    mul      t2, t2, t2              ; Вычисляем квадрат

    bgt      zero, t2, overflow      ; если t2 < 0 (переполнение)

    j        write_result

overflow:
    lui      t2, %hi(0xCCCCCCCC)
    addi     t2, t2, %lo(0xCCCCCCCC)
    j        write_result
    
invalid_input:
    addi     t2, zero, -1

write_result:
    lui      t0, %hi(output_addr)
    addi     t0, t0, %lo(output_addr)
    lw       t0, 0(t0)
    sw       t2, 0(t0)               ; Выгрузили результат

    halt