//
//  TAResultsTableViewCell.h
//  TollAvoider
//
//  Created by David Foster on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    TAResultsViewItemIdentifierDirect,
    TAResultsViewItemIdentifier520,
    TAResultsViewItemIdentifier90,
    TAResultsViewItemIdentifierError,
} TAResultsViewItemIdentifier;


@class TADirectionsRequest;

@interface TAResultsTableViewCell : UITableViewCell {
    // nothing
}

@property (nonatomic) TAResultsViewItemIdentifier identifier;
@property (nonatomic, retain) TADirectionsRequest *request;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UIImageView *iconView;
@property (nonatomic, retain) IBOutlet UILabel *label1;
@property (nonatomic, retain) IBOutlet UILabel *label2;
@property (nonatomic, retain) IBOutlet UILabel *label3;


+ (TAResultsTableViewCell *)cellWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier
                                       request:(TADirectionsRequest *)theRequest;

- (void)update;

@end
