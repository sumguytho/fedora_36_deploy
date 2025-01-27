#!/bin/bash


assert_cached(){
	basenm=`basename $1`
	if [ -e $TMP_DIR/$basenm ]; then
		return
	fi
	# https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
	# exmpty extension defaults to git
	ext=$([[ "$basenm" = *.* ]] && echo ".${basenm##*.}" || echo '.git')
	if echo "$1" | grep :// >/dev/null; then
		if [ $ext = ".git" ]; then
			git clone $1 $TMP_DIR/$basenm/
			return
		fi
		wget $1 -P $TMP_DIR/
	else
		cp $1 $TMP_DIR/
	fi
	mkdir $TMP_DIR/tmp_arch
	case $ext in
		.tar)
		tar -xf $TMP_DIR/$basenm -C $TMP_DIR/tmp_arch/
		;;
		.gz)
		tar -zxf $TMP_DIR/$basenm -C $TMP_DIR/tmp_arch/
		;;
		.zip)
		unzip $TMP_DIR/$basenm -d $TMP_DIR/tmp_arch/ >/dev/null
		;;
		*)
		rmdir $TMP_DIR/tmp_arch
		return
		;;
	esac
	rm $TMP_DIR/$basenm
	mv $TMP_DIR/tmp_arch $TMP_DIR/$basenm
}

conf_backup(){
	[ ! -e $1 ] && return
	num=0
	while : ; do
		baknm="${1}_${num}.bak"
		[ ! -e $baknm ] && break
		(( ++num ))
	done
	cp $1 $baknm
}

# https://superuser.com/questions/1111219/can-i-get-all-functions-in-a-script-file-using-bash
list_funcs(){
	echo "Available functions:"
	for func in `declare -F | cut -d ' ' -f3`; do
		echo "  $func"
	done
}

repos(){
	succ_echo "installing RPM Fusion repositories..."

	fusion_free="https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
	fusion_nonfree="https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
	assert_cached $fusion_free
	assert_cached $fusion_nonfree
	fusion_free_base=$(basename $fusion_free)
	fusion_nonfree_base=$(basename $fusion_nonfree)
	sudo dnf install $TMP_DIR/$fusion_free_base $TMP_DIR/$fusion_nonfree_base -y
	succ_echo "installing third-party repositories..."
	sudo dnf install fedora-workstation-repositories -y
	succ_echo "adding double commander repository..."
	sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/home:Alexx2000/Fedora_${_FVER}/home:Alexx2000.repo
	if [ ! "x$WITHOUT_TOR" = "xy" ]; then
		succ_echo "adding tor repository..."
		cat << EOF | sudo tee /etc/yum.repos.d/Tor.repo
[tor]
name=Tor for Fedora \$releasever - \$basearch
baseurl=https://rpm.torproject.org/fedora/\$releasever/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://rpm.torproject.org/fedora/public_gpg.key
cost=100
EOF
	fi
	succ_echo "adding vs-codium repository..."
	sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
	printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee /etc/yum.repos.d/vscodium.repo
	echo ""
}

main_packages(){
	succ_echo "installing main apps..."
	DNF_PACKAGES="\
inotify-tools xmlstarlet xterm tmux lynx \
toilet cmatrix sl vim-common neovim \
firefox chromium steam gimp krita \
vlc kate fastfetch java-17-openjdk-devel \
java-11-openjdk-devel doublecmd-qt tor obfs4 \
python3-tools ddd graphviz filelight discord \
telegram-desktop python3-pip torbrowser-launcher \
qtcreator fish inxi cpu-x sqlitebrowser wireshark \
codium okteta rubygems strace keepassxc \
audacity clementine ffmpegthumbnailer \
gperftools valgrind perf hotspot iperf3 VirtualBox \
kchmviewer xdotool \
uboot-tools dtc \
tldr sshpass \
"

	sudo dnf install obs-studio -y --allowerasing
	if [ ! "x$WITHOUT_TOR" = "xy" ]; then
		DNF_PACKAGES="$DNF_PACKAGES torbrowser-launcher"
	fi
	sudo dnf install $DNF_PACKAGES -y
	npm install -g http-proxy-to-socks
	sudo dnf group install Multimedia -y
	succ_echo "installing pip..."
	python3 -m pip install --upgrade pip
	succ_echo "installing virtualenv..."
	pip3 install --user virtualenv
	succ_echo "installing tmuxinator ruby gem..."
	gem install tmuxinator
}

