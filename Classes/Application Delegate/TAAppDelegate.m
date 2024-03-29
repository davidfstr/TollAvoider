//
//  TAAppDelegate.m
//  TollAvoider
//
//  Created by David Foster on 11/15/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TAAppDelegate.h"
#import "TALocationTracking.h"
#import "TASearchViewController.h"
#import "TAAnalytics.h"


@interface TAAppDelegate()
- (void)doTasksForEnterBackgroundOrWillTerminate;
@end


@implementation TAAppDelegate

@synthesize prefs;

#pragma mark - Init

+ (TAAppDelegate *)instance {
    return (TAAppDelegate *)UIApplication.sharedApplication.delegate;
}

- (id)init {
    if ((self = [super init])) {
        // Load preferences from disk
        prefs = [[NSUserDefaults standardUserDefaults] retain];
        [prefs registerDefaults:[NSDictionary dictionaryWithContentsOfFile:
                                 [[NSBundle mainBundle] pathForResource:@"DefaultPreferences" ofType:@"plist"]]];
    }
    return self;
}

- (void)dealloc {
    [window release];
    [navController release];
    [searchViewController release];
    [prefs release];
    [super dealloc];
}

#pragma mark - Application Lifecycle

/**
 * Invoked after main NIB loaded and app has finished launching.
 */
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Initialize analytics (first)
    [TAAnalytics initializeAnalytics];
    [TAAnalytics reportEvent:@"ApplicationStateChanged"
                      params:[NSDictionary dictionaryWithObjectsAndKeys:
                              @"Launched", @"State",
                              // Special parameters for the Launched event
                              [[UIDevice currentDevice] systemName], @"SystemName",
                              [[UIDevice currentDevice] systemVersion], @"SystemVersion",
                              nil]];
    
    // Initialize other subsystems
    [[TALocationTracking instance] initialize];
    
    // Configure and show main window
    [window addSubview:navController.view];
    [window makeKeyAndVisible];
    
    // Configure navigation bar to be orange
    navController.navigationBar.tintColor = [UIColor colorWithRed:.96   // 245
                                                            green:.40   // 102
                                                             blue:.10   // 25
                                                            alpha:1.0];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    
    [TAAnalytics reportEvent:@"ApplicationStateChanged" value:@"Inactive" name:@"State"];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    
    [TAAnalytics reportEvent:@"ApplicationStateChanged" value:@"Background" name:@"State"];
    
    [self doTasksForEnterBackgroundOrWillTerminate];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
    
    [TAAnalytics reportEvent:@"ApplicationStateChanged" value:@"Foreground" name:@"State"];
    
    [[TALocationTracking instance] markLocationAsStale];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
    
    [TAAnalytics reportEvent:@"ApplicationStateChanged" value:@"Active" name:@"State"];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    
    [TAAnalytics reportEvent:@"ApplicationStateChanged" value:@"Terminated" name:@"State"];
    
    [self doTasksForEnterBackgroundOrWillTerminate];
}

- (void)doTasksForEnterBackgroundOrWillTerminate {
    // Save preferences to disk
    NSLog(@"Saving preferences");
    [prefs synchronize];
}

#pragma mark - UINavigationControllerDelegate Methods

- (void)navigationController:(UINavigationController *)theNavigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    BOOL shouldHideBar = (viewController == searchViewController);
    [navController setNavigationBarHidden:shouldHideBar animated:YES];
    
    [TAAnalytics reportSwitchToView:navController];
}

@end
