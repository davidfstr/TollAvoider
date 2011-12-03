//
//  TAResultsViewController.m
//  TollAvoider
//
//  Created by David Foster on 11/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TAResultsViewController.h"
#import "TAResultsTableViewCell.h"
#import "TADirectionsRequest.h"
#import "TADirectionsRoute.h"
#import "TATollCalculator.h"


@interface TAResultsViewController()
@property (nonatomic, readwrite, retain) NSMutableArray *sectionNames;
@property (nonatomic, readwrite, retain) NSMutableArray *sections;
- (void)updateTable;
@end


@implementation TAResultsViewController

#pragma mark - Init

static NSString *WA520_WAYPOINT_NAME = @"WA-520 Bridge, Seattle, WA";
//static CLLocationCoordinate2D WA520E_WAYPOINT = (CLLocationCoordinate2D) { 47.636, -122.256 };
//static CLLocationCoordinate2D WA520W_WAYPOINT = (CLLocationCoordinate2D) { 47.640, -122.256 };

static CLLocationCoordinate2D I90E_WAYPOINT = (CLLocationCoordinate2D) { 47.588, -122.266 };
static CLLocationCoordinate2D I90W_WAYPOINT = (CLLocationCoordinate2D) { 47.590, -122.266 };

@synthesize sectionNames;
@synthesize sections;

- (id)initWithSource:(CLLocationCoordinate2D)source
         destination:(CLLocationCoordinate2D)destination
{
    self = [super initWithNibName:@"TAResultsViewController" bundle:nil];
    if (self) {
        directRequest = [[TADirectionsRequest alloc] initWithSource:source
                                                        destination:destination
                                                               type:@"Direct"];
        directRequest.alternatives = YES;
        // NOTE: If this name-based query breaks in the future, recommend rewriting
        //       to use similar logic as the I-90 coordinate-based queries.
        wa520Request = [[TADirectionsRequest alloc] initWithSource:source
                                                      waypointName:WA520_WAYPOINT_NAME
                                                       destination:destination
                                                              type:@"WA-520"];
        i90eRequest = [[TADirectionsRequest alloc] initWithSource:source
                                                         waypoint:I90E_WAYPOINT
                                                      destination:destination
                                                             type:@"I-90 E"];
        i90wRequest = [[TADirectionsRequest alloc] initWithSource:source
                                                         waypoint:I90W_WAYPOINT
                                                      destination:destination
                                                             type:@"I-90 W"];
        
        directCell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifierDirect request:directRequest] retain];
        wa520Cell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifier520 request:wa520Request] retain];
        // HACK: Initially associate with the I-90 E request.
        //       This association will be later revised to I-90 W if necessary.
        i90Cell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifier90 request:i90eRequest] retain];
        errorCell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifierError request:nil] retain];
        
        [self updateTable];
        
        // Start requesting directions
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updateTable)
                                                         name:@"TADirectionsRequestStatusDidChange" object:nil];
            
            [directRequest startAsynchronous];
            [wa520Request startAsynchronous];
            [i90eRequest startAsynchronous];
            [i90wRequest startAsynchronous];
        }
    }
    return self;
}

