let desktop = desktops()[0];
let wallpaperFile = ${WALLPQ_TARG};
desktop.wallpaperPlugin = 'org.kde.image';
desktop.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
desktop.writeConfig('Image', 'file://' + wallpaperFile);
