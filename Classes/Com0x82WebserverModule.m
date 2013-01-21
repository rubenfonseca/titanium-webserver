/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "Com0x82WebserverModule.h"
#import "TiBase.h"
#import "TiHost.h"
#import "TiUtils.h"
#import "FilesystemModule.h"
#import "HTTPServer.h"
#import "MyHTTPConnection.h"
#import "Com0x82WebserverCallbackProxy.h"

#import "DDLog.h"
#import "DDTTYLogger.h"

// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation Com0x82WebserverModule

#pragma mark Internal

// this is generated for your module, please do not change it
-(id)moduleGUID
{
	return @"fa7f492c-cd23-4832-ae51-ef9eb7ad2b7b";
}

// this is generated for your module, please do not change it
-(NSString*)moduleId
{
	return @"com.0x82.webserver";
}

#pragma mark Lifecycle

-(void)startup
{

	// this method is called when the module is first loaded
	// you *must* call the superclass
	[super startup];
	
	NSLog(@"[INFO] %@ loaded",self);
	
	wasRunning = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillComeToForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)shutdown:(id)sender
{
	// this method is called when the module is being unloaded
	// typically this is during shutdown. make sure you don't do too
	// much processing here or the app will be quit forceably
	
	// you *must* call the superclass
	[super shutdown:sender];
}

-(void)applicationWillResignActive:(id)notification {
	DDLogVerbose(@"------------> background");
	if(httpServer.isRunning) {
		__block UIBackgroundTaskIdentifier disconnectID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
			[[UIApplication sharedApplication] endBackgroundTask:disconnectID];
		}];
		
		wasRunning = YES;
		[httpServer stop];
	} else {
		wasRunning = NO;
	}
}

-(void)applicationWillComeToForeground:(id)notification {
	DDLogVerbose(@"------------> foreground");
	if(httpServer && wasRunning) {
		NSError *error;
		if(![httpServer start:&error]) {
			DDLogError(@"Error starting HTTP Server: %@", error);
		}
	}
}

#pragma mark Cleanup 

-(void)dealloc
{
    [super dealloc];
}

#pragma Public APIs

-(id)startServer:(id)args
{
  ENSURE_SINGLE_ARG(args,NSDictionary);
	
	NSUInteger port        = [TiUtils intValue:@"port" properties:args def:12345];
	BOOL bonjourEnabled    = [TiUtils boolValue:@"bonjour" properties:args def:YES];
	NSString *documentRoot = [TiUtils stringValue:@"documentRoot" properties:args def:NSTemporaryDirectory()];
	
	Com0x82WebserverCallbackProxy *proxy = [[Com0x82WebserverCallbackProxy alloc] _initWithPageContext:[self executionContext]];
	[proxy _initWithProperties:args];
    
	// Configure our logging framework.
	// To keep things simple and fast, we're just going to log to the Xcode console.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	
	// Create server using our custom MyHTTPServer class
	httpServer = [[HTTPServer alloc] init];
	proxy.server = httpServer;
	
	// Tell the server to broadcast its presence via Bonjour.
	// This allows browsers such as Safari to automatically discover our service.
	if(bonjourEnabled)
		[httpServer setType:@"_http._tcp."];
	
	// Normally there's no need to run our server on any specific port.
	// Technologies like Bonjour allow clients to dynamically discover the server's port at runtime.
	// However, for easy testing you may want force a certain port so you can just hit the refresh button.
	[httpServer setPort:port];
    
  DDLogVerbose(@"Server started on %@:%d", [proxy ipAddress:nil], httpServer.port);
    
  // We're going to extend the base HTTPConnection class with our MyHTTPConnection class.
	// This allows us to do all kinds of customizations.
	[httpServer setConnectionClass:[MyHTTPConnection class]];
	
	// Serve files from our embedded Web folder
	DDLogVerbose(@"Setting document root: %@", documentRoot);
	[httpServer setDocumentRoot:documentRoot];
	
	// Start the server (and check for problems)
	NSError *error;
	if(![httpServer start:&error]) {
		DDLogError(@"Error starting HTTP Server: %@", error);
	}
    
  return [proxy autorelease];
}

@end
