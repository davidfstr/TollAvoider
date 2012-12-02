//
//  TADirectionsRoute.m
//  TollAvoider
//
//  Created by David Foster on 11/29/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TADirectionsRoute.h"

@implementation TADirectionsRoute

#define MILES_PER_METER 0.000621371192237334

#pragma mark - Init

- (id)initWithTitle:(NSString *)theTitle
      durationValue:(NSInteger)theDurationValue
      distanceValue:(NSInteger)theDistanceValue
      intersects520:(BOOL)theIntersects520
       intersects90:(BOOL)theIntersects90
{
    if (self = [super init]) {
        title = [theTitle retain];
        durationValue = theDurationValue;
        distanceValue = theDistanceValue;
        intersects520 = theIntersects520;
        intersects90 = theIntersects90;
    }
    return self;
}

- (void)dealloc {
    [title release];
    [super dealloc];
}

#pragma mark - Properties

@synthesize title;

@synthesize durationValue;
@synthesize distanceValue;

- (NSString *)durationText {
    return [NSString stringWithFormat:@"%d min", (int) (durationValue / 60)];
}

- (NSString *)distanceText {
    CGFloat distanceInMeters = distanceValue;
    CGFloat distanceInMiles = distanceInMeters * MILES_PER_METER;
    return [NSString stringWithFormat:@"%.1lf mi", (double) distanceInMiles];
}

@synthesize intersects520;
@synthesize intersects90;

@end
