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


@interface TAResultsViewController()
@property (nonatomic, readwrite, retain) NSArray *sectionNames;
@property (nonatomic, readwrite, retain) NSArray *sections;
- (void)updateTable;
@end


@implementation TAResultsViewController

#pragma mark - Init

static NSString *WA520_WAYPOINT_NAME = @"WA-520 Bridge, Seattle, WA";
//static CLLocationCoordinate2D WA520_WAYPOINT = (CLLocationCoordinate2D) { 47.640, -122.256 };
static CLLocationCoordinate2D I90_WAYPOINT = (CLLocationCoordinate2D) { 47.590, -122.266 };

@synthesize sectionNames;
@synthesize sections;

- (id)initWithSource:(CLLocationCoordinate2D)source
         destination:(CLLocationCoordinate2D)destination
{
    self = [super initWithNibName:@"TAResultsViewController" bundle:nil];
    if (self) {
        directRequest = [[TADirectionsRequest alloc] initWithSource:source
                                                        destination:destination];
        wa520Request = [[TADirectionsRequest alloc] initWithSource:source
                                                      waypointName:WA520_WAYPOINT_NAME
                                                       destination:destination];
        // TODO: This gives a bizarre result when: Seattle, WA -> Redmond, WA.
        //       Name-based waypoints (ex: "I-90 Bridge, Seattle, WA") have no reasonable effect.
        //       Most likely need to search both the east and west lanes.
        //       Consider updating the WA-520 search logic to use similar logic, since it is less brittle.
        i90Request = [[TADirectionsRequest alloc] initWithSource:source
                                                        waypoint:I90_WAYPOINT
                                                     destination:destination];
        
        directCell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifierDirect request:directRequest] retain];
        wa520Cell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifier520 request:wa520Request] retain];
        i90Cell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifier90 request:i90Request] retain];
        errorCell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifierError request:nil] retain];
        
        [self updateTable];
        
        // Start requesting directions
        {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(updateTable)
                                                         name:@"TADirectionsRequestStatusDidChange" object:nil];
            
            [directRequest startAsynchronous];
            [wa520Request startAsynchronous];
            [i90Request startAsynchronous];
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
    [i90Request release];
    [tableView release];
    [super dealloc];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure navigation item
    self.navigationItem.title = @"Results";
    
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
        case TADirectionsOK:
            // TODO: Use alternate view if no 520 toll presently
            displayingError = NO;
            self.sectionNames = [NSArray arrayWithObjects:@"Free", @"Tolled", nil];
            NSMutableArray *section1 = [NSMutableArray arrayWithObjects:i90Cell, directCell, nil];
            NSMutableArray *section2 = [NSMutableArray arrayWithObjects:wa520Cell, nil];
            self.sections = [NSArray arrayWithObjects:section1, section2, nil];
            break;
            
        case TADirectionsError:
        case TADirectionsZeroResults:
            displayingError = YES;
            self.sectionNames = [NSArray arrayWithObjects:@"", nil];
            self.sections = [NSArray arrayWithObjects:errorCell, nil];
            
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
            
            // Update all cells
            for (NSArray *section in self.sections) {
                for (TAResultsTableViewCell *cell in section) {
                    [cell update];
                }
            }
            
            // TODO: Sort cells by status and distance
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

@end
