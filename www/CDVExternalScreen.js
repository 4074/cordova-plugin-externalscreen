
var exec = require('cordova/exec');

exports.setupScreenConnectionNotificationHandlers = function (success, fail) {
    return exec(success, fail, "CDVExternalScreen", "setupScreenConnectionNotificationHandlers", []);
};

exports.loadHTMLResource = function (url, success, fail) {
    return exec(success, fail, "CDVExternalScreen", "loadHTMLResource", [url]);
};

exports.loadHTML = function (url, success, fail) {
    return exec(success, fail, "CDVExternalScreen", "loadHTML", [url]);
};

exports.invokeJavaScript = function (scriptString, success, fail) {
    return exec(success, fail, "CDVExternalScreen", "invokeJavaScript", [scriptString]);
};

exports.checkExternalScreenAvailable = function (success, fail) {
    return exec(success, fail, "CDVExternalScreen", "checkExternalScreenAvailable", []);
};