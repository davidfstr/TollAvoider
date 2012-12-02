//
//  TADirectionsRequest.m
//  TollAvoider
//
//  Created by David Foster on 11/28/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TADirectionsRequest.h"
#import "PPURLRequest.h"
#import "JSON.h"
#import "TADirectionsRoute.h"
#import "TAAnalytics.h"


@interface TADirectionsRequest()
@property (nonatomic, readwrite, retain) NSArray *routes;
+ (NSArray *)decodePolylinePoints:(NSString *)encoded;
+ (BOOL)lineSegmentsIntersectP1:(CLLocationCoordinate2D)p1
                             p2:(CLLocationCoordinate2D)p2
                             p3:(CLLocationCoordinate2D)p3
                             p4:(CLLocationCoordinate2D)p4;
- (void)reportError:(NSString *)analyticsErrorDescription;
- (void)reportNoRouteFound;
- (void)reportRoutesFound:(NSArray *)theRoutes;
@end


@implementation TADirectionsRequest

static CLLocationCoordinate2D WA520_PERPENDICULAR_LINE_SEGMENT_P1 = { 47.654057, -122.254143 };
static CLLocationCoordinate2D WA520_PERPENDICULAR_LINE_SEGMENT_P2 = { 47.625141, -122.264099 };
static CLLocationCoordinate2D I90_PERPENDICULAR_LINE_SEGMENT_P1 = { 47.601532, -122.269592 };
static CLLocationCoordinate2D I90_PERPENDICULAR_LINE_SEGMENT_P2 = { 47.576061, -122.269592 };

- (id)initWithSource:(CLLocationCoordinate2D)theSource
         destination:(CLLocationCoordinate2D)theDestination
                type:(NSString *)theAnalyticsDirectionsType
{
    
    return [self initWithSource:theSource
                       waypoint:CLLocationCoordinate2DMake(0, 0)
                    destination:theDestination
                           type:theAnalyticsDirectionsType];
}

- (id)initWithSource:(CLLocationCoordinate2D)theSource
            waypoint:(CLLocationCoordinate2D)theWaypoint
         destination:(CLLocationCoordinate2D)theDestination
                type:(NSString *)theAnalyticsDirectionsType
{
    NSString *theWaypointName;
    if ((theWaypoint.latitude != 0) || (theWaypoint.longitude != 0)) {
        theWaypointName = [NSString stringWithFormat:@"%lf,%lf",
                        (double)theWaypoint.latitude,
                        (double)theWaypoint.longitude];
    } else {
        theWaypointName = nil;
    }
    
    return [self initWithSource:theSource
                   waypointName:theWaypointName
                    destination:theDestination
                           type:theAnalyticsDirectionsType];
}

- (id)initWithSource:(CLLocationCoordinate2D)theSource
        waypointName:(NSString *)theWaypointName
         destination:(CLLocationCoordinate2D)theDestination
                type:(NSString *)theAnalyticsDirectionsType
{
    if (self = [super init]) {
        source = theSource;
        // TODO: Remove this redundant information and update callers
        usesWaypoint = (theWaypointName != nil);
        waypointName = [theWaypointName retain];
        destination = theDestination;
        alternatives = NO;
        analyticsDirectionsType = theAnalyticsDirectionsType;
        
        status = TADirectionsNotRequested;
    }
    return self;
}

- (void)dealloc {
    [waypointName release];
    [analyticsDirectionsType release];
    [super dealloc];
}

#pragma mark - Properties

@synthesize alternatives;

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

- (TADirectionsRoute *)firstNonbridgeRoute {
    for (TADirectionsRoute *curRoute in self.routes) {
        if (!curRoute.intersects90 && !curRoute.intersects520) {
            return curRoute;
        }
    }
    return nil;
}

#pragma mark - Operations

- (void)startAsynchronous {
    NSLog(@"Searching for directions...");
    
    [TAAnalytics reportEvent:@"DirectionsSearch" params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                         analyticsDirectionsType, @"DirectionsType",
                                                         [TAAnalytics valueForCoordinate:source], @"Source",
                                                         [TAAnalytics valueForCoordinate:destination], @"Destination",
                                                         [TAAnalytics valueForQuotedString:waypointName], @"Waypoint",
                                                         nil]];
    
    self.status = TADirectionsRequesting;
    
    NSString *urlString;
    if (usesWaypoint) {
        urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%lf,%lf&destination=%lf,%lf&waypoints=%@&alternatives=%@&sensor=true",
                     (double)source.latitude, (double)source.longitude,
                     (double)destination.latitude, (double)destination.longitude,
                     [waypointName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                     alternatives ? @"true" : @"false"];
    } else {
        urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%lf,%lf&destination=%lf,%lf&alternatives=%@&sensor=true",
                     (double)source.latitude, (double)source.longitude,
                     (double)destination.latitude, (double)destination.longitude,
                     alternatives ? @"true" : @"false"];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    
    PPURLRequest *urlRequest = [PPURLRequest requestWithURL:url delegate:self];
    [urlRequest startAsynchronous];
}

