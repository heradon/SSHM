#!/usr/bin/env bash

version="1.47"
# Directory remotegui uses for all its files, w/o a trailing, but with a startig slash, e.g. /home/florian
dir="$HOME/.remotegui"

# Directory we may use for temporary files
tmp="/tmp"

#=============================================================#
# End of the user-changeable settings
#=============================================================#

dialog --stdout --backtitle "remotegui V$version" --title "Loading..." --infobox "Please wait...
Starting up" 0 0

#=============================================================#

debug=0
N="
"
OLDIFS="$IFS"

license="remotegui - a gui to connect to ssh and telnet servers
License: GNU GPL v3 or later at your option
Author:  Florian Bruhin (The Compiler) <florianbruh@gmail.com>
Mod: Ralf Matthes <info@rmatthes.de>
version: $version
Copyright 2009 Florian Bruhin
Copyright 2016 Ralf Matthes

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details."

about="remotegui - a gui to connect to ssh and telnet servers
License: GNU GPL v3 or later at your option
Author:  Florian Bruhin (The Compiler) <florianbruh@gmail.com>
Mod: Ralf Matthes <info@rmatthes.de>
version: $version
Copyright 2009 Florian Bruhin
Copyright 2016 Ralf Matthes"

#=============================================================#

[ ! -e "$dir" ] && mkdir "$dir"

#=============================================================#

echo "$*" | grep -q "debug" && debug=1	# debug - display some internal info
echo "$*" | grep -q "nolist" && nolist=1
echo "$*" | grep -q "noservers" && noservers=1

#=============================================================#

[ ! -e "$dir/.started" ] && dialog --stdout --backtitle "remotegui V$version" --title "Welcome!" --msgbox "
Welcome to remotegui by Florian Bruhin / The Compiler <florianbruh@gmail.com> modified by Ralf Matthes <info@rmatthes.de>

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. Choose 'license' in the menu for more details.

If you experience any bugs/errors PLEASE write me a mail to florianbruh@gmail.com. Same goes for critism, suggestions, questions, thankgivings or anything else you want me to know of course.

-- The Compiler" \
0 0 && >"$dir/.started"

#=============================================================#

# File format/columns (tab-separated):
# Protocol	User	Server	Port	Options

if [ -z "`ls "$dir"`" -o "$noservers" = 1 ]; then
	dlg="\"\" \"No servers\""
elif [ "$nolist" = 1 ]; then
	dlg="\"foo\" \"bar\""
else
	IFS="$N"	
	cd "$dir"
	for i in *; do
		IFS="	"
		line=`cat "$dir/$i"`
		set -- $line
		dlg="$dlg \"$i\" \"$1: $2@$3:$4\""
	done
	IFS="$OLDIFS"
fi

#=============================================================#

