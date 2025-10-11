### Requirements for i3 minimal Debian setup:
Add `contrib non-free` to each uncommented line in `/etc/apt/sources.list`

```
sudo apt install fastfetch kitty rofi starship zsh dunst thunar xorg xinit git curl wget nala i3 lxpolkit fonts-noto-color-emoji dmz-cursor-theme lxappearance sassc gtk2-engines-murrine gnome-themes-extra i3blocks psmisc picom feh polybar maim xclip xdotool pulseaudio pavucontrol network-manager-gnome btop nvtop -y
```
```
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install wine wine32:i386 wine64 winbind winetricks -y
```
```
git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete && git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions && git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
```