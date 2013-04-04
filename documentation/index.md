# webserver Module

## Description

Create a fully dynamic HTTP server inside your Titanium application.

## Installation

[http://docs.appcelerator.com/titanium/2.0/index.html#!/guide/Using_a_Module]()

### iOS >= 4 module only

This is an iOS > = 4 module only! If you try to require it on an iOS < = 3 device,
it will throw an exception. So you should include some sort of code on
your application to check in which version of iOS are you running, and then
decide to use or not use this module

    function isiOS4Plus()
    {
      // add iphone specific tests
      if (Titanium.Platform.name == 'iPhone OS')
      {
        var version = Titanium.Platform.version.split(".");
        var major = parseInt(version[0],10);
    
        if (major >= 4)
        {
          return true;
        }
      }
      return false;
    }  

## Changelog

See [here](changelog.html)

## Accessing the webserver Module

To access this module from JavaScript, you would do the following:

	var webserver = require("com.0x82.webserver");

The webserver variable is a reference to the Module object.	

## Reference

### webserver.startServer({...})

Use this method to setup and start the server. The only argument is an object that
you should use to configure all aspects of the webserver instance:

- *port*: [required] An integer with the port number you want to run the server. Please use
          only unprivileged ports (> 1024). Default is 12345.

- *documentRoot*: [required] The document root of the web server (where static files will be served from).
                  The default is the Application documents directory.

- *bonjour*: [optional] default to `true`. Enables Bonjour advertising for the webserver.

- *requestCallback*: [required] A callback that is called for every single HTTP request to the webserver.
                     The details about this callback are explained on the next section

After this call, the server is running and should be ready to receive requests on the device.

Example:

    var webserver = require('com.0x82.webserver');
    var server = webserver.startServer({
      port: 12345,
      documentRoot: Ti.Filesystem.tempDirectory,
      requestCallback: function(e) {
        return "Hello World!";
      }
    });

This would start the webserver on port 12345 and reply to all requests with the 
string `Hello World`.

### requestCallback

### event params

Under the `event` object passed as paramter, there are a lot of keys depending on
the request. Here's the summary:

- *method*: The HTTP method used for this request: ("GET", "POST", "PUT", "DELETE")

- *path*: The relative path for the request

Example:

    # curl -v http://localhost:12345/foo/bar
    requestCallback: function(e) {
      alert(e.path); // should print "/foo/bar"
    }

- *headers*: An object with all the headers for the request

- *get*: A (possible empty) object with all the GET params sent on this request.

Example:

    # curl -v http://localhost:12345/?foo=bar
    
    requestCallback: function(e) {
      alert(e.get.foo); // should print "bar"
    }

- *post*: A (possible empty) object with all the POST params sent on this request.
          This includes all paramters encoded as `application/x-www-form-urlencoded`.
          This never includes `GET` params, neither files sent in the `multipart` format.

Example:

    # curl -d "post_name=post_value" http://localhost:12345/?foo=bar

    requestCallback: function(e) {
      alert(e.post.post_name); // should print "post_value"
      alert(e.post.foo); // should print null
    }

- *files*: A (possible empty) object with all the files sent as `multipart/form-data`. The keys
          correspond to the file name, and the values are `TiBlob`s you can read, copy, write, etc.

Example:

    # curl -d"file_name=@/bin/sh" http://localhost:12345/?foo=bar

    requestCallback: function(e) {
      alert(e.files.file_name); // should print the file contents
    }

- *body*: An optional `TiBlob` that only appears when the webserver receives a raw request with no known
          `Content-Type`. Since it can't handle with both `multipart` neither with `form-urlencoded`, the
          full raw body is returned here in a `TiBlob` that you can process, save to a file, or do any
          other thing.

### Response values

Currently there are two types of responses supported by the module:

#### Basic string response

You just return a string from the callback, and it sent directly to the client.

Example:

    requestCallback: function(e) {
      return "Hello world";
    }

#### Advanced object response

You could however return a response that allows for more advanced stuff. The object
should contain the following keys:

- *headers*: [optional] An object with the headers you want to send with the response

Example:

    requestCallback: function(e) {
      return {
        headers: { 'Content-Type': 'application/json' }
      }
    }

- *body*: [required or file] A string with the body to be returned to client

Example:

    requestCallback: function(e) {
      return {
        headers: { 'Content-Type': 'application/json' },
        body: "{foo:'bar'}"
      }
    }

- *status*: [optional] A valid HTTP response code. Ignored if you return a *file* response.

Example:

    requestCallback: function(e) {
      return {
        headers: { 'Content-Type': 'application/json' },
        status: 401
        body: "{message:'You are not authorized'}",
      }
    }

- *file*: [required or body] A TiBlob representing an existing file to be sent to the client.
          Under the hood it uses a very efficient mechanism to load the file to the client
          without exausting all the resources.

Example:

    requestCallback: function(e) {
      return {
        headers: { 'Content-Type': 'image/png' },
        file: Ti.Filesystem.getFile(Ti.Filesystem.resourcesDirectory, "KS_nav_ui.png")
      }
    }
    
## Properties

### webserver.disconnectsInBackground = true | false (default is true)

If you change this flag to `false`, the webserver will not disconnect when the app goes into background.
It could be usefull for people that use this module to provide background Audio or GPS.

## Events

### requestStarted

The server sends this event everytime a request is started. The object passed as
argument is the same object passed to the `requestCallback` bellow.

## Usage

Please see the example director, since it contains several examples of all the API.

## Author

Matt Apperson

Ruben Fonseca

(c) 2012
