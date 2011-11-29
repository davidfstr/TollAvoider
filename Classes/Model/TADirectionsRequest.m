//
//  TADirectionsRequest.m
//  TollAvoider
//
//  Created by David Foster on 11/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TADirectionsRequest.h"
#import "PPURLRequest.h"
#import "JSON.h"


@interface TADirectionsRequest()
- (void)reportError;
- (void)reportNoRouteFound;
- (void)reportRoutesFound:(NSArray *)resultRoutes;
@end


@implementation TADirectionsRequest

- (id)initWithSource:(CLLocationCoordinate2D)theSource
         destination:(CLLocationCoordinate2D)theDestination
{
    if (self = [super init]) {
        source = theSource;
        usesWaypoint = NO;
        waypoint = CLLocationCoordinate2DMake(0, 0);
        destination = theDestination;
    }
    return self;
}

- (id)initWithSource:(CLLocationCoordinate2D)theSource
            waypoint:(CLLocationCoordinate2D)theWaypoint
         destination:(CLLocationCoordinate2D)theDestination
{
    if (self = [super init]) {
        source = theSource;
        usesWaypoint = YES;
        waypoint = theWaypoint;
        destination = theDestination;
    }
    return self;
}

- (void)startAsynchronous {
    NSLog(@"Searching for directions...");
    
    NSString *urlString;
    if (usesWaypoint) {
        urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%lf,%lf&destination=%lf,%lf&waypoints=%lf,%lf&alternatives=true&sensor=true",
                     (double)source.latitude, (double)source.longitude,
                     (double)destination.latitude, (double)destination.longitude,
                     (double)waypoint.latitude, (double)waypoint.longitude];
    } else {
        urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%lf,%lf&destination=%lf,%lf&alternatives=true&sensor=true",
                     (double)source.latitude, (double)source.longitude,
                     (double)destination.latitude, (double)destination.longitude];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    
    PPURLRequest *urlRequest = [PPURLRequest requestWithURL:url delegate:self];
    [urlRequest startAsynchronous];
}

#pragma mark - PPURLRequestDelegate Methods

- (void)requestDidFinish:(PPURLRequest *)request {
    NSString *geocodingResultJson = [[[NSString alloc] initWithData:request.receivedData encoding:NSUTF8StringEncoding] autorelease];
    if (geocodingResultJson == nil) {
        NSLog(@"*** Unable to interpret directions result from server as string. Not UTF-8 encoded?");
        
        [self reportError];
        return;
    }
    
    NSDictionary *geocodingResult = (NSDictionary *)[geocodingResultJson JSONValue];
    if (geocodingResult == nil) {
        NSLog(@"*** Unable to parse directions response. Not JSON?");
        
        [self reportError];
        return;
    }
    
    NSString *theStatus = [geocodingResult valueForKey:@"status"];
    if (theStatus) {
        if ([theStatus isEqualToString:@"OK"]) {
            // Got results
            NSArray *routes = [geocodingResult valueForKey:@"routes"];
            
            NSMutableArray *theResultRoutes = [NSMutableArray arrayWithCapacity:routes.count];
            for (NSDictionary *route in routes) {
                NSString *summary = [route valueForKey:@"summary"];
                
                NSInteger durationValueTotal = 0;   // in seconds
                NSInteger distanceValueTotal = 0;   // in meters
                
                //BOOL intersects520 = NO;
                //BOOL intersects90 = NO;
                NSArray *legs = [route valueForKey:@"legs"];
                for (NSDictionary *leg in legs) {
                    NSDictionary *duration = [leg valueForKey:@"duration"];
                    NSInteger durationValue = [[duration valueForKey:@"value"] integerValue];
                    durationValueTotal += durationValue;
                    
                    NSDictionary *distance = [leg valueForKey:@"distance"];
                    NSInteger distanceValue = [[distance valueForKey:@"value"] integerValue];
                    distanceValueTotal += distanceValue;
                    
                    NSArray *steps = [leg valueForKey:@"steps"];
                    for (NSDictionary *step in steps) {
                        //NSDictionary *polyline = [step valueForKey:@"polyline"];
                        //NSString *polylinePoints = [polyline valueForKey:@"points"];
                        
                        // TODO: Decode 'polylinePoints' and update 'intersects520' and 'intersects90'
                    }
                }
                
                NSString *durationText = [NSString stringWithFormat:@"%d min", (int) (durationValueTotal / 60)];
                NSString *distanceText = [NSString stringWithFormat:@"%d m", (int) distanceValueTotal];
                
                NSLog(@"Found: %@, %@, %@", summary, durationText, distanceText);
                // TODO: Construct TARouteResult object
                NSObject *resultRoute = @"BOGUS";
                [theResultRoutes addObject:resultRoute];
            }
            
            if (theResultRoutes.count == 0) {
                [self reportNoRouteFound];
            } else if (theResultRoutes.count == 1) {
                [self reportRoutesFound:theResultRoutes];
            }
        } else if ([theStatus isEqualToString:@"ZERO_RESULTS"]) {
            // No results
            NSLog(@"No route found.");
            
            [self reportNoRouteFound];
        } else {
            // Other error
            NSLog(@"*** Error getting directions: Got status code '%@'.", theStatus);
            
            [self reportError];
        }
    }
}

- (void)requestDidFail:(PPURLRequest *)request {
    NSLog(@"*** Error getting directions: %@", request.error);
    
    [self reportError];
}

- (void)reportError {
    // TODO: ...
}

- (void)reportNoRouteFound {
    // TODO: ...
}

- (void)reportRoutesFound:(NSArray *)resultRoutes {
    // TODO: ...
}

@end
