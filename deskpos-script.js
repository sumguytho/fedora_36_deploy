let desktop = desktops()[0];
desktop.currentConfigGroup = Array('General');
desktop.writeConfig('positions', '1,17,desktop:/root,0,1,desktop:/user,0,2,desktop:/trash.desktop,0,0');
desktop.writeConfig('sortMode', '-1');
desktop.reloadConfig();
