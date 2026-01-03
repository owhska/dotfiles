
# Autostart applications
## i3status or tint


lxpolkit &
dunst -config ~/.config/i3/dunst/dunstrc &
picom --config ~/.config/i3/picom/picom.conf --animations -b &
feh --bg-fill ~/.config/i3/wallpaper/wall.jpg &

# sxhkd
sxhkd -c ~/.config/i3/sxhkd/sxhkdrc &
