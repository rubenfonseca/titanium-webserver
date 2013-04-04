//
//  MParser.m
//  webserver
//
//  Created by Ruben Fonseca on 29/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MParser.h"
#import "MultipartReader.h"

@implementation MParser {
	MultipartReader *parser;
}

@synthesize delegate = _delegate;

MParserHeader *currentPart;

void onPartBegin(const MultipartHeaders &headers, void *userData) {
//	NSLog(@"onPartBegin");
	
	currentPart = [[MParserHeader alloc] init];
	NSMutableDictionary *fields = [[[NSMutableDictionary alloc] init] autorelease];
	
	MultipartHeaders::const_iterator it;
	MultipartHeaders::const_iterator end = headers.end();
	for(it = headers.begin(); it != headers.end(); it++) {
		NSMutableDictionary *params = [[[NSMutableDictionary alloc] init] autorelease];
		NSString *key   = [NSString stringWithCString:it->first.c_str() encoding:NSUTF8StringEncoding];
		NSString *value = [NSString stringWithCString:it->second.c_str() encoding:NSUTF8StringEncoding];
		
		NSArray *components = [value componentsSeparatedByString:@";"];
		[components enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			NSArray *subcomponents = [(NSString *)obj componentsSeparatedByString:@"="];
			if([subcomponents count] != 2) return;
			
			NSString *fieldName = [[subcomponents objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			NSString *fieldValue = [[subcomponents objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			
			fieldName = [fieldName stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
			fieldValue = [fieldValue stringByTrimmingCharactersInSet:[NSCharacterSet punctuationCharacterSet]];
			
			[params setValue:fieldValue forKey:fieldName];
		}];
		
		[fields setValue:params forKey:key];
	}
	
	currentPart.params = [NSDictionary dictionaryWithDictionary:fields];
	
	MParser *p = (MParser *)userData;
	[p.delegate processStartOfPartWithHeader:currentPart];
}

void onPartData(const char *buffer, size_t size, void *userData) {
//	NSLog(@"onPartData");
	
	NSData *data = [NSData dataWithBytes:buffer length:size];
	
	MParser *p = (MParser *)userData;
	[p.delegate processContent:data WithHeader:currentPart];
}

void onPartEnd(void *userData) {
//	NSLog(@"onPartEnd");
	
	MParser *p = (MParser *)userData;
	[p.delegate processEndOfPartWithHeader:currentPart];
	
	[currentPart release];
	currentPart = nil;
}

-(id)initWithBoundary:(NSString*)boundary {
	if(self = [super init]) {
		parser = new MultipartReader([boundary UTF8String]);
		parser->userData = (void*)self;
		parser->onPartBegin = onPartBegin;
		parser->onPartData = onPartData;
		parser->onPartEnd = onPartEnd;
	}
	return self;
}

-(void)dealloc {
	if(parser) {
		delete parser;
	}

	[super dealloc];
}

-(size_t)addData:(NSData *)data {
	size_t ret_size = parser->feed((const char*) data.bytes, data.length);
	
	if(parser->stopped()) {
		NSLog(@"ERROR: %s", parser->getErrorMessage());
	}
	
	return ret_size;
}

@end
