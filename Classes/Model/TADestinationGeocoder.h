//
//  TADestinationGeocoder.h
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TADestinationGeocoderStatus.h"
#import "PPURLRequestDelegate.h"

@class TASearchLocation;

@interface TADestinationGeocoder : NSObject <PPURLRequestDelegate> {
    TADestinationGeocoderStatus status;
    
    NSString *query;
    NSArray *searchLocations;   // <TASearchLocation>
    TASearchLocation *searchLocationChosen;
}

/** The status of the current search request. */
@property (nonatomic, readonly) TADestinationGeocoderStatus status;
/** The last search query, or nil if no search has been performed. */
@property (nonatomic, readonly, retain) NSString *query;
/** List of locations that the last search query returned, or nil if they haven't been fetched yet. */
@property (nonatomic, readonly, retain) NSArray *searchLocations;
/** Location that the user chose to search near, or nil if no choice has been made.  */
@property (nonatomic, readonly, retain) TASearchLocation *searchLocationChosen;

+ (TADestinationGeocoder *)instance;

- (void)startSearchWithQuery:(NSString *)theQuery;
- (void)continueSearchWithResolvedLocation:(TASearchLocation *)location;

@end
