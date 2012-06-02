#import <Foundation/Foundation.h>
#import "HTTPConnection.h"
#import "MParser.h"

@interface MyHTTPConnection : HTTPConnection <MParserDelegate>
{
	MParser *parser;
	
	NSMutableDictionary *uploadedFiles;
	NSMutableDictionary *multipartParams;
	NSFileHandle *currentFile;
	BOOL isMultipart;
	BOOL isFormData;
}

- (BOOL)isBrowseable:(NSString *)path;
- (NSString *)createBrowseableIndex:(NSString *)path;

@end