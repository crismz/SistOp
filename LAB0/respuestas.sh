#_Ejercicio1_
cat /proc/cpuinfo | grep "model name"  

#_Ejercicio2_
cat /proc/cpuinfo | grep "model name" | wc -l

#_Ejercicio3_
curl https://www.gutenberg.org/files/11/11-0.txt | sed 's/Alice/Cristian/g' | sed 's/ALICE/CRISTIAN/g' > Cristian_in_wonderland.txt

#_Ejercicio4_
sort -k 5 -n weather_cordoba.in | head -n 1 | awk '{printf "Minima %u/%u/%u \n", $3, $2, $1}' && sort -k 5 -n weather_cordoba.in | tail -n 1 | awk '{printf "Minima %u/%u/%u \n", $3, $2, $1}'

#_Ejercicio5_
# Se puede agregar "-o atpplayers.in" para que reemplace el archivo con los datos ordenados por ranking
sort -k 3 -n atpplayers.in

#_Ejercicio6_
# Hacemos una columna extra que tenga la diferencia de goles con awk
# Ordenamos segun puntos y diferencia de goles
# Sacamos la ultima columna con la diferencia de goles
awk '{printf "%s %s\n", $0, ($7 - $8)}' superliga.in | sort -n -k 2 -k 9 -r | awk '{NF--;print}'

#_Ejercicio7_
ip addr | grep 'link/ether ..:..:..:..:..:..'

#_Ejercicio8_
#a)
mkdir fma | touch fma_S01E{01..10}_es.srt && mv fma_S01E{01..10}_es.srt fma/
#b)
for f in *_es*; do mv -- "$f" "${f%_es.srt}.srt"; done


