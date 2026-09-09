.data
string:      .byte '________________________________'
zatichka:    .word 0x00
input_addr:  .word 0x80
output_addr: .word 0x84
newline:     .word 0x0A
err_code:    .word 0xCCCCCCCC
has_null:    .word 0          \ Флаг: 1, если встретили \0

.text
_start:
    @p input_addr a!        \ A = 0x80
    lit 0                   \ length = 0

read_loop:
    @                       \ Читаем символ
    dup
    if found_null           \ Если \0 - это конец C строки
    dup
    @p newline xor
    if found_newline        \ Если \n - это конец ввода
    
    over                    \ Проверка overflow
    dup
    lit -31 +
    -if error_exit          \ Если length >= 31 -> ошибка
    over                    \ Возвращаем порядок
    
    >r                      \ Символ кидаем в rStack
    lit 1 +                 \ length++
    read_loop ;

found_null:
    lit 1 !p has_null       \ записываем, что нашли \0

found_newline:
    drop                    \ Убираем \n или \0 со стека

setup_write:
    lit 0 a!                \ A = 0 (буфер в памяти)
    @p output_addr b!       \ B = 0x84 (порт вывода)

write_loop:
    dup
    if write_done           \ Если length == 0 -> конец реверса
    r>                      
    dup !+                  
    !b                      \ Вывод в 0x84
    lit -1 +                \ length--
    write_loop ;

write_done:
    drop                    \ Убираем length
    lit 0 !+                \ Пишем null-terminator в память
    
    @p has_null             
    if finish_pad           \ Если \0 не было, переходим к финализации

    @p input_addr b!        \ B = 0x80
    
read_rest_loop:
    @b                      \ Читаем символ
    dup
    @p newline xor
    if read_rest_done       \ Если \n -> конец
    
    a                       \ Проверка переполнения для остатка
    lit -31 +
    -if error_exit
    
    !+                      
    read_rest_loop ;

read_rest_done:
    drop                    \ Убираем \n
    lit 0 !+                \ Записываем \0

finish_pad:
    lit 0x5f5f5f5f !        \ Записываем затычку
    halt

.org 140
error_exit:
    @p output_addr b!       \ B = 0x84
    @p err_code !b          \ Выводим ошибку
    halt
