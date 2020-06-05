//force no cache
if ((navigator.appVersion.substring(0,1) == "5" && navigator.userAgent.indexOf('Gecko') != -1) || navigator.userAgent.search(/Opera/) != -1) {
    document.write('<meta http-equiv="pragma" content="no-cache" />');
}
