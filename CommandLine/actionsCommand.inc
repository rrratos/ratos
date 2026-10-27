 msgHelpShort      db "Short Description of Commands:/n/color[1A]", \
                      "==============================/n/color[1B]", \
                      "HELP ([l] or [s]) - displays information about commands,/n", \
                      "parameter S (required) - short, parameter L - long/n", \
                      "==============================/n", \
                      "RUN ([R]) - compiles (or executes) the code entered in the listing,/n", \
                      "parameter R - compiles and executes the code/n", \
                      "==============================/n", \
                      "EXIT ([S])- exits the operating system or program,/n", \
                      "parameter S - does not save data", \
                      "==============================/n", \
                      "PRINT ([MSG]) - displays the message entered by the user,/n", \
                      "parameter msg - message/n", \
                      "==============================/n", \
                      "BELL ([d]) - emits a sound for a specified time,/n", \
                      "parameter D - time in microseconds/n", \
                      "==============================/n", \
                      "INFO ([OS] or [CPU]) - displays information about the given topic in the parameter, /n", \
                      "parameter OS - operating system information, parameter CPU - processor information /n", \
                      "==============================/n", \
                      "HELLO - displays the message Hello world/n", \
                      "==============================", 0


 ; список:
 ; --дополнительные форматирующие параметры в print
 ; ---- color[hex] - цвет
 ; ---- delay[delay] - задержка вывода символов
 ; ---- wait[ms] - не выводить символы до определенного момента
 ; ---- blink[yn] - мигание текста