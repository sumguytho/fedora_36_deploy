let newOrderArr = [ 'org.kde.plasma.pager',
'org.kde.plasma.kicker',
'org.kde.plasma.icontasks',
'org.kde.plasma.marginsseparator',
'org.kde.plasma.systemtray',
'org.kde.plasma.digitalclock',
'org.kde.plasma.minimizeall' ];

let widgArr = panels()[0].widgets();
let newOrderStr = '';

for (let i = 0;; i++){
    let widg;
    for (let j = 0; j < widgArr.length; j++) if (widgArr[j].type == newOrderArr[i]) widg = widgArr[j];
    newOrderStr += widg.id;
    if (i >= newOrderArr.length - 1) break;
    newOrderStr += ';';
}

panels()[0].writeConfig('AppletOrder', newOrderStr);
