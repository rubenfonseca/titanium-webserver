// This is a test harness for your module
// You should do something interesting in this harness 
// to test out the module and to provide instructions 
// to users on how to use it by example.


// open a single window
var win = Ti.UI.createWindow({
	backgroundColor:'white'
});
var label = Ti.UI.createLabel();
win.add(label);
win.open();

// TODO: write your module tests here
var webserver = require('matt.webserver');

var server = webserver.startServer({
	port:12345,
	requestCallback: function(e) {
		Ti.API.info(e);
		return e.request;
	}
});

server.addEventListener('requestStarted', function(e) {
	//alert(e.request);
});
