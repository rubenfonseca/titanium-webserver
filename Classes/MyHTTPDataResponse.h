//
//  MyHTTPDataResponse.h
//  webserver
//
//  Created by Ruben Fonseca on 06/06/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HTTPDataResponse.h"

@interface MyHTTPDataResponse : HTTPDataResponse

@property (nonatomic, retain) NSDictionary *headers;

@end
