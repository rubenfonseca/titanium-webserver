/**
 * Your Copyright Here
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#import <UIKit/UIKit.h>
#import "TiModule.h"

@class iPhoneHTTPServerViewController;
@class HTTPServer;

@interface MattWebserverModule : TiModule 
{
	HTTPServer *httpServer;
}
@end