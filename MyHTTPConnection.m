#import "MyHTTPConnection.h"
#import "HTTPMessage.h"
#import "HTTPServer.h"

#import "HTTPConnection.h"
#import "HTTPDataResponse.h"
#import "HTTPFileResponse.h"

#import "MattWebserverCallbackProxy.h"

#import "DDNumber.h"
#import "HTTPLogging.h"

// Log levels : off, error, warn, info, verbose
// Other flags: trace
static const int httpLogLevel = HTTP_LOG_LEVEL_WARN; // | HTTP_LOG_FLAG_TRACE;


/**
 * All we have to do is override appropriate methods in HTTPConnection.
**/

@implementation MyHTTPConnection

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
    NSArray *array = [[NSFileManager defaultManager] directoryContentsAtPath:path];
    
    NSMutableString *outdata = [NSMutableString new];
	[outdata appendString:@"<html><head>"];
    [outdata appendString:@"<style>html {background-color:#eeeeee} body { background-color:#FFFFFF; font-family:Tahoma,Arial,Helvetica,sans-serif; font-size:18x; margin-left:15%; margin-right:15%; border:3px groove #006600; padding:15px; } </style>"];
    [outdata appendString:@"</head><body>"];
    [outdata appendString:@"<bq>The following files are hosted live from the iPhone's Docs folder.</bq>"];
    [outdata appendString:@"<p>"];
    for (NSString *fname in array)
    {
        NSDictionary *fileDict = [[NSFileManager defaultManager] fileAttributesAtPath:[path stringByAppendingPathComponent:fname] traverseLink:NO];
		//NSLog(@"fileDict: %@", fileDict);
		if ([[fileDict objectForKey:NSFileType] isEqualToString: @"NSFileTypeDirectory"]) fname = [fname stringByAppendingString:@"/"];
		[outdata appendFormat:@"<a href=\"%@\">%@</a>		(%8.1f Kb)<br />\n", fname, fname, [[fileDict objectForKey:NSFileSize] floatValue] / 1024];
    }
    [outdata appendString:@"</p>"];
	
	if ([self supportsPOST:path withSize:0])
	{
		[outdata appendString:@"<form action=\"\" method=\"post\" enctype=\"multipart/form-data\" name=\"form1\" id=\"form1\">"];
		[outdata appendString:@"<label>upload file"];
		[outdata appendString:@"<input type=\"file\" name=\"file\" id=\"file\" />"];
		[outdata appendString:@"</label>"];
		[outdata appendString:@"<label>"];
		[outdata appendString:@"<input type=\"submit\" name=\"button\" id=\"button\" value=\"Submit\" />"];
		[outdata appendString:@"</label>"];
		[outdata appendString:@"</form>"];
	}
	
	[outdata appendString:@"</body></html>"];
    
	//NSLog(@"outData: %@", outdata);
    return [outdata autorelease];
}



- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
	HTTPLogTrace();
	
	// Add support for POST
	
	if ([method isEqualToString:@"POST"])
	{
        // Let's be extra cautious, and make sure the upload isn't 5 gigs
			
        return requestContentLength < 500000;
	}
	
	return [super supportsMethod:method atPath:path];
}

/**
 * Returns whether or not the server will accept POSTs.
 * That is, whether the server will accept uploaded data for the given URI.
 **/
- (BOOL)supportsPOST:(NSString *)path withSize:(UInt64)contentLength
{
    //	NSLog(@"POST:%@", path);
	
	dataStartIndex = 0;
	multipartData = [[NSMutableArray alloc] init];
	postHeaderOK = FALSE;
	
	return YES;
}


/**
 * This method is called to get a response for a request.
 * You may return any object that adopts the HTTPResponse protocol.
 * The HTTPServer comes with two such classes: HTTPFileResponse and HTTPDataResponse.
 * HTTPFileResponse is a wrapper for an NSFileHandle object, and is the preferred way to send a file response.
 * HTTPDataResopnse is a wrapper for an NSData object, and may be used to send a custom response.
 **/
- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{    
	//NSLog(@"httpResponseForURI: method:%@ path:%@", method, path);
	
	NSData *requestData = [request body];
    NSString* filename = @"";
	
	NSString *requestStr = [[[NSString alloc] initWithData:requestData encoding:NSASCIIStringEncoding] autorelease];
	//NSLog(@"\n=== Request ====================\n%@\n================================", requestStr);
	//printf (" \n\n requestContentLength = %llu  \n", requestContentLength);
	if (requestContentLength > 0 && [multipartData count] >= 2)  // Process POST data
	{
        //NSLog(@"We got something to process!!!");
		//NSLog(@"processing post data: %@", requestContentLength);
        
        //NSLog(@"We have this many = %@", [multipartData count]);
		
		if ([multipartData count] < 2) return nil;
		
		NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes]
													  length:[[multipartData objectAtIndex:1] length]
													encoding:NSUTF8StringEncoding];
        		
		NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
		postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
		postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
		filename = [postInfoComponents lastObject];
        
        //NSLog(@"filename = %@", filename);
		
		if (![filename isEqualToString:@""]) //this makes sure we did not submitted upload form without selecting file
		{
			UInt16 separatorBytes = 0x0A0D;
			NSMutableData* separatorData = [NSMutableData dataWithBytes:&separatorBytes length:2];
			[separatorData appendData:[multipartData objectAtIndex:0]];
			int l = [separatorData length];
			int count = 2;	//number of times the separator shows up at the end of file data
			
			NSFileHandle* dataToTrim = [multipartData lastObject];
			//NSLog(@"data: %@", dataToTrim);
			
			//NSLog(@"NewFileUploaded");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NewFileUploaded" object:nil];
		}
		
		for (int n = 1; n < [multipartData count] - 1; n++)
			NSLog(@"%@", [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:n] bytes] length:[[multipartData objectAtIndex:n] length] encoding:NSUTF8StringEncoding]);
		
		[postInfo release];
		[multipartData release];
		requestContentLength = 0;
		
	}
	
	NSString *filePath = [self filePathForURI:path];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
	{
		return [[[HTTPFileResponse alloc] initWithFilePath:filePath forConnection:self] autorelease];;
	}
	else
	{
        NSArray *cleanPath = [path componentsSeparatedByString:@"?"];
        NSData *browseData;
        NSDictionary* POST = [NSDictionary dictionaryWithObjectsAndKeys:nil];
        NSDictionary* file = [NSDictionary dictionaryWithObjectsAndKeys:nil];
                
        if ([method isEqualToString:@"POST"])
        {
            NSLog(@"now we postin");
        }
        
        if (![filename isEqualToString:@""])
        {
            file = [NSDictionary dictionaryWithObjectsAndKeys:filename,@"filename",nil];
        }
                
        NSDictionary* GET = [cleanPath count] > 1 ?[self parseParams:[cleanPath objectAtIndex: 1]] : [NSDictionary dictionaryWithObjectsAndKeys:nil];
        
        @synchronized(self) {
            NSDictionary *event = [NSDictionary dictionaryWithObjectsAndKeys:[cleanPath objectAtIndex: 0],@"request",method,@"method",GET,@"get",POST,@"post",file,@"file",nil];
            //NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:@"value1", @"key1", @"value2", @"key2", nil];

            NSString* responce = [[MattWebserverCallbackProxy sharedInstance] requestStarted: event];
            
            browseData = [responce dataUsingEncoding:NSUTF8StringEncoding];
        }
        return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
        
//        if ([path isEqualToString:@"/list"])
//		{
//            NSString *folder = [config documentRoot];
//            if ([self isBrowseable:folder])
//            {
//                browseData = [[self createBrowseableIndex:folder] dataUsingEncoding:NSUTF8StringEncoding];
//                return [[[HTTPDataResponse alloc] initWithData:browseData] autorelease];
//            }
//        } else if ([path isEqualToString:@"/upload"])
//        {
//            
//            
//        }
	}
	
	return nil;
}


/**
 * This method is called to handle data read from a POST.
 * The given data is part of the POST body.
 **/
- (void)processBodyData:(NSData *)postDataChunk
{
	// Override me to do something useful with a POST.
	// If the post is small, such as a simple form, you may want to simply append the data to the request.
	// If the post is big, such as a file upload, you may want to store the file to disk.
	// 
	// Remember: In order to support LARGE POST uploads, the data is read in chunks.
	// This prevents a 50 MB upload from being stored in RAM.
	// The size of the chunks are limited by the POST_CHUNKSIZE definition.
	// Therefore, this method may be called multiple times for the same POST request.
		
	if (!postHeaderOK)
	{
		UInt16 separatorBytes = 0x0A0D;
		NSData* separatorData = [NSData dataWithBytes:&separatorBytes length:2];
		
		int l = [separatorData length];
        
		for (int i = 0; i < [postDataChunk length] - l; i++)
		{
			NSRange searchRange = {i, l};
            
			if ([[postDataChunk subdataWithRange:searchRange] isEqualToData:separatorData])
			{
				NSRange newDataRange = {dataStartIndex, i - dataStartIndex};
				dataStartIndex = i + l;
				i += l - 1;
				NSData *newData = [postDataChunk subdataWithRange:newDataRange];
                
				if ([newData length])
				{
                    NSLog(@"uploding data...");
					[multipartData addObject:newData];
				}
				else
				{
					postHeaderOK = TRUE;
                    
                    NSString* postInfo = [[NSString alloc] initWithBytes:[[multipartData objectAtIndex:1] bytes] length:[[multipartData objectAtIndex:1] length] encoding:NSUTF8StringEncoding];
                    
					NSArray* postInfoComponents = [postInfo componentsSeparatedByString:@"; filename="];
                    //NSLog(@"lastObject = %@", [postInfoComponents lastObject]);
                    //NSLog(@"lastObject = %@", [postInfoComponents objectAtIndex:1]);
					postInfoComponents = [[postInfoComponents lastObject] componentsSeparatedByString:@"\""];
					postInfoComponents = [[postInfoComponents objectAtIndex:1] componentsSeparatedByString:@"\\"];
                    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask ,YES );
                    NSString *filePath = [paths objectAtIndex:0];
                    
					NSString* filename = [filePath stringByAppendingPathComponent:[postInfoComponents lastObject]];
					NSRange fileDataRange = {dataStartIndex, [postDataChunk length] - dataStartIndex};
					
					[[NSFileManager defaultManager] createFileAtPath:filename contents:[postDataChunk subdataWithRange:fileDataRange] attributes:nil];
					NSFileHandle *file = [[NSFileHandle fileHandleForUpdatingAtPath:filename] retain];
                    
					if (file)
					{
						[file seekToEndOfFile];
						[multipartData addObject:file];
					}
					
					[postInfo release];
					
					//[self saveFile];
                    break;
				}
			}
		}
	}
	else
	{
        
        //NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask ,YES );
        //NSString *docPath = [paths objectAtIndex:0];
        //[postDataChunk writeToFile:@"file.pdf" atomically:NO];
		[(NSFileHandle*)[multipartData lastObject] writeData:postDataChunk];
	}
}

@end
