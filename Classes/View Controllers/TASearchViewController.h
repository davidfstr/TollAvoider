//
//  TASearchViewController.h
//  TollAvoider
//
//  Created by David Foster on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TASearchViewController : UIViewController <UISearchBarDelegate> {
    IBOutlet UISearchBar *searchBar;
    
    IBOutlet UIView *overlay;
    IBOutlet UILabel *overlayMessageLabel;
    IBOutlet UIActivityIndicatorView *overlayLoadingSpinner;
    IBOutlet UIImageView *overlayErrorIcon;
}

- (IBAction)backgroundButtonTapped:(id)sender;
- (IBAction)parkPlaceButtonTapped:(id)sender;

@end
