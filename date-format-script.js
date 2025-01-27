panels()[0].widgets().forEach(widg => {
    if (widg.type == 'org.kde.plasma.digitalclock'){
        widg.currentConfigGroup = Array('Configuration', 'Appearance');
        widg.writeConfig('customDateFormat', 'ddd, dd.MM.yyyy');
        widg.writeConfig('dateFormat', 'custom');
        widg.writeConfig('showSeconds', 2);
    }
});
// https://github.com/KDE/plasma-workspace/blob/master/applets/digital-clock/package/contents/ui/DigitalClock.qml
// for the origin of 2 in showSeconds
// I want to insert some derogatoy words here
