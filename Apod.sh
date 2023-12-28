#!/bin/bash


# Get the current display resolution
display_resolution=$(xrandr | grep '*' | awk '{print $1}')

# Extract width and height from the resolution
screen_width=$(echo $display_resolution | cut -d 'x' -f 1)
screen_height=$(echo $display_resolution | cut -d 'x' -f 2)

# Download the webpage HTML
curl -s https://apod.nasa.gov/apod/astropix.html > apod.html 2>/dev/null


# retrieve webpage content
content=$(cat apod.html)

# extract explanation
explanation=$(echo $content | grep -Po "(?<=Explanation: ).*(?=Tomorrow)")

# remove HTML tags
img_description=$(echo $explanation | sed 's/<[^>]*>//g')

# Extract the image src and alt
img_src=$(xmllint --html --xpath "/html/body/center[1]/p[2]/a/img/@src" apod.html 2>/dev/null | cut -d '"' -f 2)
img_Summary=$(xmllint --html --xpath "/html/body/center[1]/p[2]/a/img/@alt" apod.html 2>/dev/null | sed 's/\&#10;/\n/g' | cut -d '"' -f 2)

# Extract the text from the specified HTML element and replace &#10 with a newline character
img_title=$(xmllint --html --xpath "/html/body/center[2]/b[1]/text()" apod.html 2>/dev/null | sed 's/\&#10;/\n/g')

# Image name (title after replacing space with _)
img_nm=${img_title// /_}

# Download the image and save it as a JPEG file
wget -q https://apod.nasa.gov/apod/"$img_src" -O apod.jpg

# Resize apod.jpg to fit the screen dimensions
convert apod.jpg -resize ${screen_width}x${screen_height}^ -gravity center -extent ${screen_width}x${screen_height} resized_background.jpg

# Apply a blur effect to the resized background
convert resized_background.jpg -blur 0x2 blurred_background.jpg


read img_width img_height < <(identify -format "%w %h" apod.jpg)

# Calculate the dimensions for the gray box
text_width=$((img_width - 30))

text_height=$(convert -background none -fill white -font DejaVu-Sans-Bold -pointsize 12 \
  -gravity NorthWest -size ${text_width}x caption:"$img_title" \
  -gravity NorthWest -size ${text_width}x caption:"\n\n$img_description" \
  -append \
  -trim \
  -format "%h" info:-)
# Calculate the dimensions for the gray box based on the text height
box_height=$((text_height + 20 ))
box_width=$((text_width+20))
convert -size ${box_width}x${box_height} xc:none -fill 'rgba(128, 128, 128, 0.5)' -draw "roundrectangle 0,0,${box_width},${box_height},10,10" background.png

# Add the title and description to the gray box
convert background.png -gravity NorthWest -background none -fill white -font DejaVu-Sans-Bold -pointsize 18 \
  -gravity NorthWest -size ${text_width}x caption:"$img_title" \
  -geometry +10+10 \
  -composite \
  -fill white -font DejaVu-Sans -pointsize 12 \
  -gravity NorthWest -size ${text_width}x caption:"\n\n$img_description" \
  -geometry +10+30 \
  -composite \
  background.png

# Add the image to the gray box
convert apod.jpg  background.png -geometry +5+105 -composite  final_image.jpg

# Now use $screen_width and $screen_height in the image processing commands to create the image fitted to your screen using a blur background
# Overlay final_image.jpg onto the blurred background
convert blurred_background.jpg final_image.jpg -gravity center -composite final_image_resized.jpg


#Save the photo of the day
underline="_"
mkdir -p oldphotos
cp final_image_resized.jpg "oldphotos/$img_nm$underline.jpg"

#Changing the background
gsettings set org.gnome.desktop.background picture-uri-dark "oldphotos/$img_nm$underline.jpg"
gsettings set org.gnome.desktop.background picture-options "scaled"
gsettings set org.gnome.desktop.background primary-color "#000000"
gsettings set org.gnome.desktop.background secondary-color "#000000"

rm background.png apod.jpg apod.html resized_background.jpg blurred_background.jpg  final_image_resized.jpg final_image.jpg

echo "APOD background changer, Mohammad Badri Ahmadi, 28 Dec 2023"
echo "Inspired from apod-wallpaper.sh (v1.8) coded by A. Dominik"
