#!/usr/bin/sh

readFile ()
{
	grep -wo '[[:graph:]]\+' $file | tr '[:upper:]' '[:lower:]' |
	awk ' $1+0 == 0 ' | #https://www.unix.com/shell-programming-and-scripting/168198-remove-numbers-file.html
	sort | uniq -c | sort -nr | nl
}

readFileStopwords ()
{
	grep -wo '[[:alnum:]]\+' $file | tr '[:upper:]' '[:lower:]' |
	fgrep -ivwf StopWords/$language.stop_words.txt | awk 'length!=1' | awk ' $1+0 == 0 ' |
	sort | uniq -c | sort -nr | nl
}

verifyWORD_STATS_TOP ()
{
	if [ -z "$WORD_STATS_TOP" ]
	then
		echo "Environment variable 'WORD_STATS_TOP' is empty (using default 10)\n"
		WORD_STATS_TOP=10

		elif ! [ "$WORD_STATS_TOP" -eq "$WORD_STATS_TOP" ] 2> /dev/null #https://stackoverflow.com/questions/806906/how-do-i-test-if-a-variable-is-a-number-in-bash
		then
			echo "'$WORD_STATS_TOP' not a number (using default 10)\n"
			WORD_STATS_TOP=10
				
		else
		echo "WORD_STATS_TOP=$WORD_STATS_TOP\n"		
	fi
}

if [ -z "$1" ] || [ -z "$2" ];
then
	echo "\n[ERROR] insufficient parameters"
	echo "$0 Cc|Pp|Tt INPUT [iso3166]\n"

else

	if [ ! -f "$2" ]
	then
		echo "\n[ERROR] can't find file '$2'\n"
	else
		
		if [ $1 = c ] || [ $1 = C ] || [ $1 = p ] || [ $1 = P ] || [ $1 = t ] || [ $1 = T ];
		then
	
			if [ $3 = "en" ] || [ $3 = "pt" ];
			then
				language=$3
				
				else
				
				echo "\n[iso3166] is not 'en' or 'pt' (using default 'en')"
				language=en
				
			fi
			
			if [ $(head -c 4 "$2") = "%PDF" ] #https://stackoverflow.com/questions/16152583/tell-if-a-file-is-pdf-in-bash
			then 
				echo "\n'$2' : PDF file"
				echo "[INFO] Processing '$2.txt'"
				pdftotext "$2" "result---$2.txt"
				file=result---$2.txt
			
			else
			
				echo "\n'$2' : TXT file"
				echo "[INFO] Processing '$2'"
				file=result---$2	
				touch $file
			fi
		else
			echo "\n[ERROR] unknown command '$1'\n"
		
		fi

		if [ $1 = "c" ];
		then
			echo "\nSTOP WORDS will be filtered out"
			
			words=$(wc -w < StopWords/$language.stop_words.txt)
			echo "StopWords file '$language' : 'StopWords/$language.stop_words.txt' ($words words)\n"
			echo "COUNT MODE\n"

			readFileStopwords
	
			echo "\nRESULTS: '$file'"
			ls -la "$file"
		
 			total=$(awk '{for(i = 1; i <= NF; i++) {a[$i]++}} END {for(k in a) if(a[k] == 1){total++} print ""total ""}' $file) #https://www.quora.com/How-do-I-count-the-number-of-unique-words-in-a-file-in-Unix
 			echo "$(($total-$words)) distinct words\n"
		fi

		if [ $1 = "C" ];
		then
			echo "\nSTOP WORDS will be counted\n"
			echo "COUNT MODE\n"
	
			readFile
	
			echo "\nRESULTS: '$file'"
			ls -la "$file"
	
 			awk '{for(i = 1; i <= NF; i++) {a[$i]++}} END {for(k in a) if(a[k] == 1){total++} print ""total " distinct words\n"}' $file
	
		fi

		if [ $1 = "p" ];
		then
			echo "\nSTOP WORDS will be filtered out"
			words=$(wc -w < StopWords/$language.stop_words.txt)
			echo "StopWords file '$language' : 'StopWords/$language.stop_words.txt' ($words words)\n"
			
			verifyWORD_STATS_TOP
			
			readFileStopwords | head -$WORD_STATS_TOP > $file.dat 
			
			date=$(date)
			
			gnuplot -e "set title 'Top words for $2
Created: $date
($language stopwords removed)';
			set grid;
			set ylabel 'number of occurrences';
			set xlabel 'words' offset 2.5,0;
			set border 10;
			set terminal 'png' size 1000,1000;
			set output 'result---ficha01.pdf.txt.png';
			set boxwidth 0.5;
			set style fill solid;
			plot 'result---ficha01.pdf.txt.dat' using 1:2:xtic(3) with boxes title '# of occurrences';"
			
			echo "
			<html>
				<head>
					<title>Top $WORD_STATS_TOP words - '$2'</title>
				</head>
				<body>
					<h1>Top $WORD_STATS_TOP words - '$2'</h1>
					<img src=$file.png></img>
					<bottom><p> Authors: Rodrigo Capitão, Samuel Ferraz</p>
					<p> Created: $date</bottom>
				</body>
			</html>" > $file.html
			
			ls -la "$file.dat"
			ls -la "$file.png"
			ls -la "$file.html"
			
			echo ""
		fi

		if [ $1 = "P" ];
		then
			echo "\nSTOP WORDS will be counted\n"
			verifyWORD_STATS_TOP
			
			readFile | head -$WORD_STATS_TOP > $file.dat 
			
			date=$(date)
			
			gnuplot -e "set title 'Top words for $2
Created: $date
(with stopwords)';
			set grid;
			set ylabel 'number of occurrences';
			set xlabel 'words' offset 2.5,0;
			set border 10;
			set terminal 'png' size 1000,1000;
			set output 'result---ficha01.pdf.txt.png';
			set boxwidth 0.5;
			set style fill solid;
			plot 'result---ficha01.pdf.txt.dat' using 1:2:xtic(3) with boxes title '# of occurrences';" #foi retirado do manual do gnuplot alguns comandos para estilizar o gráfico
			
			echo "
			<html>
				<head>
					<title>Top $WORD_STATS_TOP words - '$2'</title>
				</head>
				<body>
					<h1>Top $WORD_STATS_TOP words - '$2'</h1>
					<img src=$file.png></img>
					<bottom><p> Authors: Rodrigo Capitão, Samuel Ferraz</p>
					<p> Created: $date</bottom>
				</body>
			</html>" > $file.html
			
			ls -la "$file.dat"
			ls -la "$file.png"
			ls -la "$file.html"
			
			echo ""
		fi

		if [ $1 = "t" ];
		then
			echo "\nSTOP WORDS will be filtered out"
			words=$(wc -w < StopWords/$language.stop_words.txt)
			echo "StopWords file '$language' : 'StopWords/$language.stop_words.txt' ($words words)\n"
			verifyWORD_STATS_TOP
			ls -la "$file"
	
			echo "\n-------------------------------------"
			echo " # TOP $WORD_STATS_TOP elements\n"

			readFile | head -$WORD_STATS_TOP
	
			echo "-------------------------------------\n"
		fi

		if [ $1 = "T" ];
		then
			echo "\nSTOP WORDS will be counted\n"
			verifyWORD_STATS_TOP
			ls -la "$file"
	
			echo "\n-------------------------------------"
			echo " # TOP $WORD_STATS_TOP elements\n"

			readFileStopwords | head -$WORD_STATS_TOP
		
			echo "-------------------------------------\n"
		fi
	fi
fi