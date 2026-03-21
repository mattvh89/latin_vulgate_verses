#!/usr/bin/bash
# Author: Matthew Van Helden
# Date: March 21, 2026
#
# Christ is King

readonly new_testament=("Matthew" "Mark" "Luke" "John" "Acts" "Romans" "1Cor" "2Cor" "Galatians" "Ephesians" "Phillipians" "Colossians" "1Thes" "2Thes" "1Timothy" "2Timothy" "Titus" "Philemon" "Hebrews" "James" "1Peter" "2Peter" "1John" "2John" "3John" "Jude" "Revelation")
readonly old_testament=("Genesis" "Exodus" "Leviticus" "Numbers" "Deuteronemy" "Joshua" "Judges" "Ruth" "1Samual" "2Samual" "1Kings" "2Kings" "1Chronicles" "2Chronicles" "Ezra" "Nehemia" "Tobit" "Judith" "Esther" "Job" "Psalms" "Proverbs" "Ecclesiastes" "Solomen" "Wisdom" "Sirach" "Isiah" "Jeremiah" "Lamentations" "Baruch" "Ezekial" "Daniel" "Hosea" "Joel" "Amos" "Obediah" "Jonah" "Micah" "Nahum" "Habakkuk" "Zephania" "Haggai" "Zacharia" "Malachi" "1Maccabees" "2Maccabees")

book_index=0
book=""
chapter=0
verse=""
end_verse=0
testament=0
bool_old_testament=0
bool_new_testament=0
bool_list_chapters=0

# Function to print the usage of the script

function help
{
	echo "\
	Usage: $0 [options] [book [chapter [verse[-end_verse]]]]

	Options:
	  -s \"search terms\"     Search DuckDuckGo for a Bible verse matching the terms
	  -h                     Display this help message

	Arguments (if no options):
	  book                   Name of the book (e.g., Genesis)
	  chapter                Chapter number (optional)
	  verse                  Single verse (optional) or range (e.g., 3-5) or open-ended (e.g., 7-)
	                         If verse is omitted, retrieves the whole chapter
	Examples:
	  $0                          Prompt for input interactively
	  $0 Genesis                  Retrieves the whole Book of Genesis
	  $0 Genesis 1                Retrieves Genesis chapter 1
	  $0 Genesis 1 1              Retrieves Genesis 1:1
	  $0 Genesis 1 1-5            Retrieves Genesis 1:1–5
	  $0 Genesis 1 1-             Retrieves from Genesis 1:1 to the end of the chapter
	  $0 -s \"synagogue of satan\" Searches DuckDuckGo and returns first matching Bible verse
	  $0 -h                        Display this help
"
}

# Function to list all the books in the old and new testament
function print_books
{
	echo
	echo "**** Old Testament ****"
	echo " "
	for book in "${old_testament[@]}"; do
		echo "$book"
	done

	echo
	echo "**** New Testament ****"
	echo " "
	for book in "${new_testament[@]}"; do
		echo "$book"
	done
	exit
}

# If no arguments were given, get user input
if [ $# -eq 0 ]
then
	read -p "Book (? for list): " book
	if [ "$book" == "?" ]; then
		print_books
		exit
	fi
	read -p "Chapter: " chapter
	read -p "Verse(s): " verse

# Else if 1 argument was given, either list the books, give help string, 
# or we're getting the list chapters in the book
elif [[ $# -eq 1 ]];  then
	case $1 in
		"?")
			print_books
			exit
			;;
		"-h")
			help
			exit
			;;
	esac


	book=$1
	chapter=1
	verse="1-"
	((++bool_list_chapters))

# Else if 2 arguments were given, we want the whole entire chapter. Set it up
# by setting verse to "1-"
elif [[ $# -eq 2 ]]; then
	if [[ $1 == "-s" ]]; then
		search_input="bible verse $2"
		search_term="${search_input// /+}"

		book_chapter_verse=$(ddgr --json "$search_input" \
		| jq -r '.[] | select(.url | test("bible|scripture|vulgate"; "i")) | .title' \
		| grep -oE '[1-3]?[A-Za-z]+[[:space:]]+[0-9]+:[0-9]+' \
		| head -n1)

		book_chapter_verse="${book_chapter_verse//:/ }"

		book=$(echo $book_chapter_verse | awk '{print $1}')
		chapter=$(echo $book_chapter_verse | awk '{print $2}')
		verse=$(echo $book_chapter_verse | awk '{print $3}')

		echo "$book $chapter:"

	else
		book=$1
		chapter=$2
		verse="1-"
	fi

# Otherwise we have a fully formed verse request
elif [[ $# -eq 3 ]]; then
	book=$1
	chapter=$2
	verse=$3

# If it's something else, print help message and quit
else
	help
fi

##########################################################################
#									 #
#		Done getting input. Now process			         #
#								  	 #
##########################################################################
# 1. Find whether the book is in the old testament or new testament
# 2. Set book index  and testament variable, 0 for old, 1 for new
# 3. Set the url using the testament, book, chapter variables
# 4. Download the page
# 5. Process the html page for the verse(s) we want

index=0
# 1. search for name of book in the constant array new_testament
for element in "${new_testament[@]}"; do
	if [[ "$book" == "$element" ]]; then
		((++bool_new_testament))
		break
	fi
	((++index))
done

# 1. if it wasn't found in the new testament, check old testament
if [[ $bool_new_testament -eq 0 ]]; then
	index=0
	for element in "${old_testament[@]}"; do
		if [[ "$book" == "$element" ]]; then
			((++bool_old_testament))
			break
		fi
		((++index))
	done
fi

# 2. if it was found in the new or old testament, set the index, else  display error and quit
if [[ $bool_new_testament -ne 0 || $bool_old_testament -ne 0 ]]; then
	book_index=$((index + 1))
else
	echo "$book not found"
	echo "    Enter ? for book to get list of books"
	exit

fi


# 2. Set the testament variable, 0 is old testament, 1 is new testament
if [[ $bool_new_testament -eq 1 ]]; then
	((++testament))
fi

# 3. Set the url using testament, book and chapter
url="http://latinvulgate.com/verse.aspx?t=$testament&b=$book_index&c=$chapter"

# 4. download the page using curl and strip all html tags
page=$(curl -s "$url" | sed 's/<[^>]*>//g')

if [[ $bool_list_chapters -eq 1 ]]; then
	grep -m1 "^chapters:" <<< "$page" # | sed 's/chapters:[[:space:]]*//'
	exit
fi

# 5. if we were given a range i.e. 1-5
if [[ $verse =~ ^[0-9]+-[0-9]+$ ]]; then
	IFS='-' read verse end_verse <<< $verse

# 5. else if we want a verse to the end of the chapter i.e. 25-
elif [[ $verse =~ ^([0-9]+)-$ ]]; then
	verse=${BASH_REMATCH[1]}
	end_verse=$(grep -oE "^[[:space:]]*$chapter[0-9]+" <<< "$page" \
        	   | sed "s/^[[:space:]]*$chapter//" \
	           | tail -1)

# 5. else we want just 1 verse
else
	end_verse=$verse
fi

for((i=verse; i<=end_verse; ++i)); do
	echo "$i"
	echo "$page" \
	| grep -E "^[[:space:]]*$chapter$i([^0-9]|$)" \
	| sed "s/^[[:space:]]*$chapter$i//" \
	| sed 's/\([.?!:]\)\([a-z]\)/\1\n\2/'
	echo
done

exit