layouts(){
	succ_echo "adding keyboard layouts..."
	kwriteconfig5 --file kxkbrc --group Layout --key Use --type bool 1
	kwriteconfig5 --file kxkbrc --group Layout --key ResetOldOptions --type bool 1
	kwriteconfig5 --file kxkbrc --group Layout --key DisplayNames 'ENG,RUS'
	kwriteconfig5 --file kxkbrc --group Layout --key VariantList ','
	kwriteconfig5 --file kxkbrc --group Layout --key LayoutList 'us,ru'
	kwriteconfig5 --file kxkbrc --group Layout --key Options 'grp:lalt_lshift_toggle'
}

numlock(){
	succ_echo "enabling numlock on startup..."
	sudo sed -i '/\[General\]/a Numlock=on' /etc/sddm.conf
	# 0 means on, that's so awesome...
	kwriteconfig5 --file kcminputrc --group Keyboard --key NumLock '0'
}

wallpaper(){
	succ_echo "changing wallpaper..."
	mkdir -p ~/Pictures/wallpapers
	sudo cp $WALLP $WALLP_TARG
	sudo chmod 777 $WALLP_TARG
	rm -f ~/Pictures/wallpapers/$WALLP_BASE
	ln -s $WALLP_TARG ~/Pictures/wallpapers/
	qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat wallp-script.js | envsubst)"
}

kicker(){
	succ_echo "replacing kickoff widget with kicker..."
	qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(<kicker-script.js)"
	
	UNNECESSARY_ARR=(\
		applications:org.kde.dolphin.desktop \
		applications:org.kde.konsole.desktop \
		applications:org.kde.kontact.desktop \
		preferred://browser \
		)
	succ_echo "unlinking unnecessary resources from favourites:"
	for res in ${UNNECESSARY_ARR[*]}
	do
		succ_echo -e "\t $res"
		qdbus-qt6 org.kde.ActivityManager /ActivityManager/Resources/Linking UnlinkResourceFromActivity \
			"org.kde.plasma.favorites.applications" "$res" ":any"
	done
}

splash_theme(){
	succ_echo "installing splash theme..."
	assert_cached $SPLASH_THEME_GZ
	SPLASH_BASE_GZ=$(basename $SPLASH_THEME_GZ)
	SPLASH_BASE=$(ls $TMP_DIR/$SPLASH_BASE_GZ)
	if [ -e ~/.local/share/plasma/look-and-feel/$SPLASH_BASE ]; then
		succ_echo "splash theme is already installed, skipping..."
	fi

	mkdir -p ~/.local/share/plasma/look-and-feel/
	cp -r $TMP_DIR/$SPLASH_BASE_GZ/$SPLASH_BASE ~/.local/share/plasma/look-and-feel/
	kwriteconfig5 --file ksplashrc --group KSplash --key Theme "${SPLASH_BASE}"
}

# https://fedoraproject.org/wiki/GRUB_2
grub_theme(){
	succ_echo 'installing grub theme...'
	assert_cached $GRUB_THEME_REPO
	pushd $PWD
	grub_dir_name=$(basename $GRUB_THEME_REPO)
	cd $TMP_DIR/$grub_dir_name/Sleek\ theme-dark
	echo -e "\nn\n" | sudo ./install.sh
	popd
}

sddm_bg(){
	succ_echo "setting sddm background..."
	sudo cp $LOCKS $LOCKS_TARG
	sudo chmod 777 $LOCKS_TARG
	rm -f ~/Pictures/wallpapers/$LOCKS_BASE
	ln -s $LOCKS_TARG ~/Pictures/wallpapers/
	sudo sed -i "s/^background=.*/background=$LOCKSE_TARG/g" /usr/share/sddm/themes/01-breeze-fedora/theme.conf.user
}

sddm_cursor(){
	succ_echo "changing sddm cursor pack..."
	sudo kwriteconfig5 --file /etc/sddm.conf --group Theme --key CursorTheme "Breeze_Snow"
}

