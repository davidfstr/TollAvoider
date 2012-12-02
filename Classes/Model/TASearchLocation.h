//
//  TASearchLocation.h
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Represents a specific location returned as a result of a search query
 * that has been successfully geocoded.
 */
@interface TASearchLocation : NSObject {
    NSString *address;
    CLLocationCoordinate2D location;
}

@property (nonatomic, readonly, retain) NSString *address;
@property (nonatomic, readonly) CLLocationCoordinate2D location;

- (id)initWithAddress:(NSString *)theAddress location:(CLLocationCoordinate2D)theLocation;

@end

