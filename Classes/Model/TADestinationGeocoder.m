//
//  TADestinationGeocoder.m
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TADestinationGeocoder.h"
#import "PPURLRequest.h"
#import "TASearchLocation.h"
#import "JSON.h"


@interface TADestinationGeocoder()
@property (nonatomic, readwrite) TADestinationGeocoderStatus status;                // private writable
@property (nonatomic, readwrite, retain) NSString *query;                           // private writable
@property (nonatomic, readwrite, retain) NSArray *searchLocations;                  // private writable
@property (nonatomic, readwrite, retain) TASearchLocation *searchLocationChosen;    // private writable
- (void)continueSearchWithLocation:(TASearchLocation *)location;
@end


@implementation TADestinationGeocoder

#pragma mark - Init

+ (TADestinationGeocoder *)instance {
    static TADestinationGeocoder *instance = nil;
    if (!instance) {
        instance = [[TADestinationGeocoder alloc] init];
    }
    return instance;
}

#pragma mark - Properties

- (TADestinationGeocoderStatus)status {
    return status;
}

- (void)setStatus:(TADestinationGeocoderStatus)theStatus {
    status = theStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TADestinationGeocoderStatusDidChange" object:self];
}

@synthesize query;
@synthesize searchLocations;
@synthesize searchLocationChosen;

#pragma mark - Operations

- (void)startSearchWithQuery:(NSString *)theQuery {
    switch (status) {
        case TAGeocoderNotGeocoding:
            // Never loaded before
            break;
        case TAGeocoderGeocoding:
            // TODO: Cancel outstanding request
            NSLog(@"*** Ignoring request to reload while already loaded since this is not implemented yet.");
            return;
        case TAGeocoderGeocodeAmbiguous:
        case TAGeocoderGeocodeNoMatch:
        case TAGeocoderGeocodeFailed:
        case TAGeocoderGeocodeComplete:
            // Reload
            break;
        default:
            NSLog(@"*** Unknown TADestinationGeocoderStatus: %d", (int) status);
            return;
    }
    self.query = theQuery;
    self.searchLocations = nil;
    self.searchLocationChosen = nil;
    
    self.status = TAGeocoderGeocoding;
    
    NSString *searchQueryEscaped = [theQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *geocodeUrl = [NSString stringWithFormat:
                            @"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=true",
                            searchQueryEscaped];
    
    NSLog(@"Searching for: %@", theQuery);
    PPURLRequest *geocodeRequest = [PPURLRequest requestWithURL:[NSURL URLWithString:geocodeUrl] delegate:self];
    [geocodeRequest startAsynchronous];
}

- (void)continueSearchWithUniqueLocation:(TASearchLocation *)location {
    [self continueSearchWithLocation:location];
}

- (void)continueSearchWithResolvedLocation:(TASearchLocation *)location {
    [self continueSearchWithLocation:location];
}

- (void)continueSearchWithLocation:(TASearchLocation *)location {
    self.searchLocationChosen = location;
    self.status = TAGeocoderGeocodeComplete;
}

#pragma mark - PPURLRequestDelegate Methods

- (void)requestDidFinish:(PPURLRequest *)request {
    if (status == TAGeocoderGeocoding) {
        NSString *geocodingResultJson = [[[NSString alloc] initWithData:request.receivedData encoding:NSUTF8StringEncoding] autorelease];
        if (geocodingResultJson == nil) {
            NSLog(@"*** Unable to interpret geocoding result from server as string. Not UTF-8 encoded?");
            
            self.status = TAGeocoderGeocodeFailed;
            return;
        }
        
        NSDictionary *geocodingResult = (NSDictionary *)[geocodingResultJson JSONValue];
        if (geocodingResult == nil) {
            NSLog(@"*** Unable to parse geocoding response. Not JSON?");
            
            self.status = TAGeocoderGeocodeFailed;
            return;
        }
        
        NSString *theStatus = [geocodingResult valueForKey:@"status"];
        if (theStatus) {
            if ([theStatus isEqualToString:@"OK"]) {
                // Got results
                NSArray *results = [geocodingResult valueForKey:@"results"];
                
                NSMutableArray *theSearchLocations = [NSMutableArray arrayWithCapacity:results.count];
                for (NSDictionary *result in results)
                {
                    NSDictionary *geometry = [result objectForKey:@"geometry"];
                    NSDictionary *location = [geometry objectForKey:@"location"];
                    
                    NSString *formattedAddress = [result objectForKey:@"formatted_address"];
                    double lat = [(NSNumber *)[location objectForKey:@"lat"] doubleValue];
                    double lng = [(NSNumber *)[location objectForKey:@"lng"] doubleValue];
                    
                    NSLog(@"Found: (%lf,%lf): %@", lat, lng, formattedAddress);
                    [theSearchLocations addObject:[[[TASearchLocation alloc] initWithAddress:formattedAddress
                                                                                    location:CLLocationCoordinate2DMake(lat, lng)] autorelease]];
                }
                
                self.searchLocations = theSearchLocations;
                if (theSearchLocations.count == 0) {
                    self.status = TAGeocoderGeocodeNoMatch;
                } else if (theSearchLocations.count == 1) {
                    [self continueSearchWithUniqueLocation:[theSearchLocations objectAtIndex:0]];
                } else {
                    self.status = TAGeocoderGeocodeAmbiguous;
                }
            } else if ([theStatus isEqualToString:@"ZERO_RESULTS"]) {
                // No results
                NSLog(@"Not found");
                
                self.status = TAGeocoderGeocodeNoMatch;
            } else {
                // Other error
                NSLog(@"*** Error geocoding search query: Got status code '%@'.", theStatus);
                
                self.status = TAGeocoderGeocodeFailed;
            }
        }
    }
}

- (void)requestDidFail:(PPURLRequest *)request {
    if (status == TAGeocoderGeocoding) {
        NSLog(@"*** Error geocoding search query: %@", request.error);
        
        self.status = TAGeocoderGeocodeFailed;
    }
}

@end
