# MyBash

## Integrantes: 
- Damian Feigelmuller
    - damian.feigelmuller@mi.unc.edu.ar

- Cristian Ariel Muñoz
    - cristian.munoz@mi.unc.edu.ar

- Santiago Torres
    - santitorres460@mi.unc.edu.ar

- Santiago Troiano
    - stroiano@mi.unc.edu.ar 

## Librerias Destacadas:
- glib-2.0/glib.h
- limits.h
- string.h
- unistd.h
- fcntl.h

## Proceso De Desarrollo

### TADs scommand y pipeline
Para empezar, lo primero que se hizo fue el módulo command, que contenía los TADs "scommand" y "pipeline".

La estructura utilizada para scommand fue una struct con 3 espacios, el primero una lista de strings los cuales serian los comandos con sus argumentos, el segundo y el tercero, también 2 strings los cuales especificarían la ruta de redirección de input/output, respectivamente.
Para el pipeline, usamos de nuevo una struct, pero esta vez tendría una lista de scommands y luego un booleano el cual especificaría si se debe esperar o no, que será de utilidad más adelante en el execute. 

Después de una primera implementación del módulo command, con algunos bugs y memory leaks, nos dividimos el trabajo del resto de módulos. 
Un punto importante a destacar fue la implementación de pipeline_destroy, donde usamos g_list_free_full() la cual requería de una función de tipo destroy para liberar la memoria de cada elemento de la lista. Fue necesario implementar una función auxiliar que matchee con el tipo requerido de la función en g_list_free_full() ("void_scommand_destroy").

Por último, se añadió la función scommand_to_array(), la cual seria de utilidad en el módulo execute.

### Parsing
Se hicieron algunos prototipos y al final se terminó con una versión más robusta y funcional que pasaba el test.
Después de integrar y ejecutar todo el programa, se encontró un error en el caso de que el input sea vacío, se debía hacer un parse_garbage() y no se realizaba nada.
Por último, se añadieron soluciones a casos bordes para evitar más problemas de este tipo.

### Builtin y Execute
Se realizó el módulo builtin antes que el módulo execute para hacernos una idea más clara, ya que este último debe hacer uso del primero.
Fueron hechos casos bordes del comando cd. Los comandos exit y help fueron implementados sin problemas.

El módulo execute tuvo que ser rehecho 2 veces, ya que faltaba conocimiento de las syscalls necesarias. 
Luego del martes 06/09, donde se dio la clase de las syscalls se pudieron reordenar las ideas y hacer avances hacia la funcionalidad del módulo. 
Se añadieron casos de redirección de input/output y se utilizó la syscall pipe() en el caso de una pipeline con 2 comandos. 
Se añadieron 2 funciones las cuales se encargarían de redireccionar el input/output (una función para c/u) 
Utilizando la función scommand_to_array(), fue fácil manejar los parámetros que tomaría la syscall execvp().
Por último, estuvo el problema de los procesos zombie. Para solucionar esto, después de que se ejecuten los 2 procesos hijos, se hizo ignorar la señal de estos con la syscall signal()

### MyBash
Una vez terminado todos los módulos se completo el módulo principal con una llamada a execute_pipeline() y luego a pipeline_destroy(). Por último se mejoró el aspecto visual del prompt el cual imprimiría por pantalla
1.- Username
2.- Hostname
3.- Directorio Actual
Al igual que el GNU bash

### Comandos testeados
- cd
- cd ..
- cd ~/Documents

- ls -l | wc -c

- grep name /proc/cpuinfo > out.txt
- cat out.txt
- wc < out.txt
- rm out.txt

- xeyes &

- touch test.txt
- wc < text. txt > out.txt

- ls > out.txt | wc < in.txt

- touch tarTest.txt
- tar -czvf tarTest.tar.gz tarTest.txt

- ./mybash








