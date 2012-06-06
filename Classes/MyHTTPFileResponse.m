//
//  MyHTTPFileResponse.m
//  webserver
//
//  Created by Ruben Fonseca on 06/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyHTTPFileResponse.h"
#import "TiUtils.h"

@implementation MyHTTPFileResponse
@synthesize headers;

-(void)dealloc {
	RELEASE_TO_NIL(headers);
	[super dealloc];
}

-(NSDictionary *)httpHeaders {
	return self.headers;
}

@end
