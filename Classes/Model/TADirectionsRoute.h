//
//  TADirectionsRoute.h
//  TollAvoider
//
//  Created by David Foster on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TADirectionsRoute : NSObject {
    NSString *title;
    NSInteger durationValue;
    NSInteger distanceValue;
    BOOL intersects520;
    BOOL intersects90;
}

@property (nonatomic, readonly, retain) NSString *title;
@property (nonatomic, readonly, retain) NSString *durationText;
@property (nonatomic, readonly, retain) NSString *distanceText;

- (id)initWithTitle:(NSString *)title
      durationValue:(NSInteger)durationValue
      distanceValue:(NSInteger)distanceValue
      intersects520:(BOOL)intersects520
       intersects90:(BOOL)intersects90;

@end