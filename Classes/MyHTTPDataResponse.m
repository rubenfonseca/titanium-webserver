//
//  MyHTTPDataResponse.m
//  webserver
//
//  Created by Ruben Fonseca on 06/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MyHTTPDataResponse.h"
#import "TiUtils.h"

@implementation MyHTTPDataResponse
@synthesize headers;
@synthesize thisStatus;

-(void)dealloc {
	RELEASE_TO_NIL(headers);
	[super dealloc];
}

-(NSDictionary *)httpHeaders {
	return self.headers;
}

-(NSInteger)status {
	return thisStatus;
}

@end