- (void)openInGoogleMaps {
    NSString *urlString;
    if (usesWaypoint) {
        urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%lf,%lf&daddr=%@+to:%lf,%lf&dirflg=d",
                     (double)source.latitude, (double)source.longitude,
                     [waypointName stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                     (double)destination.latitude, (double)destination.longitude];
    } else {
        urlString = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%lf,%lf&daddr=%lf,%lf&dirflg=d",
                     (double)source.latitude, (double)source.longitude,
                     (double)destination.latitude, (double)destination.longitude];
    }
    NSURL *url = [NSURL URLWithString:urlString];
    
    [TAAnalytics reportEvent:@"ExitToDirections"
                       value:analyticsDirectionsType name:@"DirectionsType"];
    
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - PPURLRequestDelegate Methods

- (void)requestDidFinish:(PPURLRequest *)request {
    NSString *geocodingResultJson = [[[NSString alloc] initWithData:request.receivedData encoding:NSUTF8StringEncoding] autorelease];
    if (geocodingResultJson == nil) {
        NSLog(@"*** Unable to interpret directions result from server as string. Not UTF-8 encoded?");
        
        [self reportError:@"ResponseBadString"];
        return;
    }
    
    NSDictionary *geocodingResult = (NSDictionary *)[geocodingResultJson JSONValue];
    if (geocodingResult == nil) {
        NSLog(@"*** Unable to parse directions response. Not JSON?");
        
        [self reportError:@"ResponseBadJson"];
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
                    NSNumber *durationValueNumber = [duration valueForKey:@"value"];
                    NSInteger durationValue = [durationValueNumber integerValue];
                    durationValueTotal += durationValue;
                    
                    NSDictionary *distance = [leg valueForKey:@"distance"];
                    NSNumber *distanceValueNumber = [distance valueForKey:@"value"];
                    NSInteger distanceValue = [distanceValueNumber integerValue];
                    distanceValueTotal += distanceValue;
                    
                    // Detect whether any steps are intersecting WA-520 or I-90 
                    NSArray *steps = [leg valueForKey:@"steps"];
                    for (NSDictionary *step in steps) {
                        NSDictionary *polyline = [step valueForKey:@"polyline"];
                        NSString *polylinePoints = [polyline valueForKey:@"points"];
                        NSArray *polylinePointsDecoded = 
                            [TADirectionsRequest decodePolylinePoints:polylinePoints];
                        
                        for (int i=0, n=polylinePointsDecoded.count; i<n-1; i++) {
                            CLLocation *p1loc = [polylinePointsDecoded objectAtIndex:i];
                            CLLocation *p2loc = [polylinePointsDecoded objectAtIndex:i+1];
                            
                            CLLocationCoordinate2D p1 = p1loc.coordinate;
                            CLLocationCoordinate2D p2 = p2loc.coordinate;
                            
                            if ([TADirectionsRequest lineSegmentsIntersectP1:p1
                                                                          p2:p2
                                                                          p3:WA520_PERPENDICULAR_LINE_SEGMENT_P1
                                                                          p4:WA520_PERPENDICULAR_LINE_SEGMENT_P2])
                            {
                                intersects520 = YES;
                            }
                            if ([TADirectionsRequest lineSegmentsIntersectP1:p1
                                                                          p2:p2
                                                                          p3:I90_PERPENDICULAR_LINE_SEGMENT_P1
                                                                          p4:I90_PERPENDICULAR_LINE_SEGMENT_P2])
                            {
                                intersects90 = YES;
                            }
                        }
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
            
            [self reportError:[NSString stringWithFormat:@"GoogleDirectionsApiError,%@",
                               [TAAnalytics valueForQuotedString:theStatus]]];
        }
    }
}

/**
 * Decodes a polyline to an array of CLLocation coordinates.
 * 
 * Algorithm: http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/decode.js
 */
