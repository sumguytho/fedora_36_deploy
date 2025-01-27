const menus = Array('org.kde.plasma.kicker', 'org.kde.plasma.kickoff', 'org.kde.plasma.kickerdash');
panels()[0].widgets().forEach(widg => {
    if (menus.indexOf(widg.type) != -1) widg.remove();
});
const newWidg = panels()[0].addWidget(menus[0]);
newWidg.writeConfig('icon', 'start-here-kde');
newWidg.currentConfigGroup = Array('Shortcuts');
newWidg.writeConfig('global', 'Meta+F1');