sddm_tweaks(){
	sddm_bg
	sddm_cursor
	# sddm time now shows seconds and there is no Clock.qml anymore
}

lock_bg(){
	succ_echo "changing lock screen background..."
	kwriteconfig5 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image "$LOCKS_TARG"
}

konsole_theme(){
	succ_echo "adding konsole theme..."
	mkdir -p ~/.local/share/konsole
	cp $KONSOLE_THEME ~/.local/share/konsole/
	cp $KONSOLE_PROFILE ~/.local/share/konsole/
	kwriteconfig5 --file konsolerc --group 'Desktop Entry' --key DefaultProfile "$(basename $KONSOLE_PROFILE)"
}

konsole_toolbars(){
	succ_echo "disabling konsole toolbars..."

	# substituting xml files no longer works, they are just renamed to .backup files,
	# just change state and hope that this blob doesn't contain something dangerously
	# outdated, the next step is to switch to some other terminal
	NO_TOOLSBARS_STATE="AAAA/wAAAAD9AAAAAQAAAAAAAAAAAAAAAPwCAAAAAvsAAAAiAFEAdQBpAGMAawBDAG8AbQBtAGEAbgBkAHMARABvAGMAawAAAAAA/////wAAAXwBAAAD+wAAABwAUwBTAEgATQBhAG4AYQBnAGUAcgBEAG8AYwBrAAAAAAD/////AAABFQEAAAMAAAOPAAACKAAAAAQAAAAEAAAACAAAAAj8AAAAAQAAAAIAAAACAAAAFgBtAGEAaQBuAFQAbwBvAGwAQgBhAHIAAAAAAP////8AAAAAAAAAAAAAABwAcwBlAHMAcwBpAG8AbgBUAG8AbwBsAGIAYQByAAAAAAD/////AAAAAAAAAAA="
	# I think I can get over whatever it looks like by default now
	# kwriteconfig5 --file konsolerc --group MainWindow --key State "$NO_TOOLSBARS_STATE"
}

konsole_tweaks(){
	konsole_theme
	konsole_toolbars
}

clock_tweak(){
	succ_echo "changing digital clock datetime format..."
	qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat date-format-script.js)"
}

locale_tweak(){
	succ_echo "changing measurements and date locale and format..."
	kwriteconfig5 --file plasma-localerc --group 'Formats' --key LC_MEASUREMENT 'C'
	kwriteconfig5 --file plasma-localerc --group 'Formats' --key LC_TIME 'C'
}

cursor_tweak(){
	succ_echo "changing cursor pack..."
	plasma-apply-cursortheme Breeze_Light
}

gtk_theme_tweak(){
	succ_echo "changing gtk theme..."
	qdbus-qt6 org.kde.GtkConfig /GtkConfig setGtkTheme 'Breeze'
}

showdesktop_tweak(){
	succ_echo "changing show desktop to minimize..."
	qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat minimize-scipt.js)"
}

panel_reorder_tweak(){
	succ_echo "changing panel applets order..."
	qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat reorder-script.js)"
}

preview_delay_tweak(){
	succ_echo "changing tooltip delay..."
	# i guess that's the closest i can get to tooltip on click
	kwriteconfig5 --file ~/.config/plasmarc --group PlasmaToolTips --key Delay 250
}

user_avatar_tweak(){
	succ_echo "changing user profile picture..."
	sudo mkdir -p /var/lib/AccountsService/icons/
	sudo cp $PROFILE_PIC /var/lib/AccountsService/icons/$USER
	sudo chmod 644 /var/lib/AccountsService/icons/$USER
}

kdewallet_tweak(){
	succ_echo "disabling kdewallet subsystem..."

	kwriteconfig5 --file kwalletrc --group Wallet --key Enabled --type bool 0
	kwriteconfig5 --file kwalletrc --group Wallet --key "Launch Manager" --type bool 0
	kwriteconfig5 --file kwalletrc --group Wallet --key "Leave Manager Open" --type bool 0
	kwriteconfig5 --file kwalletrc --group Wallet --key "Prompt on Open" --type bool 0
	kwriteconfig5 --file kwalletrc --group Wallet --key "First Use" --type bool 0
}

