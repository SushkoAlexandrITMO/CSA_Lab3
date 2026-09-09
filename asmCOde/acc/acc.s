.data

input_addr:      .word  0x0080               ; Адресс ввода
output_addr:     .word  0x0084               ; Адресс вывода
result:          .word  0x0000               ; Результат
range:           .word  0x0020               ; Размерность цикла обработки
buffer:          .word  0x0000               ; Буфер для хранения промежуточных данных
check:           .word  0x0001               ; Проверка значения правого бита
cicle_step:      .word  0x0001               ; Шаг цикла проверки

.text

_start:
    load_addr input_addr
    load_acc
    store_addr buffer
    jmp do_check

do_check:
    load_addr range                        ; Загрузили кол-во итераций цикла
    beqz end                               ; Если итераций не остлось - цикл завершён
    sub cicle_step                         ; Если нет - уменьшаем на 1 и выгружаем
    store_addr range
    load_addr buffer                       ; Загружаем число
    and check                              ; Проверяем правый бит
    bnez inc_result                        ; Если 1, то увеличиваем результат
    jmp cicle_shift

inc_result:                                ; Увеличение результат на 1
    load_addr result
    add cicle_step
    store_addr result
    jmp cicle_shift

cicle_shift:                               ; Сдвиг битов числа
    load_addr buffer
    shiftr cicle_step
    store_addr buffer
    jmp do_check

end:                                       ; Остановка выполнения, выгрузка результата
    load_addr result
    store_ind output_addr
    halt