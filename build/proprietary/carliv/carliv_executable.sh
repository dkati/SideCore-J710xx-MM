#!/bin/bash
e="\x1b[";c=$e"39;49;00m";y=$e"93;01m";cy=$e"96;01m";r=$e"1;91m";g=$e"92;01m";m=$e"95;01m";
##########################################################
#                                                        #
#           Carliv Image Kitchen for Android             #
#     boot+recovery images copyright-2016 carliv@xda     #
#    including support for MTK powered phones images     #
#                                                        #
##########################################################
bin="$PWD/.bin";
working="$PWD/.working";
scripts="$PWD/.scripts";
find "$bin" "$scripts" -type f ! -name "*.*" -exec chmod +x {} \;
cd "$PWD";
###########################################################



boot()
{

###########################################################
echo " ";
cd boot-resources;
grep_boot1="$(find . -maxdepth 1 -type f | grep -i \\.img$ | sed 's/ /ftemps/g' 2>/dev/null)";
grep_boot="$(echo $grep_boot1 | sed -e 's/\.\///g' | sort -f)";
cd ../;
if [ "$grep_boot" == "" ];
then
  printf %s "There is no image in your [boot-resources] folder. Place some in there and then press [B] to start again or [Q] to go to main menu, then press ENTER!"
  read bchoice;
  if [[ "$bchoice" = "B" || "$bchoice" = "b" ]]; 
	then
	boot;
  elif [[ "$bchoice" = "Q" || "$bchoice" = "q" ]]; 
	then
	main;
  else
	echo "$bchoice is not a valid option";  boot;
  fi;
fi;
count=0;
for filename in $grep_boot
 do
 count=$(($count+1));
 filename="$(echo $filename | sed 's/ftemps/ /g')";
 file_array[$count]="$filename";
  echo "  $count. - $filename";
  echo "---------------------------------------------------";
done
benv=1;

if [ "$(echo $benv | sed 's/[0-9]*//')" == "" ] || [ "benv"=="none" ];
	then
	  file_chosen=${file_array[$benv]};
	  if [ "$file_chosen" == "" ];
      then
        wrongbs;
      else
        workfile="$file_chosen";
      fi;
	else
	  wrongbs;
fi;
yes | cp -f boot-resources/"$workfile" "$working"/"$workfile";
filetype=bootimage;


echo " ";
echo " ";
echo -e "Your selected image is$g $workfile$c"; 
if [[ "$workfile" == *boot* || "$workfile" == *recovery* ]];
	then
	  wfolder="${workfile%.*}";
	else	  
		if [[ "$filetype" = "bootimage" ]];
			then
			wfolder=boot-"${workfile%.*}";
		else
			wfolder=recovery-"${workfile%.*}";
		fi;
fi;
echo " ";
if [ -d "$wfolder" ]; 
	then
	echo -e "The folder for repack will be$g $wfolder$c";
	echo "Make sure that the folder exists and you didn't delete it, because if you did, it will display an error message.";
	echo " ";	
fi;
img_repack;
}

img_repack()
{
if [ -d "$wfolder" ]; 
	then
	"$scripts"/repack_img "$wfolder";
	else
	echo -e "The folder for repack $g $wfolder$c doesn't exists. Are you sure you didn't delete it?";
fi;

echo "Renaming kernel..."
cd output
cp -r boot* boot.img
rm -rf boot_*
cd ..
echo "Ready..."

}

main()
{ 
echo " ";
boot;
}


main;