shell_prompt_format(){
	succ_echo "changing shell prompt format..."
	TextReset="\e[0m"
	Gray="\e[00;37m"
	BoldCyan="\e[01;36m"
	White="\e[01;37m"
	BoldBlue="\e[01;34m"
	BoldGreen="\e[01;32m"
	PS1="\n\[${BoldGreen}\]\u\[${TextReset}\]\[${Gray}\]@\[${TextReset}\]\[${BoldBlue}\]\h\[${TextReset}\]\[${Gray}\] \t \[${TextReset}\]\[${BoldCyan}\]\w\[${TextReset}\]\[${White}\] \[${TextReset}\]\n$ "
	sed -i "s/^PS1=.*//g" ~/.bashrc
	echo "PS1=\"$PS1\"" | tee -a ~/.bashrc
	sed -i "s/^unset command_not_found_handle*//g" ~/.bashrc
	echo "unset command_not_found_handle" | tee -a ~/.bashrc
}

screensaving_tweaks(){
	succ_echo "changing screensaving and screen locking behaviour..."
	kwriteconfig5 --file kscreenlockerrc --group Daemon --key Autolock --type bool 0
	# hello from plasma 6
	kwriteconfig5 --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle --type bool 0
	# shutdown on powerbtn press
	kwriteconfig5 --file powerdevilrc --group AC --group SuspendAndShutdown --key powerButtonAction "8"
	kwriteconfig5 --file powerdevilrc --group AC --group Display --key TurnOffDisplayIdleTimeoutSec "600"
	# would you look at that, it's in seconds now
	kwriteconfig5 --file powerdevilrc --group AC --group SuspendAndShutdown --key AutoSuspendIdleTimeoutSec "1800"
}

visual(){
	numlock
	layouts
	locale_tweak
	wallpaper
	clock_tweak
	kicker
	showdesktop_tweak
	panel_reorder_tweak
	gtk_theme_tweak
	sddm_tweaks
	splash_theme
	grub_theme
	screensaving_tweaks
	lock_bg
	cursor_tweak
	konsole_tweaks
	preview_delay_tweak
	user_avatar_tweak
	shell_prompt_format
}

rar_unrar(){
	succ_echo "installing rar..."
	if which rar >/dev/null 2>&1; then
		succ_echo "rar is already installed, skipping..."
		return
	fi
	assert_cached $RAR_GZ
	RAR_B=$(basename $RAR_GZ)
	subdir=`ls $TMP_DIR/$RAR_B`
	
	pushd $PWD
	cd $TMP_DIR/$RAR_B/$subdir
	sudo make install
	popd
}

# https://github.com/autokey/autokey
autokey(){
	succ_echo "Installing autokey..."
	if pip freeze | grep autokey >/dev/null; then
		succ_echo "autokey is already installed, skipping..."
		return
	fi
	pip3 install autokey
	pip3 install qscintilla pyqt5
	sudo dnf install wmctrl -y
}

ghidra(){
	succ_echo "installing ghidra..."
	assert_cached $GHIDRA_ZIP
	GHIDRA_ZIP_BASENAME=$(basename $GHIDRA_ZIP)
	GHIDRA_BASENAME=$(ls $TMP_DIR/$GHIDRA_ZIP_BASENAME)
	LEN=$(expr length $GHIDRA_ZIP_BASENAME)
	# timestamp + extension
	CULL_SZ=13
	NEWLEN=$(expr $LEN - 13)
	GHIDRA_BASENAME=$(expr substr $GHIDRA_BASENAME 1 $NEWLEN)
	if [ -e ~/Apps/$GHIDRA_BASENAME ]; then
		succ_echo "ghidra is already installed, skipping..."
		return
	fi
	cp -r $TMP_DIR/$GHIDRA_ZIP_BASENAME/$GHIDRA_BASENAME ~/Apps/
	export GHIDRA_PATH=$HOME/Apps/$GHIDRA_BASENAME
	cat $GHIDRA_TEMPL | envsubst > ~/.local/share/applications/$(basename $GHIDRA_TEMPL)
}

