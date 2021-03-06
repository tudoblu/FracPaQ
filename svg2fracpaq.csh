#!/bin/csh
#####################################################################################
# Shell script to convert a scalable vector graphics file into a text file
# suitable for input into Dave Healy's FracPaQ software
#
##### SVG file example ####
# <?xml version="1.0" encoding="utf-8"?>
# <!-- Generator: Adobe Illustrator 14.0.0, SVG Export Plug-In . SVG Version: 6.00 Build 43363)  -->
# <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
# <svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
#          width="595.28px" height="841.89px" viewBox="0 0 595.28 841.89" enable-background="new 0 0 595.28 841.89" xml:space="preserve">
# <path fill="#DD4B26" stroke="#ED1C24" stroke-miterlimit="10" d="M98.571,410.374"/>
# <line fill="none" stroke="#ED1C24" stroke-miterlimit="10" x1="98.571" y1="410.374" x2="297.64" y2="273.64"/>
# <line fill="none" stroke="#ED1C24" stroke-miterlimit="10" x1="321.701" y1="350.51" x2="444.15" y2="223.979"/>
# <line fill="none" stroke="#ED1C24" stroke-miterlimit="10" x1="187.687" y1="236.905" x2="338.028" y2="168.877"/>
# <line fill="none" stroke="#ED1C24" stroke-miterlimit="10" x1="321.701" y1="260.034" x2="420.34" y2="116.497"/>
#
# On any Linux PC or Mac, copy this file then make executable by typing:
# chmod a+x svg2fracpaq.csh at the command prompt
#
# then place the SVG file in the same folder as svg2fracpaq.csh and then type the following at the command prompt
# 
# svg2fracpaq.csh <infile.svg> 
#
# and hit Enter.
# 
# Written and updated by: D. Cornwell
# Date: 12/9/14, 20-30/11/15, 15-20/2/16
# 18/11/16 - final update before release, commas & tabs
#####################################################################################

set infile = $1

############### NO CHANGES BELOW THIS LINE ##########################################
# remove any old files
#\rm lines* polylines.* remainder.* lineinfo* all.out all_sorted.out all_sorted_no_num.out nearly_there.out

echo "SVG file: "$infile" has been chosen"

set outfile = $1.csv
set outfile2 = $1.txt

# Create a new file with just the lines from the .svg with the string "line" in them
#grep 'line' $infile >! lineinfo
awk '/^.*line/,/>/' $infile >! lineinfo

# Split line file into polylines, lines and the remainder of point info so that it
# can be extracted separately
grep -n '<polyline' lineinfo >! polylines.tmp
grep -n '<line' lineinfo >! lines.tmp
grep -n -v 'line' lineinfo >! remainder.tmp

# Separate out single line polylines (special case)
grep '/>' polylines.tmp >! spolylines.tmp

# Delete single polylines from multi-line polylines file
sed '/>/d'  polylines.tmp >! polylines2.tmp

#--- MULTI-LINE POLYLINES ---#
# For multi line polylines - separate line numbers and rest into two files
awk 'BEGIN { FS = ":" }; {print $1}' polylines2.tmp >! polylines.num
awk 'BEGIN { FS = ":" }; {print $2}' polylines2.tmp >! polylines.info

# Extract necessary information from lines.info (first change " to fs for file separator, output comma separated)
sed 's/"/fs/g' polylines.info | awk 'BEGIN { FS = "fs" }; {print $8,$9}' >! polylines.ext

# Replace ^M character with comma (data continues on next line), replace /> with nothing (data ends on this line)
# Change spaces to commas
# Replace lines ending in ,, (continuations with backslash \)
tr -d '\015' < polylines.ext | sed 's/ /,/g' | sed 's/,,/ \\/g' >! polylines.ext2

# Paste line numbers to extracted information
paste polylines.num polylines.ext2 >! polylines.out 
#---

#--- SINGLE LINE POLYLINES ---#
# For single polylines - separate line numbers and rest into two files
awk 'BEGIN { FS = ":" }; {print $1}' spolylines.tmp >! spolylines.num
awk 'BEGIN { FS = ":" }; {print $2}' spolylines.tmp >! spolylines.info

# Extract necessary information from lines.info (first change " to fs for file separator, output comma separated)
sed 's/"/fs/g' spolylines.info | awk 'BEGIN { FS = "fs" }; {print $8,$9}' >! spolylines.ext

# Changes spaces to commas then changes lines ending with ,"/> with nothing (data ends on this line)
sed 's/ /,/g' spolylines.ext | sed 's/,"\/>//g' >! spolylines.ext2

# Change lines ending in commas to end in \ (continuation) 
tr -d '\015' < spolylines.ext2 | sed 's/,$/ \\/g' | sed 's/"\/>//g' | sed 's/\/>//g' >! spolylines.ext3

# Paste line numbers to extracted information
paste spolylines.num spolylines.ext3 >! spolylines.out 
#---

#--- LINES ---#
# For lines - separate line numbers and rest into two files
awk 'BEGIN { FS = ":" }; {print $1}' lines.tmp >! lines.num
awk 'BEGIN { FS = ":" }; {print $2}' lines.tmp >! lines.info

# Extract necessary information from lines.info (first change " to fs for file separator, output comma separated)
sed 's/"/fs/g' lines.info | awk 'BEGIN { FS = "fs" }{ OFS = "," }; {print $8,$10,$12,$14}' >! lines.ext

# Paste line numbers to extracted information
paste lines.num lines.ext >! lines.out 
#---

#--- REMAINDER ---#
# For remainder - separate line numbers and rest into two files
awk 'BEGIN { FS = ":" }; {print $1}' remainder.tmp >! remainder.num
awk 'BEGIN { FS = ":" }; {print $2}' remainder.tmp >! remainder.info

# Changes spaces to commas then changes lines ending with ,"/> with nothing (data ends on this line)
sed 's/ /,/g' remainder.info | sed 's/,"\/>//g' >! remainder.ext

# Change lines ending in commas to end in \ (continuation) 
tr -d '\015' < remainder.ext | sed 's/,$/ \\/g' | sed 's/"\/>//g' | sed 's/\/>//g' >! remainder.ext2

# Paste line numbers to extracted information
paste remainder.num remainder.ext2 >! remainder.out 
#---

#--- COMBINE LINES, POLYLINES, SPOLYLINES, REMAINDER ---#
cat lines.out polylines.out spolylines.out remainder.out >! all.out

#--- SORT USING ORIGINAL LINE NUMBERS ---#
sort -n -k1 all.out >! all_sorted.out

#--- PRINT WITHOUT ORIGINAL LINE NUMBERS ---#
awk '{print $2,$3}' all_sorted.out >! all_sorted_no_num.out

#--- APPEND LINES ---#
# if a line ends with a backslash, append the next line to it
sed -e :a -e '/\\$/N; s/\\\n//; ta' all_sorted_no_num.out >! nearly_there.out

#--- SPACES TO COMMAS ---#
sed 's/ /,/g' nearly_there.out | sed 's/,$//' >! nearly_there2.out

#--- DELETE ANY REMAINING BLANK LINES ---#
awk 'NF' nearly_there2.out >! $outfile

#--- CHANGE COMMAS TO TABS, SAVE AS .CSV & .TXT ---#
tr ',' '\t' < $outfile > $outfile2

#--- REPORT FILE CREATION ---#
echo "FracPaQ files "$outfile" and "$outfile2" have been created"

#--- CLEAN UP TEMPORARY FILES ---#
\rm lines* polylines.* polylines2.* spolylines.* remainder.* lineinfo* all.out all_sorted.out all_sorted_no_num.out nearly_*.out
