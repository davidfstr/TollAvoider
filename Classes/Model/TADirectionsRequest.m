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
#import "TADirectionsRoute.h"


@interface TADirectionsRequest()
@property (nonatomic, readwrite, retain) NSArray *routes;
- (void)reportError;
- (void)reportNoRouteFound;
- (void)reportRoutesFound:(NSArray *)theRoutes;
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
        
        status = TADirectionsNotRequested;
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

#pragma mark - Properties

- (TADirectionsRequestStatus)status {
    return status;
}

- (void)setStatus:(TADirectionsRequestStatus)theStatus {
    if (theStatus == status) {
        return;
    }
    
    status = theStatus;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TADirectionsRequestStatusDidChange" object:self];
}

@synthesize routes;

#pragma mark - Operations

- (void)startAsynchronous {
    NSLog(@"Searching for directions...");
    self.status = TADirectionsRequesting;
    
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
            NSArray *routesJson = [geocodingResult valueForKey:@"routes"];
            
            NSMutableArray *theRoutes = [NSMutableArray arrayWithCapacity:routesJson.count];
            for (NSDictionary *routeJson in routesJson) {
                NSString *summary = [routeJson valueForKey:@"summary"];
                
                NSInteger durationValueTotal = 0;   // in seconds
                NSInteger distanceValueTotal = 0;   // in meters
                
                BOOL intersects520 = NO;
                BOOL intersects90 = NO;
                NSArray *legs = [routeJson valueForKey:@"legs"];
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
                
                TADirectionsRoute *route = 
                    [[[TADirectionsRoute alloc] initWithTitle:summary
                                                durationValue:durationValueTotal
                                                distanceValue:distanceValueTotal
                                                intersects520:intersects520
                                                 intersects90:intersects90]
                     autorelease];
                NSString *durationText = route.durationText;
                NSString *distanceText = route.distanceText;
                
                NSLog(@"Found: %@, %@, %@", summary, durationText, distanceText);
                [theRoutes addObject:route];
            }
            
            if (theRoutes.count == 0) {
                [self reportNoRouteFound];
            } else {
                [self reportRoutesFound:theRoutes];
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
    self.status = TADirectionsError;
}

- (void)reportNoRouteFound {
    self.status = TADirectionsZeroResults;
}

- (void)reportRoutesFound:(NSArray *)theRoutes {
    self.routes = theRoutes;
    
    self.status = TADirectionsOK;
}

@end
