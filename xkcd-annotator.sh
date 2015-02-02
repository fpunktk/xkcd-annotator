#!/bin/bash

# annotate xkcd comics with title and alt-text
# copyright Felix Kästner (fpunktk), GPL
# expected fileformat: [^-]*-[0-9]+-.*\.(jpg|png)

title_font="/usr/share/fonts/truetype/freefont/FreeSansBold.ttf"
title_size="26"
alt_font="/usr/share/fonts/truetype/freefont/FreeSans.ttf"
alt_size="16"
sourcedir="./"
destdir="./xkcd-converted/"
minwidth="500"
am="1" # alt-text margin left and right

# change margin for alt-text to manually prevent overflow
case "$1" in
    [0-9]|[1-9][0-9])
        [ $1 -lt $(($minwidth / 10)) ] && am="$1"
    ;;
esac

mkdir -pv "$destdir"

for fn in xkcd*.png xkcd*.jpg
do
    [ -f "$fn" ] || continue
    echo "$fn"
    # get width and height from the original image
    read cw ch <<<$(identify -format '%w %h' "$fn")
    w="$cw"
    [ $w -lt $minwidth ] && w="$minwidth"
    # extract the number (between the -)
    nn="${fn#*-}"
    nn="${nn%%-*}"
    # download the json with the image information if it does not exist
    [ -r "$destdir${fn%\.*}.json" ] || wget -q -O "$destdir${fn%\.*}.json" "http://xkcd.com/$nn/info.0.json"
    json="$(cat "$destdir${fn%\.*}.json")"
    # extract title-text and alt-text from json (dirty hack, might break things)
    tt="${json#*\"title\": \"}"
    tt="${tt%%\", *}"
    at="${json#*\"alt\": \"}"
    at="${at%%\", *}"
    # write title-text (with number) and alt-text to a new png image
    convert -background white -border 2x0 -bordercolor white -fill black -font "$title_font" -pointsize "$title_size" -size $(($w-4))x -gravity Center caption:"xkcd $nn: $tt" tt.png
    # TODO: sometimes text gets cut off for no obvious reason, can be prevented by specifying margin $am
    convert -background '#FFF9BD' -bordercolor '#FFF9BD' -border ${am}x0 -bordercolor black -border 1x1 -fill black -font "$alt_font" -pointsize "$alt_size" -size $(($w-2-$am-$am))x -gravity Center caption:"$at" at.png
    # get height from the new images
    th="$(identify -format '%h' tt.png)"
    ah="$(identify -format '%h' at.png)"
    echo -e "$nn $w $ch $th $ah \n$tt \n$at \n"
    # combine the images
    convert -size ${w}x$(($ch+$th+$ah+5)) "xc:white" tt.png -geometry +0+0 -composite "$fn" -geometry +$((($w-$cw)/2))+$th -composite at.png -geometry +0+$(($th+$ch+5)) -composite "$destdir${fn%\.*}.png"
    # delete temporary images
    rm tt.png at.png
done

