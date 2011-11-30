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
    
    // Initialize icon
    switch (theIdentifier) {
        case TAResultsViewItemIdentifierDirect:
            self.iconView.image = [UIImage imageNamed:@"Direct.png"];
            break;
        case TAResultsViewItemIdentifier520:
            self.iconView.image = [UIImage imageNamed:@"WA-520.png"];
            break;
        case TAResultsViewItemIdentifier90:
            self.iconView.image = [UIImage imageNamed:@"I-90.png"];
            break;
        case TAResultsViewItemIdentifierError:
            self.iconView.image = [UIImage imageNamed:@"184-warning.png"];
            break;
    }
    
    // Initialize rest of the view
    [self update];
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
    TADirectionsRoute *route;
    if (self.identifier == TAResultsViewItemIdentifierDirect) {
        route = request.firstNonbridgeRoute;
    } else {
        route = [request.routes objectAtIndex:0];
    }
    
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
            label2.text = @"Error finding route...";
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
    
    // TODO: Remove
    /*
    if (route.intersects520) {
        label3.text = @"Intersects WA-520";
    }
    if (route.intersects90) {
        label3.text = @"Intersects I-90";
    }
     */
}

@end
