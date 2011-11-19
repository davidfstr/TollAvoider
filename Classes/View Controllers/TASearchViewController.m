//
//  TASearchViewController.m
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TASearchViewController.h"
#import "TALocationTracking.h"
#import "TALocationTrackingStatus.h"
#import "TADestinationGeocoder.h"
#import "TADestinationGeocoderStatus.h"


@interface TASearchViewController()
- (void)showErrorOverlay:(NSString *)message;
- (void)showLoadingOverlay:(NSString *)message;
- (void)hideOverlay;
@end


@implementation TASearchViewController

#pragma mark - Init

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateStatus)
                                                 name:@"TALocationTrackingStatusDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateStatus)
                                                 name:@"TADestinationGeocoderStatusDidChange" object:nil];
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // TODO: Hook search bar up to perform searches
    [[TADestinationGeocoder instance] startSearchWithQuery:@"Seattle, WA"];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Operations

- (void)updateStatus {
    TALocationTrackingStatus locationStatus = [TALocationTracking instance].status;
    TADestinationGeocoderStatus geocodeStatus = [TADestinationGeocoder instance].status;
    
    // TODO: Need to take action when geocoder enters the TAGeocoderGeocodeAmbiguous from some other state:
    //          Display alert with choices.
    //          If choice selected, goes to TAGeocoderGeocodeComplete.
    //          Otherwise if cancel, goes to TAGeocoderNotGeocoding.
    
    // TODO: Need to take action when self enters the Complete state from some other state:
    //          Push the Results view controller.
    
    // Location errors
    if (locationStatus == TALocationErrorDenied) {
        [self showErrorOverlay:@"Please enable Location Services for Toll Avoider in Settings."];
        return;
    }
    if (locationStatus == TALocationErrorOther) {
        [self showErrorOverlay:@"Unable to determine your location."];
        return;
    }
    
    // Search errors
    if (geocodeStatus == TAGeocoderGeocodeNoMatch) {
        [self showErrorOverlay:@"Address not found."];
        return;
    }
    if (geocodeStatus == TAGeocoderGeocodeFailed) {
        [self showErrorOverlay:@"Error while resolving address.\nCheck your internet connection."];
        return;
    }
    
    // Searching...
    BOOL geocoderIdle =
        (geocodeStatus == TAGeocoderNotGeocoding) || 
        (geocodeStatus == TAGeocoderGeocodeComplete);
    if ((locationStatus == TALocationIsolating) && (!geocoderIdle)) {
        [self showLoadingOverlay:@"Searching for your current location..."];
        return;
    }
    if ((geocodeStatus == TAGeocoderGeocoding) ||
        (geocodeStatus == TAGeocoderGeocodeAmbiguous))
    {
        [self showLoadingOverlay:@"Searching for address..."];
        return;
    }
    
    // Complete
    if ((locationStatus == TALocationFound) && (geocodeStatus == TAGeocoderGeocodeComplete)) {
        [self hideOverlay];
        return;
    }
    
    // Working in Background
    [self hideOverlay];
    return;
}

- (void)showErrorOverlay:(NSString *)message {
    NSLog(@"*** %@", message); // TODO: Display in UI
}

- (void)showLoadingOverlay:(NSString *)message {
    NSLog(@"--- %@", message); // TODO: Display in UI
}

- (void)hideOverlay {
    NSLog(@"--- <hidden>");    // TODO: Display in UI
}

#pragma mark - Events

- (IBAction)parkPlaceButtonTapped:(id)sender {
    NSString *ppAppStoreUrlString = @"http://itunes.apple.com/us/app/park-place/id366719922?mt=8";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ppAppStoreUrlString]];
}

@end
