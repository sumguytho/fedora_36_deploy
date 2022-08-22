let widgs = ['org.kde.plasma.minimizeall', 'org.kde.plasma.showdesktop'];
panels()[0].widgets().forEach(widg=>{
    if (widgs.indexOf(widg.type) != -1) widg.remove();
});
panels()[0].addWidget(widgs[0]);
