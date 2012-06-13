/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiUtils.h"
#import "TiProxy.h"
#import "Com0x82WebserverCallbackProxy.h"

@implementation Com0x82WebserverCallbackProxy

static Com0x82WebserverCallbackProxy* _instance;

+(Com0x82WebserverCallbackProxy *) sharedInstance
{
    return _instance;
}

-(void)dealloc
{
  RELEASE_TO_NIL(errorCallback);
	RELEASE_TO_NIL(requestCallback);
	_instance = nil;
	
	[super dealloc];
}

-(void)_initWithProperties:(NSDictionary *)properties {
	[super _initWithProperties:properties];
	
  _instance = self;
  requestCallback = [[properties objectForKey:@"requestCallback"] retain];
  errorCallback = [[properties objectForKey:@"errorCallback"] retain];
}

-(id)requestStarted:(NSDictionary*)event
{    
    if(requestCallback)
    {
			NSCondition *condition = [[NSCondition alloc] init];
			[condition lock];
			
			__block id ret = nil;
			[[requestCallback context] invokeBlockOnThread:^{
				ret = [[requestCallback call:[NSArray arrayWithObject:event] thisObject:self] copy];
				
				[condition lock];
				[condition signal];
				[condition unlock];
			}];
			
			while(ret == nil)
				[condition wait];
			[condition unlock];
			
			[condition release];
			
			return [ret autorelease];
    } else {
        return @"";
    }
}
@end
