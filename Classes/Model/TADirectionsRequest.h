//
//  TADirectionsRequest.h
//  TollAvoider
//
//  Created by David Foster on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPURLRequestDelegate.h"

@interface TADirectionsRequest : NSObject <PPURLRequestDelegate> {
    CLLocationCoordinate2D source;
    BOOL usesWaypoint;
    CLLocationCoordinate2D waypoint;
    CLLocationCoordinate2D destination;
}

- (id)initWithSource:(CLLocationCoordinate2D)theSource
         destination:(CLLocationCoordinate2D)theDestination;

- (id)initWithSource:(CLLocationCoordinate2D)theSource
            waypoint:(CLLocationCoordinate2D)theWaypoint
         destination:(CLLocationCoordinate2D)theDestination;

- (void)startAsynchronous;

@end
