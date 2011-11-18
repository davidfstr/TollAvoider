//
//  PPURLRequest.m
//  ParkPlace
//
//  Created by David Foster on 1/26/11.
//  Copyright 2011 Seabalt. All rights reserved.
//

#import "PPURLRequest.h"
#import "PPURLRequestDelegate.h"


@interface PPURLRequest()
- (NSURLRequest *)request;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (NSCachedURLResponse *) connection:(NSURLConnection *)connection
				   willCacheResponse:(NSCachedURLResponse *)cachedResponse;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)theError;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
@end


@implementation PPURLRequest

#define DEFAULT_TIMEOUT_INTERVAL 5
#define DEFAULT_DOWNLOAD_BUFFER_CAPACITY (1024 * 16)

@synthesize url;
@synthesize delegate;
@synthesize receivedData;
@synthesize error;

#pragma mark -
#pragma mark Init

- (id)initWithURL:(NSURL *)theURL
         delegate:(id <PPURLRequestDelegate>)theDelegate
{
    if (self = [super init]) {
        url = [theURL retain];
        delegate = [theDelegate retain];
    }
    return self;
}

+ (PPURLRequest *)requestWithURL:(NSURL *)theURL
                        delegate:(id <PPURLRequestDelegate>)theDelegate
{
    return [[[PPURLRequest alloc] initWithURL:theURL delegate:theDelegate] autorelease];
}

- (void)dealloc {
    [url release];
    [delegate release];
    [receivedData release];
    [error release];
    [super dealloc];
}

#pragma mark -
#pragma mark Operations

- (void)startAsynchronous {
    [NSURLConnection connectionWithRequest:[self request] delegate:self];
}

- (void)runSynchronous {
    NSURLResponse *response;
    NSError *theError;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:[self request]
                                         returningResponse:&response
                                                     error:&theError];
    if (data) {
        [self connection:nil didReceiveResponse:response];
        [self connection:nil didReceiveData:data];
        [self connectionDidFinishLoading:nil];
    } else {
        [self connection:nil didFailWithError:theError];
    }
}

#pragma mark -
#pragma mark Internal
     
- (NSURLRequest *)request {
    return [NSURLRequest requestWithURL:url
                            cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                        timeoutInterval:DEFAULT_TIMEOUT_INTERVAL];
}

#pragma mark -
#pragma mark NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // Allocate memory to receive data
    long long contentLength = [response expectedContentLength];
	if (contentLength == NSURLResponseUnknownLength) {
		contentLength = DEFAULT_DOWNLOAD_BUFFER_CAPACITY;
	}
	receivedData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)contentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [receivedData appendData:data];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection
				   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    // All cache management is being done manually
	return nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)theError {
	error = [theError retain];
    [delegate requestDidFail:self];
    
    // Detatch delegate
    [delegate release]; delegate = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [delegate requestDidFinish:self];
    
	// Detatch delegate
    [delegate release]; delegate = nil;
}

@end
