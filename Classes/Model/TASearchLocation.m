//
//  TASearchLocation.m
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TASearchLocation.h"

@implementation TASearchLocation

@synthesize address;
@synthesize location;

#pragma mark - Init

- (id)initWithAddress:(NSString *)theAddress location:(CLLocationCoordinate2D)theLocation {
    if (self = [super init]) {
        address = [theAddress retain];
        location = theLocation;
    }
    return self;
}

- (void)dealloc {
    [address release];
    [super dealloc];
}

@end

