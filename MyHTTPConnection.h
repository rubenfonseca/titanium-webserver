#import <Foundation/Foundation.h>
#import "HTTPConnection.h"


@interface MyHTTPConnection : HTTPConnection
{
	int dataStartIndex;
	NSMutableArray* multipartData;
    NSMutableData* postedBody;

	BOOL postHeaderOK;
}

- (BOOL)isBrowseable:(NSString *)path;
- (NSString *)createBrowseableIndex:(NSString *)path;

- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength;
- (void)saveFile;

@end