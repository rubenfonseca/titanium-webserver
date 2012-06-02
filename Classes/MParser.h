//
//  MParser.h
//  webserver
//
//  Created by Ruben Fonseca on 29/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MParserHeader.h"

//-----------------------------------------------------------------
// protocol MultipartFormDataParser
//-----------------------------------------------------------------
@protocol MParserDelegate <NSObject> 
@optional
- (void)processContent:(NSData*) data WithHeader:(MParserHeader*) header;
- (void)processEndOfPartWithHeader:(MParserHeader*) header;
- (void)processStartOfPartWithHeader:(MParserHeader*) header;
@end

@interface MParser : NSObject
@property (nonatomic, assign) id<MParserDelegate> delegate;

-(id)initWithBoundary:(NSString*)boundary;
-(size_t)addData:(NSData *)data;

@end
