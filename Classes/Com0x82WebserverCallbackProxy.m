/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import "TiUtils.h"
#import "TiProxy.h"
#import "Com0x82WebserverCallbackProxy.h"

#include <ifaddrs.h>
#include <arpa/inet.h>

@interface Com0x82WebserverCallbackProxy ()
- (NSString *)getIPAddress;
@end

@implementation Com0x82WebserverCallbackProxy
@synthesize server=_server;

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

-(id)ipAddress:(id)args {
	return [self getIPAddress];
}

-(id)port:(id)args {
	return NUMINT(_server.port);
}

- (NSString *)getIPAddress
{
	NSString *address = @"error";
	struct ifaddrs *interfaces = NULL;
	struct ifaddrs *temp_addr = NULL;
	int success = 0;
	
	// retrieve the current interfaces - returns 0 on success
	success = getifaddrs(&interfaces);
	if (success == 0)
	{
		// Loop through linked list of interfaces
		temp_addr = interfaces;
		while(temp_addr != NULL)
		{
			if(temp_addr->ifa_addr->sa_family == AF_INET)
			{
				// Check if interface is en0 which is the wifi connection on the iPhone
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
				{
					// Get NSString from C String
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
				}
			}
			
			temp_addr = temp_addr->ifa_next;
		}
	}
	
	// Free memory
	freeifaddrs(interfaces);
	
	return address;
}

@end