umlet(){
	succ_echo "installing umlet..."
	assert_cached $UMLET_ZIP
	UMLET_ZIP_BASE=$(basename $UMLET_ZIP)
	UMLET_BASE=$(ls $TMP_DIR/$UMLET_ZIP_BASE)
	if [ -e ~/Apps/$UMLET_BASE ]; then
		succ_echo "umlet is already installed, skipping..."
		return
	fi
	cp -r $TMP_DIR/$UMLET_ZIP_BASE/$UMLET_BASE ~/Apps/
	
	JAVA_DIR=/usr/lib/jvm/java-11-openjdk
	EXECP=$(echo $HOME/Apps/$UMLET_BASE/umlet.sh | sed 's|/|\\/|g')
	sed -i "s/^Exec=.*/Exec=$EXECP/g" $HOME/Apps/$UMLET_BASE/umlet.desktop
	
	IMGP=$(echo $HOME/Apps/$UMLET_BASE/img/umlet_logo.png | sed 's|/|\\/|g')
	sed -i "s/^Icon=.*/Icon=$IMGP/g" $HOME/Apps/$UMLET_BASE/umlet.desktop
	
	cp ~/Apps/$UMLET_BASE/umlet.desktop ~/.local/share/applications/
	chmod +x ~/Apps/$UMLET_BASE/umlet.sh
	sed -i "/^_UMLET_HOME=.*/i export JAVA_HOME=$JAVA_DIR" $HOME/Apps/$UMLET_BASE/umlet.sh
}

eclipse_jdt(){
	succ_echo "installing eclipse..."
	assert_cached $ECLIPSE_GZ
	ECLIPSE_GZ_BASE=$(basename $ECLIPSE_GZ)
	ECLIPSE_BASE=$(ls $TMP_DIR/$ECLIPSE_GZ_BASE)
	if [ -e ~/Apps/$ECLIPSE_BASE ]; then
		succ_echo "eclipse jdt is already installed, skipping..."
		return
	fi
	cp -r $TMP_DIR/$ECLIPSE_GZ_BASE/$ECLIPSE_BASE ~/Apps/
	
	export ECLIPSE_EXEC=$HOME/Apps/$ECLIPSE_BASE/eclipse
	export ECLIPSE_ICON=$HOME/Apps/$ECLIPSE_BASE/icon.xpm
	chmod +x $ECLIPSE_EXEC
	cat $ECLIPSE_TEMPL | envsubst > ~/.local/share/applications/$(basename $ECLIPSE_TEMPL)
}

# stuff that is more than just 'dnf install'
app_packages(){
	mkdir -p ~/Apps
	# rar_unrar
	autokey
	ghidra
	umlet
	eclipse_jdt
}

brief_launch(){
	# no idea how long it would take an app to initialize
	# using sysvinit approach
	BRIEF_SLEEP=10
	$@ &
	BRIEF_PID=$!
	sleep ${BRIEF_SLEEP}s
	kill $BRIEF_PID > /dev/null
	wait $BRIEF_PID
}

# might be unfinished
file_associations_tweak(){
	succ_echo "replacing mimeapps..."
	conf_backup ~/.config/mimeapps.list
	cp $DEFAULT_APPS ~/.config/
	succ_echo "updating system cache..."
	kbuildsycoca5
}

icontasks_tweak(){
	succ_echo "changing pinned apps in taskbar..."
	qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(<icontasks-script.js)"
}

postinstall_cleanup(){
	succ_echo "unlinking kate from favourites..."
	qdbus-qt6 org.kde.ActivityManager /ActivityManager/Resources/Linking UnlinkResourceFromActivity \
		"org.kde.plasma.favorites.applications" "org.kde.kate.desktop" ":any"
	succ_echo "unlinking kwrite from favourites..."
	qdbus-qt6 org.kde.ActivityManager /ActivityManager/Resources/Linking UnlinkResourceFromActivity \
		"org.kde.plasma.favorites.applications" "org.kde.kwrite.desktop" ":any"
	succ_echo "linking system monitor to favorites..."
	qdbus-qt6 org.kde.ActivityManager /ActivityManager/Resources/Linking LinkResourceToActivity \
		"org.kde.plasma.favorites.applications" "applications:org.kde.plasma-systemmonitor" ":any"
	succ_echo "removing gambas3 desktop file..."
	sudo rm -f /usr/share/applications/gambas3.desktop
	succ_echo "removing autokey-gtk desktop file..."
	sudo rm -f ~/.local/share/applications/autokey-gtk.desktop
}

