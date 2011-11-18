//
//  PPURLRequest.h
//  ParkPlace
//
//  Created by David Foster on 1/26/11.
//  Copyright 2011 Seabalt. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol PPURLRequestDelegate;

/**
 * Encapsulates a single asynchronous request for a URL.
 * 
 * PPURLRequest retains its delegate when it is initialized.
 * It releases the delegate when it finishes loading, fails, or is canceled.
 */
@interface PPURLRequest : NSObject {
    NSURL *url;
    id <PPURLRequestDelegate> delegate;
    NSMutableData *receivedData;
    NSError *error;
}

/** URL that will be downloaded. */
@property (nonatomic, readonly, retain) NSURL *url;
/** Delegate that will be notified upon download completion or failure. */
@property (nonatomic, readonly, retain) id <PPURLRequestDelegate> delegate;
/** Contains the downloaded data. Note that there may be data even if there was an error. */
@property (nonatomic, readonly, retain) NSMutableData *receivedData;
/** Error received while downloading data, or nil if was successful. */
@property (nonatomic, readonly, retain) NSError *error;

- (id)initWithURL:(NSURL *)theURL
         delegate:(id <PPURLRequestDelegate>)theDelegate;

+ (PPURLRequest *)requestWithURL:(NSURL *)theURL
                        delegate:(id <PPURLRequestDelegate>)theDelegate;

/** Starts downloading the URL in the background. */
- (void)startAsynchronous;
/** Downloading the URL synchronously, blocking until completion. */
- (void)runSynchronous;

@end
