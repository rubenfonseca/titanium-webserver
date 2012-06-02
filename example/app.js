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

var webserver = require('matt.webserver');

var server = webserver.startServer({
	port:12345,
	filePath: Ti.Filesystem.tempDirectory,
	requestCallback: function(e) {
    Ti.API.log("###################### NEW REQ ############");
    Ti.API.log(e);
    Ti.API.log("###########################################");

		var passed_test_count = 0;

		if(e.post !== undefined) {
			Ti.API.info('POST data tests -----------------------------------------');
			if(typeof e.post === "object") {
				Ti.API.info('Test 1 - POST data exists, and has been returned to JS as the correct data type');
				passed_test_count++;

				if(e.post.test !== undefined) {
					Ti.API.info('Test 2 - The data sent via a form post has been correctly returned to JS land.');
					passed_test_count++;
				} else {
					Ti.API.info("Test 2 - FAILED");
				}

				if(e.post.get_test === undefined) {
					Ti.API.info('Test 3 - GET data is not in the POST data.');
					passed_test_count++;
				} else {
					Ti.API.info("Test 3 - FAILED");
				}
			} else {
				Ti.API.info("Test 1 - FAILED");
			}
		} else {
			Ti.API.info("WARNING - This test is inadaquit, submit the form with at least 2 POST variables");
		}

		if(e.get !== undefined) {
			Ti.API.info('GET data tests ------------------------------------------');
			if(typeof e.get === "object") {
				Ti.API.info('Test 4 - GET data exists, and has been returned to JS as the correct data type');
				passed_test_count++;
				if(e.get.get_test !== undefined) {
					Ti.API.info('Test 5 - The data sent via a GET variable has been correctly returned to JS land.');
					passed_test_count++;
				} else {
					Ti.API.info('Test 5 - FAILED');
				}

				if(e.post == undefined || e.get.test === undefined) {
					Ti.API.info('Test 6 - POST data is not in the GET data.');
					passed_test_count++;
				} else {
					Ti.API.info('Test 6 - FAILED');
				}

			} else {
				Ti.API.info("Test 4 - FAILED");
			}
		} else {
			Ti.API.info("WARNING - This test is inadaquit, submit the form to a URL with at least 2 GET variable in it");
		}

		if(e.files !== undefined) {
			Ti.API.info('FILE data tests -----------------------------------------');

			if(typeof e.files === "object") {
				Ti.API.info('Test 7 - Files posted via MULTI-PART FORM DATA are returned to JS land correctly');
				passed_test_count++;

				// if(e.files.length < 2) {
				// 	Ti.API.info("WARNING - This test is inadaquit, please post at least 2 files");
				// }

        for(var name in e.files) if(e.files.hasOwnProperty(name)) {
          var file = e.files[name];

          if(file != null && file.size != null && file.path != null) {
						Ti.API.info('Test 8 - File path returned to JS land correctly');
            passed_test_count++;
          } else {
            Ti.API.info('Test 8 - FAILED');
          }
        }

			} else {
				Ti.API.info("Test 7 - FAILED");
			}
		}

		if(passed_test_count === 8) {
			Ti.API.info("YAY! All tests pass!");
		} else {
			Ti.API.info("Sorry, not all tests passed...");
		}

		var string = "This is the text / HTML that should display in the users browser";
		return string;
	}
});

server.addEventListener('requestStarted', function(e) {
	//alert(e.request);
});
