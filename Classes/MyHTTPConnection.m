#import "TiUtils.h"
#import "TiBlob.h"

#import "MyHTTPConnection.h"
#import "MyHTTPDataResponse.h"
#import "MyHTTPFileResponse.h"
#import "HTTPMessage.h"
#import "HTTPServer.h"

#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"

#import "MattWebserverCallbackProxy.h"

#import "DDNumber.h"
#import "HTTPLogging.h"

#import "MParser.h"
#import "MParserHeader.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_FLAG_TRACE; // | HTTP_LOG_FLAG_TRACE;

@implementation MyHTTPConnection

-(void)dealloc {
	RELEASE_TO_NIL(parser);
	RELEASE_TO_NIL(uploadedFiles);
	RELEASE_TO_NIL(multipartParams);
	RELEASE_TO_NIL(currentFile);
	
	[super dealloc];
}

- (BOOL)isBrowseable:(NSString *)path
{
	// Override me to provide custom configuration...
	// You can configure it for the entire server, or based on the current request
	return YES;
}

/**
 * This method creates a html browseable page.
 * Customize to fit your needs
 **/
- (NSString *)createBrowseableIndex:(NSString *)path
{
	NSLog(@"Path is %@", path);
	NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
	
	NSMutableString *outdata = [[NSMutableString alloc] init];
	[outdata appendString:@"<html><head>"];
	[outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
	[outdata appendString:@"</head><body>"];
	[outdata appendString:@"<bq>The following files are hosted live from the iPhone's Docs folder.</bq>"];
	[outdata appendString:@"<p>"];
	for (NSString *fname in array)
	{
		NSDictionary *fileDict = [[NSFileManager defaultManager] attributesOfItemAtPath:[path stringByAppendingPathComponent:fname] error:nil];
		//NSLog(@"fileDict: %@", fileDict);
		if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"]) fname = [fname stringByAppendingString:@"/"];
		[outdata appendFormat:@"<a href=\"%@\">%@</a>		(%8.1f Kb)<br />\n", fname, fname, [[fileDict objectForKey:NSFileSize] floatValue] / 1024];
	}
	[outdata appendString:@"</p>"];
	
	[outdata appendString:@"<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"form1\" id=\"form1\">"];
	[outdata appendString:@"<label>upload file"];
	[outdata appendString:@"<input type=\"file\" name=\"file\" id=\"file\" />"];
	[outdata appendString:@"</label>"];
	[outdata appendString:@"<label>"];
	[outdata appendString:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"Submit\" />"];
	[outdata appendString:@"</label>"];
	[outdata appendString:@"</form>"];
	
	[outdata appendString:@"</body></html>"];
	
	//NSLog(@"outData: %@", outdata);
	return [outdata autorelease];
}

- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Let's be extra cautious, and make sure the upload isn't 5 gigs
	return requestContentLength < 10000000;
}

-(BOOL)expectsMultipartRequest:(NSString *)contentType paramsIndex:(NSInteger)index {
	NSArray *params = [[contentType substringFromIndex:index + 1] componentsSeparatedByString:@";"];
	
	for(NSString *param in params) {
		index = [param rangeOfString:@"="].location;
		if((NSNotFound == index) || index >= param.length - 1) {
			continue;
		}
		
		NSString *paramName = [param substringWithRange:NSMakeRange(1, index-1)];
		NSString *paramValue = [param substringFromIndex:index + 1];
		
		if([paramName isEqualToString:@"boundary"]) {
			// let's separate the boundary from content-type, to make it more handy to handle
			[request setHeaderField:@"boundary" value:paramValue];
		}
	}
	
	if(nil == [request headerField:@"boundary"])
		return NO;
	else
		return YES;
}

