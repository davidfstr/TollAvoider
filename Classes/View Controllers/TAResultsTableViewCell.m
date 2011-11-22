//
//  TAResultsTableViewCell.m
//  TollAvoider
//
//  Created by David Foster on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TAResultsTableViewCell.h"


@interface TAResultsTableViewCell()
- (void)initializeWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier;
@end


@implementation TAResultsTableViewCell

#pragma mark - Init

+ (TAResultsTableViewCell *)cellWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier {
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TAResultsTableViewCell" owner:self options:nil];
    
    TAResultsTableViewCell *cell = (TAResultsTableViewCell *)[nib objectAtIndex:0];
    [cell initializeWithIdentifier:theIdentifier];
    return cell;
}

- (void)initializeWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier {
    identifier = theIdentifier;
    
    NSString *routeName;
    switch (identifier) {
        case TAResultsViewItemIdentifier520:
            routeName = @"WA-520";
            break;
        case TAResultsViewItemIdentifier90:
            routeName = @"I-90";
            break;
        case TAResultsViewItemIdentifierDirect:
            routeName = @"surface";
            break;
        default:
            routeName = @"<unknown>";
            break;
    }
    
    spinner.hidden = NO;
    iconView.hidden = YES;
    label1.text = @"";
    label2.text = [NSString stringWithFormat:@"Finding %@ route...", routeName];
    label3.text = @"";
}

- (void)dealloc {
    [spinner release];
    [iconView release];
    [label1 release];
    [label2 release];
    [label3 release];
    [super dealloc];
}

@end
