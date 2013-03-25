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
  
  // Only remove the shared instance if we are the shared instance :)
	if(self == _instance)
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

-(NSString *)getIPAddress {
	NSArray* interfaces = [NSArray arrayWithObjects:@"en0", @"en1", nil];
	for (NSString* interface in interfaces) {
		NSString* iface = [self getIface:interface];
		if (iface) {
			return iface;
		}
	}
	return nil;
}

-(NSString *)getIface:(NSString *)iname {
	struct ifaddrs* head = NULL;
	struct ifaddrs* ifaddr = NULL;
	getifaddrs(&head);
	
	NSString* str = nil;
	for (ifaddr = head; ifaddr != NULL; ifaddr = ifaddr->ifa_next) {
		if (ifaddr->ifa_addr->sa_family == AF_INET &&
				!strcmp(ifaddr->ifa_name, [iname UTF8String])) {
			
			char ipaddr[20];
			struct sockaddr_in* addr;
			addr = (struct sockaddr_in*)ifaddr->ifa_addr;
			inet_ntop(addr->sin_family, &(addr->sin_addr), ipaddr, 20);
			str = [NSString stringWithUTF8String:ipaddr];
			break;
		}
	}
	
	freeifaddrs(head);
	return str;
}

@end
