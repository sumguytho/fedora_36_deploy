panels()[0].widgets().forEach(widg => {
    if (widg.type == 'org.kde.plasma.digitalclock'){
        widg.currentConfigGroup = Array('Configuration', 'Appearance');
        widg.writeConfig('customDateFormat', 'ddd, dd.MM.yyyy');
        widg.writeConfig('dateFormat', 'custom');
        widg.writeConfig('showSeconds', 'true');
    }
});