-(BOOL)expectsFormDataRequest {
	return YES;
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path {
	HTTPLogTrace();
	
	isMultipart = NO;
	isFormData = NO;
	
	if([method isEqualToString:@"POST"]) {
		NSString *contentType = [request headerField:@"Content-Type"];
		if([contentType isEqualToString:@"application/x-www-form-urlencoded"]) {
			isFormData = YES;
			return [self expectsFormDataRequest];
		}
		
		NSInteger paramsSeparator = [contentType rangeOfString:@";"].location;
		if(NSNotFound == paramsSeparator) {
			return NO;
		}
		if(paramsSeparator >= contentType.length - 1) {
			return NO;
		}
		
		NSString *type = [contentType substringToIndex:paramsSeparator];
		if([type isEqualToString:@"multipart/form-data"]) {
			isMultipart = YES;
			return [self expectsMultipartRequest:contentType paramsIndex:paramsSeparator];
		}
		
		return NO;
	}
	
	return [super expectsRequestBodyFromMethod:method atPath:path];
}

-(NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
	NSMutableDictionary *event = [NSMutableDictionary dictionary];
	
	// store method
	[event setValue:method forKey:@"method"];
	
	// store path
	[event setValue:path forKey:@"path"];
	
	// store headers
	[event setValue:[request allHeaderFields] forKey:@"headers"];
	
	// get GET params
	NSDictionary *get = [self parseGetParams];
	[event setValue:get forKey:@"get"];
	
	// get POST params
	if(isMultipart) {
		// Transform all NSData into Strings
		NSMutableDictionary *post = [NSMutableDictionary dictionary];
		for(NSString *name in multipartParams) {
			NSData *data = [multipartParams valueForKey:name];
			NSString *dataString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
			[post setValue:dataString forKey:name];
		}
		[event setValue:post forKey:@"post"];
		
		// Transform all files into TiBlobs
		NSMutableDictionary *files = [NSMutableDictionary dictionary];
		for(NSString *fileName in uploadedFiles) {
			NSString *filePath = [uploadedFiles valueForKey:fileName];
			
			TiBlob *blob = [[TiBlob alloc] _initWithPageContext:[[MattWebserverCallbackProxy sharedInstance] executionContext]];
			[blob initWithFile:filePath];
			[files setValue:blob forKey:fileName];
			[blob autorelease];
		}
		[event setValue:files forKey:@"files"];
		
	} else {
		if(isFormData) {
			NSData *postData = [request body];
			if(postData) {
				NSString *postStr = [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding];
				[event setValue:[self parseParams:postStr] forKey:@"post"];
				[postStr autorelease];
			}
		} else {
			// Send the raw body :D
			NSString *mime = [[request allHeaderFields] valueForKey:@"Content-Type"];
			if(!mime) { mime = @"application/octet-stream"; }
				
			TiBlob *blob = [[TiBlob alloc] _initWithPageContext:[[MattWebserverCallbackProxy sharedInstance] executionContext]];
			[blob initWithData:[request body] mimetype:mime];
			[event setValue:blob forKey:@"body"];
			[blob autorelease];
		}
	}
	
	// Static files never hit the callback
	NSString *filePath = [self filePathForURI:path];
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self] autorelease];;
	}
	else
	{
		id res = [[MattWebserverCallbackProxy sharedInstance] requestStarted:event];
		return [self buildResponseFromObject:res];
	}
}

-(void)prepareForBodyWithSize:(UInt64)contentLength {
	HTTPLogTrace();
	
	NSString *boundary = [request headerField:@"boundary"];
	
	if(boundary) {
		parser = [[MParser alloc] initWithBoundary:boundary];
		parser.delegate = self;
	
		uploadedFiles = [[NSMutableDictionary alloc] init];
		multipartParams = [[NSMutableDictionary alloc] init];
	}
}

-(void)processBodyData:(NSData *)postDataChunk {
	HTTPLogTrace();
	
	if(parser) {
		[parser addData:postDataChunk];
	} else {
		[request appendData:postDataChunk];
	}
}

#pragma mark Multipart Form Data Parser Delegate
-(void)processStartOfPartWithHeader:(MParserHeader *)header {
	// check content disposition to find out filename
	NSDictionary *disposition = [header.params objectForKey:@"Content-Disposition"];
	NSString *fileName = [[disposition objectForKey:@"filename"] lastPathComponent];
	NSString *name = [disposition objectForKey:@"name"];
	
	if(nil == fileName || [fileName isEqualToString:@""]) {
		// Abort if we don't even have a name
		if(!name) { return; }
		
		[multipartParams setValue:[NSMutableData data] forKey:name];
	} else {
		TiFile *tempFile = [TiUtils createTempFile:fileName];
		currentFile = [[NSFileHandle fileHandleForWritingAtPath:tempFile.path] retain];
		[uploadedFiles setValue:tempFile.path forKey:name];
	}
}

-(void)processContent:(NSData *)data WithHeader:(MParserHeader *)header {
	NSDictionary *disposition = [header.params objectForKey:@"Content-Disposition"];
	NSString *name = [disposition objectForKey:@"name"];
	
	if(currentFile) {
		[currentFile writeData:data];
	} else if(name) {
		NSMutableData *d = (NSMutableData *)[multipartParams valueForKey:name];
		NSAssert(d != nil, @"Param should exist");
		
		[d appendData:data];
		[multipartParams setValue:d forKey:name];
	}
}

-(void)processEndOfPartWithHeader:(MParserHeader *)header {
	[currentFile closeFile];
	[currentFile release];
	currentFile = nil;
}

-(NSObject<HTTPResponse> *)buildResponseFromObject:(id)obj {
	if([obj isKindOfClass:[NSString class]]) {
		NSData *data = [(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding];
		return [[[HTTPDataResponse alloc] initWithData:data] autorelease];
	}
	
	if([obj isKindOfClass:[NSDictionary class]]) {
		NSDictionary *data = (NSDictionary *)obj;
		
		if([data valueForKey:@"body"]) {
			NSString *body= [data valueForKey:@"body"];
			NSData *bodyData = [body dataUsingEncoding:NSUTF8StringEncoding];
			
			MyHTTPDataResponse *res = [[[MyHTTPDataResponse alloc] initWithData:bodyData] autorelease];
			res.headers = [data valueForKey:@"headers"];
			return res;
		}
		else if ([data valueForKey:@"file"]) {
			TiBlob *blob = (TiBlob *)[data valueForKey:@"file"];
			
			MyHTTPFileResponse *res = [[[MyHTTPFileResponse alloc] initWithFilePath:blob.path forConnection:self] autorelease];
			res.headers = [data valueForKey:@"headers"];
			return res;
		} else {
			NSLog(@"Warning!! Response object must include body or file");
			return nil;
		}
	}
	
	NSLog(@"Warning!!! Response wasn't either a String nor a Object");
	return nil;
}

@end
