//
//  TAAnalytics.m
//  TollAvoider
//
//  Created by David Foster on 12/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TAAnalytics.h"
#import "FlurryAnalytics.h"
#import "TAAppDelegate.h"


@interface TAAnalytics()
static void uncaughtExceptionHandler(NSException *exception);
@end


@implementation TAAnalytics

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

@end
