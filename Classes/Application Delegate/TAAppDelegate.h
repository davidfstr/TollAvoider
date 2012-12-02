//
//  TAAppDelegate.h
//  TollAvoider
//
//  Created by David Foster on 11/15/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TASearchViewController;

@interface TAAppDelegate : UIResponder <UIApplicationDelegate, UINavigationControllerDelegate> {
    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navController;
    IBOutlet TASearchViewController *searchViewController;
}

/** Application preferences. */
@property (nonatomic, readonly, assign) NSUserDefaults *prefs;

/**
 * The single application delegate instance.
 */
+ (TAAppDelegate *)instance;

@end
