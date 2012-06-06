//
//  MyHTTPFileResponse.h
//  webserver
//
//  Created by Ruben Fonseca on 06/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HTTPFileResponse.h"

@interface MyHTTPFileResponse : HTTPFileResponse

@property (nonatomic, retain) NSDictionary *headers;

@end
