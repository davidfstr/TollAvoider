//
//  TAResultsTableViewCell.m
//  TollAvoider
//
//  Created by David Foster on 11/22/11.
//  Copyright (c) 2011 Seabalt Solutions, LLC. All rights reserved.
//

#import "TAResultsTableViewCell.h"
#import "TADirectionsRequest.h"
#import "TADirectionsRoute.h"
#import "TATollCalculator.h"


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

#pragma mark - Properties

- (TADirectionsRoute *)route {
    if (self.identifier == TAResultsViewItemIdentifierDirect) {
        return request.firstNonbridgeRoute;
    } else {
        return [request.routes objectAtIndex:0];
    }
}

#pragma mark - Operations

- (void)update {
    TADirectionsRequestStatus status = (request != nil)
        ? request.status
        : TADirectionsError;
    
    switch (status) {
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
            label2.text = @"Error finding route.";
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
            TADirectionsRoute *route = [self route];
            
            NSString *costString = @"FREE";
            if (self.identifier == TAResultsViewItemIdentifier520) {
                CGFloat *rateDescriptor = [TATollCalculator rateForNow];
                CGFloat passPrice = rateDescriptor[1];
                CGFloat noPassPrice = rateDescriptor[2];
                if (passPrice != 0 || noPassPrice != 0) {
                    costString = [NSString stringWithFormat:@"$%.02f (Pass), $%.02f (No Pass)",
                                  passPrice, noPassPrice];
                }
            }
            
            spinner.hidden = YES;
            iconView.hidden = NO;
            label1.text = route.title;
            label2.text = [NSString stringWithFormat:@"%@, %@", route.durationText, route.distanceText];
            label3.text = costString;
            break;
        }
    }
    
    if (request.status == TADirectionsOK) {
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)tap {
    if (request.status == TADirectionsOK) {
        [request openInGoogleMaps];
    }
}

#pragma mark - Comparisons

- (NSComparisonResult)compare:(TAResultsTableViewCell *)other {
    BOOL selfOK = (self.request.status == TADirectionsOK);
    BOOL otherOK = (other.request.status == TADirectionsOK);
    
    // Push errors to the bottom. Otherwise shortest distance first.
    if (selfOK && otherOK) {
        return (self.route.distanceValue <= other.route.distanceValue)
            ? NSOrderedAscending
            : NSOrderedDescending;
    } else if (!selfOK && otherOK) {
        return NSOrderedDescending;
    } else if (selfOK && !otherOK) {
        return NSOrderedAscending;
    } else /*if (!selfOK && !otherOK)*/ {
        return NSOrderedSame;
    }
}

@end
