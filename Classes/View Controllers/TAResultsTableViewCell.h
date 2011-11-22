//
//  TAResultsTableViewCell.h
//  TollAvoider
//
//  Created by David Foster on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
    TAResultsViewItemIdentifier520,
    TAResultsViewItemIdentifier90,
    TAResultsViewItemIdentifierDirect,
} TAResultsViewItemIdentifier;


// TODO: Use or delete
typedef enum {
    TAResultsViewItemStateLoading,
    TAResultsViewItemStateError,
    TAResultsViewItemStateResult,
} TAResultsViewItemState;


@interface TAResultsTableViewCell : UITableViewCell {
    TAResultsViewItemIdentifier identifier;
    
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UIImageView *iconView;
    IBOutlet UILabel *label1;
    IBOutlet UILabel *label2;
    IBOutlet UILabel *label3;
}

+ (TAResultsTableViewCell *)cellWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier;

@end
