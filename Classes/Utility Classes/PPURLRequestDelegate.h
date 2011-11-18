//
//  PPURLRequestDelegate.h
//  ParkPlace
//
//  Created by David Foster on 1/26/11.
//  Copyright 2011 Seabalt. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PPURLRequest;

@protocol PPURLRequestDelegate<NSObject>

/** Notified when a URL was retrieved successfully. */
- (void)requestDidFinish:(PPURLRequest *)request;
/** Notified when a URL couldn't be retrieved. */
- (void)requestDidFail:(PPURLRequest *)request;

@end
