//
//  MParserHeader.m
//  webserver
//
//  Created by Ruben Fonseca on 29/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MParserHeader.h"

@implementation MParserHeader
@synthesize params = _params, name = _name;

-(void)dealloc {
	[_params release]; _params = nil;
	[_name release]; _name = nil;
	
	[super dealloc];
}

@end
