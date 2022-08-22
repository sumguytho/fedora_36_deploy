let target = desktops()[0];
Object.getOwnPropertyNames(target).forEach(prop => {
    print('property: ' + prop + ' type: ' + typeof target[prop] + '\n');
});