while :; do
	if [ "$nodlg" != 1 ]; then
		eval dlginput=\`dialog --stdout --help-button --help-label "\"Menu\"" --cancel-label "\"Quit\"" --ok-label "\"Connect\"" --backtitle "\"remotegui V$version\"" --title "\"Choose Server\"" --menu "\"\"" 0 60 0 $dlg\`
		status="$?"
	else
		nodlg=
	fi

	case $status in
		1|255) exit 0 ;; # cancel/esc
		#=============================================================#
		0) # connect
			if [ ! -z "$dlginput" ]; then # No Servers
				for i in cmd server user port opt; do eval cmd$i=; done
				line=`cat "$dir/$dlginput"`
				IFS="	"
				set -- $line
				IFS="$OLDIFS"
				case "$1" in
					SSH)
						[ "$2" != 0 ] && user="$2" || user=
						[ "$3" != 0 ] && port="-p $4" || port=
						[ "$5" != 0 ] && opt="$5" || opt=
						cmd="ssh $port $opt $user@$3"
						;;
					Telnet)
						[ "$2" != 0 ] && user="-l $2 " || user=
						[ "$3" != 0 ] && port="$4" || port=
						[ "$5" != 0 ] && opt="$5" || opt=
						cmd="telnet $user $opt $3 $port"
						;;
				esac
				eval "$cmd" 2\>$tmp/remoteguilog
				#=============================================================#				
				sed -i "/Connection to .* closed./d;/Connection closed by foreign host./d" $tmp/remoteguilog # Remove uninterresting parts out of the error log, maybe more to remove???
				if [ -s $tmp/remoteguilog ]; then
					dialog --backtitle "remotegui V$version" --title "Error" --yes-label "View" --no-label "Don't view" --yesno "Oops, we hit an error. If you want to view the error message choose view, use q to quit." 0 0 && less $tmp/remoteguilog
					rm $tmp/remoteguilog
				fi
			fi
			;;
		#=============================================================#
		2) # Menu
			file=`echo "$dlginput" | sed "s/HELP //"`
			if [ -z "$file" ]; then
				args=
			else
				args="\"Edit \\\\\"$file\\\\\"\" \"\" \"Delete \\\\\"$file\\\\\"\" \"\" \"Copy \\\\\"$file\\\\\"\" \"\" \"Change type of \\\\\"$file\\\\\"\" \"\" \"\" \"\""
			fi

			eval dlginput2=\`dialog --stdout --backtitle \""remotegui V$version"\" --title \""Menu"\" --menu \""$file"\" 0 0 0 \
				$args \
				\""Add new profile"\" \"\" \
				\""Show License"\" \"\" \
				\""About remotegui"\" \"\"\`
			case "$dlginput2" in
				#=============================================================#
				"Edit \"$file\"")
					if [ ! -z "$file" ]; then
						line=`cat "$dir/$file"`
						IFS="	"
						set -- $line
						type="$1"
						user="$2"
						server="$3"
						port="$4"
						args="$5"
						IFS="$OLDIFS"
						fail=1
						while [ "$fail" = 1 ]; do
							fail=
							dlginput2=`dialog --stdout --backtitle "remotegui V$version" --title "Menu" --form "Enter the Server info. Please don't use backslash, backtick, hypen and tab." 0 0 0 \
								"Name" 1 1 "$file" 1 12 33 32 \
								"User" 2 1 "$user" 2 12 33 32 \
								"Server" 3 1 "$server" 3 12 33 256 \
								"Port" 4 1 "$port" 4 12 5 5 \
								"Other $type arguments" 5 1 "$args" 6 1 44 43`
							status="$?"
							IFS="$N"
							set -- $dlginput2
							IFS="$OLDIFS"
		
							case $status in
								1|255)
									fail=
									nodlg=1
									status=2
									;;
								*)
									#[ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" -o "$1" = 0 -o "$3" = 0 -o "$1" = ".copying" ] && fail=1
									if [ "$fail" = 1 ]; then
										dialog --stdout --backtitle "remotegui V$version" --title "Error" --msgbox "There was an error somewhere. Maybe you left something empty (enter 0 for unused values) or the profile already exists?" 0 0
									else
										echo "$type	$2	$3	$4" > "$dir/$file"
										[ "$file" != "$1" ] && mv "$dir/$file" "$dir/$1"
										dlg=`echo "$dlg" | sed "s/\"$file\" \"$type: $user@$server:$port\"/\"$1\" \"$type: $2@$3:$4\"/g"`
									fi
									;;
							esac
						done
					fi
					;;
				#=============================================================#
				"Delete \"$file\"")
					if [ ! -z "$dlginput" ]; then
						dialog --stdout --backtitle "remotegui V$version" --title "Delete" --yesno "Really delete $file?" 0 0
						case $? in
							1|255)
								nodlg=1
								status=2
								;;
							*)
								line=`cat "$dir/$file"`
								IFS="	"
								set -- $line
								IFS="$OLDIFS"
								dlg=`echo "$dlg" | sed "s/\"$file\" \"$1: $2@$3:$4\"//g"`
								rm -f "$dir/$file"
								;;
						esac
					fi
					;;
				#=============================================================#
				"Copy \"$file\"")
					if [ ! -z "$dlginput" ]; then
						fail=1
						while [ "$fail" = 1 ]; do
							fail=
							dlginput2=`dialog --stdout --backtitle "remotegui V$version" --title "Copy" --inputbox "New filename?" 0 0 "$file"`
							case $? in
								1|255)
									fail=
									nodlg=1
									status=2
									;;
								*)
									if [ -e "$dir/$dlginput2" ]; then
										dialog --stdout --backtitle "remotegui V$version" --title "Copy" --msgbox "$dlginput does already exist." 0 0
										fail=1
									else
										cp "$dir/$file" "$dir/$dlginput2"
										line=`cat "$dir/$file"`
										IFS="	"
										set -- $line
										IFS="$OLDIFS"
										dlg=`"$dlg \"$dlginput2\" \"$1: $2@$3:$4\""//g"`
									fi
									;;
							esac
						done
					fi
					;;
				#=============================================================#
				"Change type of \"$file\"")
					
					if [ ! -z "$file" ]; then
						line=`cat "$dir/$file"`
						IFS="	"
						set -- $line
						IFS="$OLDIFS"
						type=`dialog --stdout --default-item "$1" --backtitle "remotegui V$version" --title "Add" --menu "Which type?" 0 0 0 \
						"SSH" "" \
						"Telnet" ""`
						if [ "$type" != "$1" ]; then
							echo "$type	$2	$3	$4	$5" > "$dir/$file"
							dlg=`echo "$dlg" | sed "s/\"$file\" \"$1:/\"$file\" \"$type:/g"`
						fi
					fi
					;;
				#=============================================================#
				"Show License")
					rep=1
					while [ "$rep" = 1 ]; do
						dialog --stdout --yes-label "View full license" --no-label "Back" --backtitle "remotegui V$version" --title "Welcome!" --yesno "$license" 0 0
						case $? in
							1|255)
								nodlg=1
								status=2
								rep=
								;;
							*)
								dialog --stdout --backtitle "remotegui V$version" --title "View License" --msgbox "Press q to quit the license" 0 0
								less "$dir/.copying"
								;;
						esac
					done
					;;
				"Add new profile")
					rep=1
					while [ "$rep" = 1 ]; do
						rep=
						type=`dialog --stdout --backtitle "remotegui V$version" --title "Add" --menu "Which type?" 0 0 0 \
						"SSH" "" \
						"Telnet" ""`
						case $? in
							1|255)
								nodlg=1
								status=2
								;;
							*)
								fail=1
								while [ "$fail" = 1 ]; do			
									fail=
									dlginput2=`dialog --stdout --backtitle "remotegui V$version" \
										--title "Add" --form "Enter the Server info. Please only use A-Z, a-z, 0-9, . , - and _. If you don't want to fill out a field, just enter 0 there." 0 0 0 \
										"Name" 1 1 "" 1 12 33 32 \
										"User" 2 1 "" 2 12 33 32 \
										"Server" 3 1 "" 3 12 33 256 \
										"Port" 4 1 "22" 4 12 5 5 \
										"Other $type arguments" 5 1 "" 6 1 44 43 \
										--infobox "Please wait..." 0 0`
	
									case $? in
										1|255)
											rep=1
											fail=
											;;
										*)
											IFS="$N"
											set -- $dlginput2
											IFS="$OLDIFS"
		
											[ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" -o "$1" = 0 -o "$3" = 0 -o -e "$dir/$1" -o "$1" = ".copying" ] && fail=1
											if [ "$fail" = 1 ]; then
												dialog --stdout --backtitle "remotegui V$version" --title "Error" --msgbox "There was an error somewhere. Maybe you left something empty (enter 0 for unused values) or the profile already exists?" 0 0
											else
												echo "$type	$2	$3	$4	$5" > "$dir/$1"
												dlg="$dlg \"$1\" \"$type: $2@$3:$4\""
											fi
											;;
									esac
								done
								;;
						esac
					done
					;;
				"About remotegui")
					dialog --stdout --backtitle "remotegui V$version" --title "About remotegui" --msgbox "$about" 0 0
					nodlg=1
					status=2
					;;
			esac 
			;;
	esac
done