+ (NSArray *)decodePolylinePoints:(NSString *)encoded {
    int length = encoded.length;
    int index = 0;
    NSMutableArray *array = [NSMutableArray array];
    int lat = 0;
    int lng = 0;
    
    while (index < length) {
        int shift = 0;
        int result = 0;
        while (1) {
            int b = [encoded characterAtIndex:index] - 63; index++;
            result |= (b & 0x1f) << shift;
            shift += 5;
            if (!(b >= 0x20)) {
                break;
            }
        }
        int dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lat += dlat;
        
        shift = 0;
        result = 0;
        while (1) {
            int b = [encoded characterAtIndex:index] - 63; index++;
            result |= (b & 0x1f) << shift;
            shift += 5;
            if (!(b >= 0x20)) {
                break;
            }
        }
        int dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
        lng += dlng;
        
        CLLocation *location = [[[CLLocation alloc] initWithLatitude:lat * 1e-5
                                                           longitude:lng * 1e-5] autorelease];
        [array addObject:location];
    }
    
    return array;
}

/**
 * Returns whether the line segments (p1, p2) and (p3, p4) intersect.
 * 
 * Algorithm: http://paulbourke.net/geometry/lineline2d/
 */
+ (BOOL)lineSegmentsIntersectP1:(CLLocationCoordinate2D)p1
                             p2:(CLLocationCoordinate2D)p2
                             p3:(CLLocationCoordinate2D)p3
                             p4:(CLLocationCoordinate2D)p4
{
    CLLocationDegrees x1 = p1.latitude;
    CLLocationDegrees y1 = p1.longitude;
    CLLocationDegrees x2 = p2.latitude;
    CLLocationDegrees y2 = p2.longitude;
    CLLocationDegrees x3 = p3.latitude;
    CLLocationDegrees y3 = p3.longitude;
    CLLocationDegrees x4 = p4.latitude;
    CLLocationDegrees y4 = p4.longitude;
    
    CLLocationDegrees denom = ((y4 - y3)*(x2 - x1) - (x4 - x3)*(y2 - y1));
    if (denom == 0) {
        // Line segments are parallel
        // HACK: Assume not intersecting
        return NO;
    }
    CLLocationDegrees ua = ((x4 - x3)*(y1 - y3) - (y4 - y3)*(x1 - x3)) / denom;
    CLLocationDegrees ub = ((x2 - x1)*(y1 - y3) - (y2 - y1)*(x1 - x3)) / denom;
    
    return ((0 <= ua) && (ua <= 1)) && ((0 <= ub) && (ub <= 1));
}

- (void)requestDidFail:(PPURLRequest *)request {
    NSLog(@"*** Error getting directions: %@", request.error);
    
    [self reportError:[NSString stringWithFormat:@"RequestFail,%d,%@",
                       (int) request.error.code,
                       [TAAnalytics valueForQuotedString:request.error.domain]]];
}

- (void)reportError:(NSString *)analyticsErrorDescription {
    [TAAnalytics reportEvent:@"DirectionsError" params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        analyticsDirectionsType, @"DirectionsType",
                                                        [TAAnalytics valueForCoordinate:source], @"Source",
                                                        [TAAnalytics valueForCoordinate:destination], @"Destination",
                                                        [TAAnalytics valueForQuotedString:waypointName], @"Waypoint",
                                                        analyticsErrorDescription, @"Error",
                                                        nil]];
    
    self.status = TADirectionsError;
}

- (void)reportNoRouteFound {
    [TAAnalytics reportEvent:@"DirectionsNotFound" params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           analyticsDirectionsType, @"DirectionsType",
                                                           [TAAnalytics valueForCoordinate:source], @"Source",
                                                           [TAAnalytics valueForCoordinate:destination], @"Destination",
                                                           [TAAnalytics valueForQuotedString:waypointName], @"Waypoint",
                                                           nil]];
    
    self.status = TADirectionsZeroResults;
}

- (void)reportRoutesFound:(NSArray *)theRoutes {
    self.routes = theRoutes;
    
    // NOTE: Must log to analytics /after/ the routes are set above so that the 'firstNonbridgeRoute' property works
    TADirectionsRoute *firstNonbridgeRoute = self.firstNonbridgeRoute;
    TADirectionsRoute *firstRoute = [self.routes objectAtIndex:0];
    TADirectionsRoute *designatedRoute = ([analyticsDirectionsType isEqualToString:@"Direct"])
        ? firstNonbridgeRoute
        : firstRoute;
    [TAAnalytics reportEvent:@"DirectionsFound" params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                        analyticsDirectionsType, @"DirectionsType",
                                                        [TAAnalytics valueForCoordinate:source], @"Source",
                                                        [TAAnalytics valueForCoordinate:destination], @"Destination",
                                                        [TAAnalytics valueForQuotedString:waypointName], @"Waypoint",
                                                        [TAAnalytics valueForRoute:firstNonbridgeRoute], @"FirstNonbridgeRoute",
                                                        [TAAnalytics valueForRoute:firstRoute], @"FirstRoute",
                                                        [TAAnalytics valueForRoute:designatedRoute], @"DesignatedRoute",
                                                        nil]];
    
    self.status = TADirectionsOK;
}

@end