autologin_tweak(){
	succ_echo "enabling autologin for user..."
	sudo touch /etc/sddm.conf.d/kde_settings.conf
	sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key Relogin "false"
	sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key Session "plasma"
	sudo kwriteconfig5 --file /etc/sddm.conf.d/kde_settings.conf --group Autologin --key User "$USER"
}

doublecmd_confs(){
	succ_echo 'changing doublecmd configs...'
	DCMD_CONF=$HOME/.config/doublecmd/doublecmd.xml
	while ! ls $DCMD_CONF &>/dev/null; do
		succ_echo "doublecmd didn't yet generate config file, launching it..."
		brief_launch doublecmd
	done
	conf_backup $DCMD_CONF
	xmlstarlet ed --inplace \
		-u '/doublecmd/Behaviours/ShowSystemFiles' -v 'True' \
		-u '/doublecmd/Behaviours/DateTimeFormat' -v 'dd/mm/yyyy hh:nn:ss' \
		-u '/doublecmd/Behaviours/JustRunTerminal' -v 'konsole' $DCMD_CONF
		
	SUBNODE="/doublecmd/Hotkeys/Form[@Name='Main']"
	DCMD_SCF=$HOME/.config/doublecmd/shortcuts.scf
	
	# https://stackoverflow.com/questions/11618715/xmlstarlet-to-insert-tags
	# https://stackoverflow.com/questions/5954168/how-to-insert-a-new-element-under-another-with-xmlstarlet
	conf_backup $DCMD_SCF
	xmlstarlet ed -L -s $SUBNODE -t elem -n HotkeyTMP -v "" \
		-s //HotkeyTMP -t elem -n 'Shortcut' -v 'Ctrl+Shift+1' \
		-s //HotkeyTMP -t elem -n 'Command' -v 'cm_PanelsSplitterPerPos' \
		-s //HotkeyTMP -t elem -n 'Param' -v 'splitpct=100' \
		-r //HotkeyTMP -v Hotkey $DCMD_SCF
		
	xmlstarlet ed -L -s $SUBNODE -t elem -n HotkeyTMP -v "" \
		-s //HotkeyTMP -t elem -n 'Shortcut' -v 'Ctrl+Shift+2' \
		-s //HotkeyTMP -t elem -n 'Command' -v 'cm_PanelsSplitterPerPos' \
		-s //HotkeyTMP -t elem -n 'Param' -v 'splitpct=50' \
		-r //HotkeyTMP -v Hotkey $DCMD_SCF
		
	xmlstarlet ed -L -s $SUBNODE -t elem -n HotkeyTMP -v "" \
		-s //HotkeyTMP -t elem -n 'Shortcut' -v 'Ctrl+Shift+3' \
		-s //HotkeyTMP -t elem -n 'Command' -v 'cm_PanelsSplitterPerPos' \
		-s //HotkeyTMP -t elem -n 'Param' -v 'splitpct=0' \
		-r //HotkeyTMP -v Hotkey $DCMD_SCF
}

# https://vscodium.com/#install
codium_confs(){
	succ_echo "installing vs-codium extensions..."
	codium --install-extension ms-vscode.hexeditor
	codium --install-extension llvm-vs-code-extensions.vscode-clangd
	codium --install-extension ms-python.python
	codium --install-extension yocto-project.yocto-bitbake

	succ_echo "changing vs-codium user settings..."
	CODIUM_CONF=~/.config/VSCodium/User/settings.json
	mkdir -p `dirname $CODIUM_CONF`
	conf_backup $CODIUM_CONF
	cp $CODIUM_SETTINGS $CODIUM_CONF
}

