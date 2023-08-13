let icons = [
'applications:torbrowser.desktop',
'applications:org.telegram.desktop.desktop',
'preferred://filemanager',
'preferred://browser',
'applications:discord.desktop',
'applications:steam.desktop'
];
panels()[0].widgets().forEach(widg => {
    if(widg.type == 'org.kde.plasma.icontasks'){
        widg.currentConfigGroup = Array('General');
        widg.writeConfig('launchers', icons.join(','));
    }
});
