let icons = [
'applications:windscribe.desktop',
'applications:torbrowser.desktop',
'applications:telegramdesktop.desktop',
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
