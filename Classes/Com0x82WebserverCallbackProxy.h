/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiProxy.h"


@interface Com0x82WebserverCallbackProxy : TiProxy
{

@private
	// The JavaScript callbacks (KrollCallback objects)
	KrollCallback *errorCallback;
	KrollCallback *requestCallback;
}

-(id)requestStarted:(NSDictionary*) event;
+ (Com0x82WebserverCallbackProxy *) sharedInstance;

@end