/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiProxy.h"


@interface MattWebserverCallbackProxy : TiProxy
{

@private
	// The JavaScript callbacks (KrollCallback objects)
	KrollCallback *errorCallback;
	KrollCallback *requestCallback;
}

-(NSString*)requestStarted:(NSDictionary*) event;
-(id)initWithProxy:(id<TiEvaluator>)context args:(NSDictionary*)args;
+ (MattWebserverCallbackProxy *) sharedInstance;
@end