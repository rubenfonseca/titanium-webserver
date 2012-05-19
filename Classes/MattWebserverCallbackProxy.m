/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiUtils.h"
#import "TiProxy.h"
#import "MattWebserverCallbackProxy.h"

@implementation MattWebserverCallbackProxy
static id _instance;

+(MattWebserverCallbackProxy *) sharedInstance
{
    return _instance;
}

-(void)_destroy
{
    RELEASE_TO_NIL(errorCallback);
	RELEASE_TO_NIL(requestCallback);
	[super _destroy];
}

-(void)dealloc
{
    [super dealloc];
}

-(id)initWithProxy:(id<TiEvaluator>)context args:(NSDictionary*)args
{
    _instance = self;
    requestCallback = [[args objectForKey:@"requestCallback"] retain];
    errorCallback = [[args objectForKey:@"errorCallback"] retain];

	return _instance;
}

-(NSString*)requestStarted:(NSDictionary*)event
{    
    if ([super _hasListeners:@"requestStarted"])
    {
        [super fireEvent:@"requestStarted" withObject:event];
    }
    
    if(requestCallback)
    {
        return [requestCallback call:[NSArray arrayWithObject:event] thisObject:nil];
        
    } else {
        return @"";
    }
}
@end
