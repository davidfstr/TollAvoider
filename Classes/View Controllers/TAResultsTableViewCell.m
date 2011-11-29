//
//  TAResultsTableViewCell.m
//  TollAvoider
//
//  Created by David Foster on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TAResultsTableViewCell.h"
#import "TADirectionsRequest.h"
#import "TADirectionsRoute.h"


@interface TAResultsTableViewCell()
- (void)initializeWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier
                         request:(TADirectionsRequest *)theRequest;
@end


@implementation TAResultsTableViewCell

@synthesize identifier;
@synthesize request;
@synthesize spinner;
@synthesize iconView;
@synthesize label1;
@synthesize label2;
@synthesize label3;

#pragma mark - Init

+ (TAResultsTableViewCell *)cellWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier
                                       request:(TADirectionsRequest *)theRequest
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TAResultsTableViewCell" owner:self options:nil];
    
    TAResultsTableViewCell *cell = (TAResultsTableViewCell *)[nib objectAtIndex:0];
    [cell initializeWithIdentifier:theIdentifier request:theRequest];
    return cell;
}

- (void)initializeWithIdentifier:(TAResultsViewItemIdentifier)theIdentifier
                         request:(TADirectionsRequest *)theRequest
{
    self.identifier = theIdentifier;
    self.request = theRequest;
    
    [self update];
    // TODO: Need to initialize icon
}

- (void)dealloc {
    [request release];
    [spinner release];
    [iconView release];
    [label1 release];
    [label2 release];
    [label3 release];
    [super dealloc];
}

#pragma mark - Operations

- (void)update {
    // TODO: For the direct cell, need to get the first non-520/non-90 route, if there is one.
    //       If there is not one, this cell shouldn't even be displaying...
    TADirectionsRoute *route = [request.routes objectAtIndex:0];
    
    switch (request.status) {
        case TADirectionsNotRequested:
        case TADirectionsRequesting: {
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
            break;
        }
        
        case TADirectionsError: {
            spinner.hidden = YES;
            iconView.hidden = NO;
            label1.text = @"";
            label2.text = @"Error while searching for route...";
            label3.text = @"";
            break;
        }
            
        case TADirectionsZeroResults: {
            spinner.hidden = YES;
            iconView.hidden = NO;
            label1.text = @"";
            label2.text = @"No routes found.";
            label3.text = @"";
            break;
        }
        
        case TADirectionsOK: {
            spinner.hidden = YES;
            iconView.hidden = NO;
            label1.text = route.title;
            label2.text = [NSString stringWithFormat:@"%@, %@", route.durationText, route.distanceText];
            // TODO: Need to compute this for the 520 route, since it isn't always free
            label3.text = @"FREE";
            break;
        }
    }
}

@end