desktop_icons() {
	# doublecmd doesn't have trash link, nor is it possible
	# to add said link with little effort
	succ_echo "populating desktop with links..."
	cp -n $TRASH_DESKTOP ~/Desktop/
	rm -f ~/Desktop/{$USER,root}
	ln -s $HOME ~/Desktop/$USER
	ln -s / ~/Desktop/root
	ATTEMPTS=5
	DESKTOP_ID=$(qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "print(desktops()[0].id)")
	while [ $ATTEMPTS -gt 0 ]; do
		qdbus-qt6 org.kde.plasmashell /PlasmaShell evaluateScript "$(cat deskpos-script.js)"
		# the config isn't adjusted fast enough after creating links
		# after it ajdusts it can overwrite changes made by plasma script
		sleep 2
		
		POSITIONS=$(kreadconfig5 --file plasma-org.kde.plasma.desktop-appletsrc --group Containments --group "$DESKTOP_ID" --group General --key positions)
		POSITIONS=$(echo "'$POSITIONS'" | tr -d "\"\\\\")
		if echo "$POSITIONS" | grep -q "trash\.desktop,0,0"; then
			break
		fi
		((ATTEMPTS--))
	done
}

firefox_confs() {
	succ_echo "applying firefox profile config..."
	while [ ! -d ~/.mozilla/firefox/ ]; do
		succ_echo "firefox didn't yet generate config files, launching it..."
		brief_launch firefox
	done
	def_prof=`echo ~/.mozilla/firefox/*.default-release`
	if [ ${#def_prof[@]} -ne 1 ]; then
		succ_echo "more then one firefox profile found, skipping..."
		return
	fi
	conf_backup $def_prof/`basename $FIREFOX_SETTINGS`
	cp $FIREFOX_SETTINGS $def_prof/
}

has_tag() {
	file=$1
	tag=$2
	tag_contents=$(grep "$tag" < $file)
	if [ -z "$tag_contents" ]; then
		return 1
	fi
	return 0
}

tmux_confs() {
	succ_echo "Adding tmux autolaunch..."
	targ_file=~/.bashrc.d/bash-tmux-tweak
	if [ ! -e "$targ_file" ]; then
		mkdir -p $(dirname $targ_file)
		# https://unix.stackexchange.com/questions/43601/how-can-i-set-my-default-shell-to-start-up-tmux
		cat >> $targ_file << EOF
# bash-tmux-tweak
if command -v tmux &> /dev/null && [ -n "\$PS1" ] && [[ ! "\$TERM" =~ screen ]] && [[ ! "\$TERM" =~ tmux ]] && [ -z "\$TMUX" ]; then
  tmux
fi
EOF
		chmod +x $targ_file
	fi
	succ_echo "Adding extra tmux configuration..."
	targ_file="$HOME/.tmux.conf"
	tmux_tag="#tmux-tweak"
	if [ ! -e "$targ_file" ] || ! has_tag $targ_file $tmux_tag; then
		# ${targ_file} just doesn't do it
		cat >> ~/.tmux.conf << EOF
$tmux_tag
set -g display-panes-time 3000
EOF
	fi
}

# also handles stuff that depends on certain things being installed
main_configs(){
	file_associations_tweak
	icontasks_tweak
	postinstall_cleanup
	autologin_tweak
	kdewallet_tweak

	doublecmd_confs
	desktop_icons
	codium_confs
	firefox_confs
	tmux_confs
	
	succ_echo "adding user to wireshark group..."
	sudo usermod -aG wireshark $USER
}

pip_pkg_update(){
	succ_echo "updating pip packages..."
	# https://stackoverflow.com/questions/2720014/how-to-upgrade-all-python-packages-with-pip
	# pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U
	# https://discuss.python.org/t/pip-22-3-list-list-format-freeze-can-not-be-used-with-the-outdated-option/20061/2
	PIP_PREREQUISITES="\
meson dbus-devel glib2-devel python3-devel cairo cairo-devel gobject-introspection-devel \
cairo-gobject-devel libcurl-devel openssl-devel \
"

	sudo dnf install $PIP_PREREQUISITES -y
	ATTEMPTS=5
	while [ $ATTEMPTS -gt 0 ]; do
		pip_pkg_list=`pip list --outdated --format=json | jq -r '.[] | "\(.name)==\(.latest_version)"'`
		if [ -z "$pip_pkg_list" ];then
			return
		fi
		for pippkg in ${pip_pkg_list[*]}; do
			pip3 install -U --user $pippkg
		done
		(( ATTEMPTS-- ))
	done
	succ_echo "some pip packages couldn't be updated..."
}

extra_pip_pkgs() {
	PIP_PKGS="\
yt-dlp spotdl \
"
	succ_echo "installing extra pip packages..."
	pip3 install ${PIP_PKGS}
}

succ_echo(){
	BoldBlackFont='\033[1;30m'
	IntenseGreenBackground='\033[0;102m'
	TextReset='\033[0m'
	echo -en "${IntenseGreenBackground}"
	echo -en "${BoldBlackFont}"
	echo -n $@
	echo -e "${TextReset}"
}

clean_sudo_persist(){
	succ_echo "cleaning up sudo persist process..."
	kill $SUDO_PERSIST_PID
}

clean_sudo_persist_err(){
	succ_echo "an error occurred..."
	clean_sudo_persist
}

############################################################
############################################################

source ./commons.env
#wallpaper
export WALLP_BASE=$(basename $WALLP)
export WALLP_TARG="/usr/share/backgrounds/$WALLP_BASE"
# quoted
export WALLPQ_TARG="'$HOME/Pictures/wallpapers/$WALLP_BASE'"
# escaped
export WALLPE_TARG=$(echo $WALLP_TARG | sed 's|/|\\/|g')
# lock screen
export LOCKS_BASE=$(basename $LOCKS)
export LOCKS_TARG="/usr/share/backgrounds/$LOCKS_BASE"
export LOCKSE_TARG=$(echo $LOCKS_TARG | sed 's|/|\\/|g')


source ./packages.env

export _FVER=40
echo "This script is meant for Fedora Workstation ${_FVER} KDE spin, using it on any other distro isn't guaranteed to work."
echo "This script assumes a fresh install and will override certain configs."

if [ $# -le 0 ]; then
	echo "Available options: --all, --all-packages, --visual, --repos, --packages"
	echo ""
	echo "--rm-cache (should be the first argument)"
	echo ""
	echo "--packages-main, --packages-app"
else
	# https://unix.stackexchange.com/questions/625645/how-to-make-sudo-not-expire-while-script-is-running
	sudo -v
	succ_echo "creating sudo persist process..."
	while sleep 60; do sudo -v; done &
	export SUDO_PERSIST_PID=$!
	
	# https://stackoverflow.com/questions/64786/error-handling-in-bash
	trap clean_sudo_persist_err ERR
	
	set -eE -o pipefail
	EXEC_FL=0
	
	if ! command -v git >/dev/null 2>&1; then
		succ_echo "git isn't installed, installing it..."
		sudo dnf install git -y
	fi
	if [ -z $COMMON_GIT_DIR ]; then
		GIT_BASE=$(basename $COMMON_GIT)
		GIT_BASE=${GIT_BASE%.*}
		export COMMON_GIT_DIR=$GIT_BASE
		succ_echo "no git clone dir provided, assuming '${GIT_BASE}'..."
	fi
	if [ ! -d $COMMON_GIT_DIR ]; then
		succ_echo "directory '$COMMON_GIT_DIR' doesn't exist, cloning it..."
		git clone $COMMON_GIT $COMMON_GIT_DIR
	fi

	mkdir -p $TMP_DIR
	
	for i in "$@"; do
	  case $i in
	  	--base)
		  sudo dnf update -y
		  repos
		  main_packages
		;;
		--all)
		  sudo dnf update -y
		  repos
		  main_packages
		  app_packages
		  pip_pkg_update
		  extra_pip_pkgs
		  main_configs
		  visual
		  succ_echo "a reboot is required for some changes to take effect..."
		  ;;
		--all-packages)
		  sudo dnf update -y
		  repos
		  main_packages
		  app_packages
		  pip_pkg_update
		  extra_pip_pkgs
		  ;;
		--rm-cache)
		  rm -rf $TMP_DIR
		  mkdir -p $TMP_DIR
		  ;;
		--visual)
		  visual
		  ;;
		--repos)
		  repos
		  ;;
		--packages)
		  main_packages
		  app_packages
		  ;;
		--packages-main)
		  main_packages
		  ;;
		--packages-app)
		  app_packages
		  ;;
		--func)
		  EXEC_FL=1
		  ;;
		*)
		  if [ $EXEC_FL -eq 1 ]; then
			EXEC_FL=0
			$i
		  else
			echo "Unknown option $i"
		  fi
		  ;;
	  esac
	done

	if [ $EXEC_FL -eq 1 ]; then
		list_funcs
	fi

	clean_sudo_persist
fi
