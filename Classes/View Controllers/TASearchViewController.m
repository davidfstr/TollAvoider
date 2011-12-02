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
#import <QuartzCore/QuartzCore.h>   // for layer.cornerRadius
#import "TASearchLocation.h"
#import "TAResultsViewController.h"


@interface TASearchViewController()
- (void)showErrorOverlay:(NSString *)message;
- (void)showLoadingOverlay:(NSString *)message;
- (void)hideOverlay;
@end


@implementation TASearchViewController

#define LOG_OVERLAY_STATE 0

#if LOG_OVERLAY_STATE
    #define OverlayLog(format, args...) NSLog(format, ## args)
#else
    #define OverlayLog(format, args...) /* nothing */
#endif

#pragma mark - Init

- (void)awakeFromNib {
    // Listen for state changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateStatus)
                                                 name:@"TALocationTrackingStatusDidChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateStatus)
                                                 name:@"TADestinationGeocoderStatusDidChange" object:nil];
}

- (void)dealloc {
    [searchBar release];
    [overlay release];
    [overlayMessageLabel release];
    [overlayLoadingSpinner release];
    [overlayErrorIcon release];
    [super dealloc];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // Round the corners
    overlay.layer.cornerRadius = 8;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [searchBar release];
    searchBar = nil;
    [overlay release];
    overlay = nil;
    [overlayMessageLabel release];
    overlayMessageLabel = nil;
    [overlayLoadingSpinner release];
    overlayLoadingSpinner = nil;
    [overlayErrorIcon release];
    overlayErrorIcon = nil;
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
    
    static BOOL geocoderStateWasAmbiguous = NO;
    BOOL geocoderStateIsAmbiguous = (geocodeStatus == TAGeocoderGeocodeAmbiguous);
    if (geocoderStateIsAmbiguous && (!geocoderStateWasAmbiguous)) {
        // Geocoder just entered the TAGeocoderGeocodeAmbiguous status
        
        // Display the possible search locations to the user
        UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Multiple Locations Found"
                                                         message:@"Please select a location."
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                               otherButtonTitles:nil]
                              autorelease];
        int locationIndex = 0;
        for (TASearchLocation *loc in [TADestinationGeocoder instance].searchLocations) {
            if (locationIndex == 4) {
                // HACK: Can only display first 4 locations without squishing message
                break;
            }
            [alert addButtonWithTitle:loc.address];
            locationIndex++;
        }
        [alert show];
    }
    geocoderStateWasAmbiguous = geocoderStateIsAmbiguous;
    
    static BOOL selfStateWasComplete = NO;
    BOOL selfStateIsComplete = (locationStatus == TALocationFound) && (geocodeStatus == TAGeocoderGeocodeComplete);
    if (selfStateIsComplete && (!selfStateWasComplete)) {
        // Self just entered the complete status
        
        // Push the Results view
        TAResultsViewController *resultsViewController =
            [[[TAResultsViewController alloc] initWithSource:[TALocationTracking instance].userLocation.coordinate
                                                 destination:[TADestinationGeocoder instance].searchLocationChosen.location]
             autorelease];
        [self.navigationController pushViewController:resultsViewController animated:YES];
    }
    selfStateWasComplete = selfStateIsComplete;
    
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
    if ((locationStatus == TALocationIsolating) && (geocodeStatus != TAGeocoderNotGeocoding)) {
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
    if (selfStateIsComplete) {
        [self hideOverlay];
        return;
    }
    
    // Working in Background
    [self hideOverlay];
    return;
}

- (void)showErrorOverlay:(NSString *)message {
    OverlayLog(@"*** %@", message);
    
    overlayErrorIcon.hidden = NO;
    overlayLoadingSpinner.hidden = YES;
    overlayMessageLabel.text = message;
    overlay.hidden = NO;
}

- (void)showLoadingOverlay:(NSString *)message {
    OverlayLog(@"--- %@", message);
    
    overlayErrorIcon.hidden = YES;
    overlayLoadingSpinner.hidden = NO;
    overlayMessageLabel.text = message;
    overlay.hidden = NO;
}

- (void)hideOverlay {
    OverlayLog(@"--- <hidden>");
    
    overlay.hidden = YES;
}

- (void)hideSearchInterface {
    // Relinquish focus from the search bar and hide the keyboard
    [searchBar resignFirstResponder];
}

#pragma mark - Events

- (IBAction)backgroundButtonTapped:(id)sender {
    [self hideSearchInterface];
}

- (IBAction)parkPlaceButtonTapped:(id)sender {
    NSString *ppAppStoreUrlString = @"http://itunes.apple.com/us/app/park-place/id366719922?mt=8";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:ppAppStoreUrlString]];
}

#pragma mark - UISearchBarDelegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)theSearchBar {
    [self hideSearchInterface];
    [[TADestinationGeocoder instance] startSearchWithQuery:searchBar.text];
}

#pragma mark - UIAlertViewDelegate Methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    TADestinationGeocoder *geocoder = [TADestinationGeocoder instance];
    
    TASearchLocation *tappedLocation;
    if (buttonIndex == alertView.cancelButtonIndex) {
        tappedLocation = nil;
    } else {
        tappedLocation = [geocoder.searchLocations objectAtIndex:buttonIndex-1];
    }
    [geocoder continueSearchWithResolvedLocation:tappedLocation];
}

@end