- (void)dealloc {
    [directCell release];
    [wa520Cell release];
    [i90Cell release];
    [directRequest release];
    [wa520Request release];
    [i90eRequest release];
    [i90wRequest release];
    [tableView release];
    [super dealloc];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure navigation item
    self.navigationItem.title = @"Results";
    
    // Make table transparent
    tableView.backgroundColor = [UIColor clearColor];
    
    // Configure row height
    TAResultsTableViewCell *anyCell = wa520Cell;
    [tableView setRowHeight:anyCell.frame.size.height];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [tableView release];
    tableView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Operations

- (void)updateTable {
    BOOL displayingError;
    switch (directRequest.status) {
        case TADirectionsNotRequested:
        case TADirectionsRequesting:
        case TADirectionsOK: {
            BOOL tollIsActive; {
                CGFloat *rateDescriptor = [TATollCalculator rateForNow];
                CGFloat passPrice = rateDescriptor[1];
                CGFloat noPassPrice = rateDescriptor[2];
                tollIsActive = (passPrice != 0 || noPassPrice != 0);
            }
            
            displayingError = NO;
            if (tollIsActive) {
                self.sectionNames = [NSMutableArray arrayWithObjects:@"Free", @"Tolled", nil];
                NSMutableArray *section1 = [NSMutableArray arrayWithObjects:i90Cell, directCell, nil];
                NSMutableArray *section2 = [NSMutableArray arrayWithObjects:wa520Cell, nil];
                self.sections = [NSMutableArray arrayWithObjects:section1, section2, nil];
            } else {
                self.sectionNames = [NSMutableArray arrayWithObjects:@"Free", nil];
                NSMutableArray *section1 = [NSMutableArray arrayWithObjects:wa520Cell, i90Cell, directCell, nil];
                self.sections = [NSMutableArray arrayWithObjects:section1, nil];
            }
            break;
        }
            
        case TADirectionsError:
        case TADirectionsZeroResults:
            displayingError = YES;
            self.sectionNames = [NSMutableArray arrayWithObjects:@"", nil];
            NSMutableArray *section1 = [NSMutableArray arrayWithObjects:errorCell, nil];
            self.sections = [NSMutableArray arrayWithObjects:section1, nil];
            break;
            
        default:
            NSLog(@"*** Unknown TADirectionsRequestStatus: %d", (int) directRequest.status);
            return;
    }
    
    if (displayingError) {
        if (directRequest.status == TADirectionsError) {
            errorCell.label2.text = @"Error while searching for routes.";
            errorCell.label3.text = @"Check your internet connection.";
        } else if (directRequest.status == TADirectionsZeroResults) {
            errorCell.label2.text = @"No routes found.";
            errorCell.label3.text = @"";
        }
    } else {
        if (directRequest.status == TADirectionsOK) {
            if (directRequest.firstNonbridgeRoute == nil) {
                // Remove direct cell
                for (NSMutableArray *section in self.sections) {
                    [section removeObject:directCell];
                }
            }
            
            // If direct route does not offer an alternative that crosses a bridge,
            // do not display any bridge routes
            BOOL anyDirectRouteCrossesBridge = NO;
            for (TADirectionsRoute *route in directRequest.routes) {
                if (route.intersects520 || route.intersects90) {
                    anyDirectRouteCrossesBridge = YES;
                    break;
                }
            }
            if (!anyDirectRouteCrossesBridge) {
                // Remove all bridge cells
                for (NSMutableArray *section in self.sections) {
                    [section removeObject:wa520Cell];
                    [section removeObject:i90Cell];
                }
                
                // Remove any resultant empty sections
                for (int i=0; i<sections.count; i++) {
                    NSMutableArray *section = [sections objectAtIndex:i];
                    if (section.count == 0) {
                        [sections removeObjectAtIndex:i];
                        [sectionNames removeObjectAtIndex:i];
                        i--; // Try again at same index
                    }
                }
            }
            
            // HACK: Update the I-90 cell to display the status of the I-90 request that either:
            //       (1) has an error (if any)
            //       (2) is still loading (if any)
            //       (3) has the shortest route (if both OK)
            if ((i90eRequest.status == TADirectionsError) || 
                (i90eRequest.status == TADirectionsZeroResults))
            {
                i90Cell.request = i90eRequest;
            } else if ((i90wRequest.status == TADirectionsError) || 
                       (i90wRequest.status == TADirectionsZeroResults))
            {
                i90Cell.request = i90wRequest;
            } else if (i90eRequest.status == TADirectionsRequesting) {
                i90Cell.request = i90eRequest;
            } else if (i90wRequest.status == TADirectionsRequesting) {
                i90Cell.request = i90wRequest;
            } else if ((i90eRequest.status == TADirectionsOK) && 
                       (i90wRequest.status == TADirectionsOK))
            {
                TADirectionsRoute *i90eRoute = [i90eRequest.routes objectAtIndex:0];
                TADirectionsRoute *i90wRoute = [i90wRequest.routes objectAtIndex:0];
                
                if (i90eRoute.distanceValue <= i90wRoute.distanceValue) {
                    i90Cell.request = i90eRequest;
                } else {
                    i90Cell.request = i90wRequest;
                }
            }
            
            // Update all cells to match the state of their associated request
            for (NSArray *section in self.sections) {
                for (TAResultsTableViewCell *cell in section) {
                    [cell update];
                }
            }
            
            // Sort cells by status and distance
            for (NSMutableArray *section in self.sections) {
                NSArray *sortedSection = [section sortedArrayUsingSelector:@selector(compare:)];
                [section removeAllObjects];
                [section addObjectsFromArray:sortedSection];
            }
        } else {
            // Keep all the rows in the loading state
        }
    }
    
    [tableView reloadData];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)sectionIndex {
    return [self.sectionNames objectAtIndex:sectionIndex];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex {
    NSArray *section = [self.sections objectAtIndex:sectionIndex];
    return section.count;
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *section = [self.sections objectAtIndex:indexPath.section];
    TAResultsTableViewCell *cell = [section objectAtIndex:indexPath.row];
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *section = [self.sections objectAtIndex:indexPath.section];
    TAResultsTableViewCell *cell = [section objectAtIndex:indexPath.row];
    [cell tap];
    
    [theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
