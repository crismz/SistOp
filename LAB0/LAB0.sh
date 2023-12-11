#Ejercicio 1
# cat :Para visualizar el contenido del archivo (cat es de concatenar)
#grep: Para que muestre por pantalla las lineas que contegan esa expresión
cat /proc/cpuinfo | grep "model name"      
# El modelo es Intel(R) Core(TM) i5-4200M CPU @ 2.50GHz

#Ejercicio 2
# wc (word count) es un comando utilizado que permite realizar diferentes conteos desde la entrada estándar,
# ya sea de palabras, caracteres o saltos de líneas. 
# Ejemplo $ cat /etc/passwd | grep /home | wc -l 
cat /proc/cpuinfo | grep "model name" | wc -l

#Ejercicio 3
# wget o curl para descargar el archivo
# sed sirve para reemplazar o borrar expresiones en un archivo (en este caso debido a las pipes lo que tira el curl)
# Con la redirección > le damos de entrada lo que devuelve sed y por eso lo guarda en el archivo .txt
curl https://www.gutenberg.org/files/11/11-0.txt | sed 's/Alice/Cristian/g' | sed 's/ALICE/CRISTIAN/g' > Cristian_in_wonderland.txt

#Ejercicio 4
# Para ordenar un archivo usamos sort (-k para seleccionar columna para archivos tipo CSV, -n para ordenar numericamente)
# head para buscar la primer linea
# tail para buscar la ultima linea
# awk sirve para buscar en un archivo e imprimir lo que se necesite (Ver en internet)
sort -k 5 -n weather_cordoba.in | head -n 1 | awk '{printf "Minima %u/%u/%u \n", $3, $2, $1}' && sort -k 5 -n weather_cordoba.in | tail -n 1 | awk '{printf "Minima %u/%u/%u \n", $3, $2, $1}' 

#Ejercicio 5
sort -k 3 -n atpplayers.in # -o atpplayers.in 

#Ejercicio 6
# Hacemos una columna extra que tenga la diferencia de goles con awk
# Ordenamos segun puntos y diferencia de goles
# Sacamos la ultima columna con la diferencia de goles
awk '{printf "%s %s\n", $0, ($7 - $8)}' superliga.in | sort -n -k 2 -k 9 -r | awk '{NF--;print}'

#Ejercicio 7
ip addr | grep 'link/ether ..:..:..:..:..:..'

#Ejercicio 8
#a)
# "mkdir fma" crear la carpeta, touch los archivos y mv mueve los archivos a la carpeta fma
mkdir fma | touch fma_S01E{01..10}_es.srt && mv fma_S01E{01..10}_es.srt fma/

#b)
# The first line instructs the script to search for all the files in the current directory that have _es in its name.
# The second line uses the mv command on each file found to replace the _es.srt extension with .srt.
# The third line ends the loop segment.
for f in *_es*; do mv -- "$f" "${f%_es.srt}.srt"; done
