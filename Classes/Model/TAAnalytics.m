//
//  TAAnalytics.m
//  TollAvoider
//
//  Created by David Foster on 12/1/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TAAnalytics.h"
#import "FlurryAnalytics.h"
#import "TAAppDelegate.h"
#import "TASearchLocation.h"
#import "TADirectionsRoute.h"


@interface TAAnalytics()
static void uncaughtExceptionHandler(NSException *exception);
- (void)didShowViewController:(UIViewController *)viewController;
@end


@implementation TAAnalytics

#pragma mark - Init

+ (TAAnalytics *)instance {
    static TAAnalytics *instance = nil;
    if (!instance) {
        instance = [[TAAnalytics alloc] init];
    }
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        // nothing
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - Properties

+ (BOOL)enabled {
#if TARGET_IPHONE_SIMULATOR
    // Don't bombard Flurry with analytics from development
    return NO;
#else
    return YES;
#endif
}

#pragma mark - Operations

// NOTE: Cannot name 'initialize' since Cocoa automatically calls class methods with that name
//       at class initialization time, which is not desirable here.
+ (void)initializeAnalytics {
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    // Gather basic metrics
    if ([TAAnalytics enabled]) {
        [FlurryAnalytics startSession:@"5JJSRKQZXZMYUPXERIFA"];
    }
    
    // Register the install ID, generating a unique one if needed
    NSString *installID = [[TAAppDelegate instance].prefs stringForKey:@"AnalyticsInstallID"];
    if ([installID isEqualToString:@""]) {
        CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef uuidStringRef = CFUUIDCreateString(nil, uuidRef);
        NSString *uuidString = [(NSString *)CFStringCreateCopy(NULL, uuidStringRef) autorelease];
        CFRelease(uuidRef);
        CFRelease(uuidStringRef);
        
        installID = uuidString;
        [[TAAppDelegate instance].prefs setObject:installID forKey:@"AnalyticsInstallID"];
    }
    if ([TAAnalytics enabled]) {
        [FlurryAnalytics setUserID:installID];
    }
}

static void uncaughtExceptionHandler(NSException *exception) {
    if ([TAAnalytics enabled]) {
        [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
    }
}

+ (void)reportLocation:(CLLocation *)newLocation {
    if ([TAAnalytics enabled]) {
        [FlurryAnalytics setLatitude:newLocation.coordinate.latitude
                           longitude:newLocation.coordinate.longitude
                  horizontalAccuracy:newLocation.horizontalAccuracy
                    verticalAccuracy:newLocation.verticalAccuracy];
    }
}

+ (void)reportSwitchToView:(UIViewController *)viewController {
    [[TAAnalytics instance] didShowViewController:viewController];
}

+ (void)reportSwitchToViewWithID:(NSString *)viewId {
    // Don't log the same controller twice in a row
    static NSString *lastReportedViewId = nil;
    if ([lastReportedViewId isEqualToString:viewId]) {
        return;
    }
    [lastReportedViewId autorelease];
    lastReportedViewId = [viewId retain];
    
    [TAAnalytics reportEvent:@"ShowView" params:[NSDictionary dictionaryWithObjectsAndKeys:
                                                 viewId, @"View", nil]];
}

+ (void)reportEvent:(NSString *)eventId params:(NSDictionary *)_params {
    // Add additional parameters common to all events
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:_params];
    {
        NSDate *date = [NSDate date];
        NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss ZZ"];
        NSString *dateString = [dateFormatter stringFromDate:date];
        
        [params setObject:dateString forKey:@"_Time"];
    }
    
    // Log to console
    NSLog(@"> %@", eventId);
    for (NSString *key in params) {
        NSLog(@"    | %@: '%@'", key, [params objectForKey:key]);
    }
    
    if ([TAAnalytics enabled]) {
        [FlurryAnalytics logEvent:eventId withParameters:params];
    }
}

+ (void)reportEvent:(NSString *)eventId value:(NSString *)value name:(NSString *)name {
    [TAAnalytics reportEvent:eventId
                      params:[NSDictionary dictionaryWithObjectsAndKeys:
                              value, name,
                              nil]];
}

+ (void)reportEvent:(NSString *)eventId {
    [TAAnalytics reportEvent:eventId
                      params:[NSDictionary dictionary]];
}

#pragma mark - View Change Listener

// NOTE: In PPAnalytics (which this class is based on), there is a lot more fancy logic in this section
//       to handle automatic detection of switches between views. This app is sufficiently simple
//       that all such switches are reported manually.

- (void)didShowViewController:(UIViewController *)viewController {
    // Drill into tab bar controllers
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        viewController = ((UITabBarController *)viewController).selectedViewController;
    }
    
    // Drill into navigation controllers
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        // NOTE: Don't use 'visibleViewController', since that will pick up modal controllers that are being dismissed
        viewController = ((UINavigationController *)viewController).topViewController;
    }
    
    // Determine ID of view to log
    NSString *viewId;
    SEL analyticsViewId = @selector(analyticsViewId);
    if ([viewController respondsToSelector:analyticsViewId]) {
        // If present, use [analyticsViewId] as the view ID
        viewId = [viewController performSelector:analyticsViewId];
    } else {
        // Otherwise use view controller's classname as the view ID
        viewId = NSStringFromClass([viewController class]);
    }
    
    [TAAnalytics reportSwitchToViewWithID:viewId];
}

#pragma mark - Value Formatting

+ (NSString *)valueForQuotedString:(NSString *)str {
    NSString *escapedStr = [str stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    return [NSString stringWithFormat:@"\"%@\"", escapedStr];
}

+ (NSString *)valueForCoordinate:(CLLocationCoordinate2D)location {
    return [NSString stringWithFormat:@"%lf,%lf",
            (double) location.latitude,
            (double) location.longitude];
}

+ (NSString *)valueForLocation:(TASearchLocation *)location {
    return [NSString stringWithFormat:@"%lf,%lf,%@",
            (double) location.location.latitude,
            (double) location.location.longitude,
            [TAAnalytics valueForQuotedString:location.address]];
}

+ (NSString *)valueForLocationArray:(NSArray *)locationArray {
    NSMutableString *stringBuf = [[[NSMutableString alloc] initWithCapacity:64] autorelease];
    BOOL firstLocation = YES;
    for (TASearchLocation *location in locationArray) {
        if (firstLocation) {
            firstLocation = NO;
        } else {
            [stringBuf appendString:@";"];
        }
        [stringBuf appendString:[TAAnalytics valueForLocation:location]];
    }
    return stringBuf;
}

+ (NSString *)valueForBool:(BOOL)boolValue {
    return boolValue ? @"YES" : @"NO";
}

+ (NSString *)valueForRoute:(TADirectionsRoute *)route {
    return [NSString stringWithFormat:@"%@;%@;%@",
            route.durationText,
            route.distanceText,
            [TAAnalytics valueForQuotedString:route.title]];
}

@end
