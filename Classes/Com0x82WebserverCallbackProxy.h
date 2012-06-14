/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiProxy.h"
#import "HTTPServer.h"

@interface Com0x82WebserverCallbackProxy : TiProxy
{

	@private
	// The JavaScript callbacks (KrollCallback objects)
	KrollCallback *errorCallback;
	KrollCallback *requestCallback;
	
	HTTPServer *_server;
}

@property (nonatomic, retain) HTTPServer *server;

+ (Com0x82WebserverCallbackProxy *) sharedInstance;

-(id)requestStarted:(NSDictionary*) event;
-(id)ipAddress:(id)args;
-(id)port:(id)args;

@end