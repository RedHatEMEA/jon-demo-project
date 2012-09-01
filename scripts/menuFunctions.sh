
#function - menuHeader (menuTitle) - outputs the menu title, with *s below and a new line 
function menuHeader () {
	MENU_TITLE=$1
	
	clear
	
	echo $MENU_TITLE
	TITLE_LENGTH=${#MENU_TITLE}
	
	for ((  i = 0 ;  i <= $TITLE_LENGTH;  i++  ))
	do
		echo -ne "-"
	done
	newLine
	newLine	
}

#function - menuFooter (isMainMenu) - outputs the quit, back to main menu and reads the variable
function menuFooter () {
	IS_MAIN_MENU=$1

	newLine
	if [[ "$IS_MAIN_MENU" != "true" ]]; then
		echo B. Back to Main Menu
	fi

	echo "Choose an option (Q to quit):"
}

#function - takeInputOption () - takes in an option as input and <returns> the option 
function takeInputOption() {

	read option
	option=`lowercase $option`
	echo $option	
}

#function - basicMenuOptions (option) - case stmt used at the end of every menu *) options, handles (b)ack, (q)uit and wrong inputs
function basicMenuOptions() {
	option=$1
	
	case $option in
		"q" | "Q" ) 
			quit
			;;

		"b" | "B" ) 
			mainMenu
			;;
		
		*) 
			newLine
			echo Wrong input... please input correct selection
			;;
	esac
	
}