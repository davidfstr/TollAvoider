//
//  TAResultsViewController.m
//  TollAvoider
//
//  Created by David Foster on 11/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "TAResultsViewController.h"
#import "TAResultsTableViewCell.h"

@implementation TAResultsViewController

#pragma mark - Init

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        wa520Cell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifier520] retain];
        i90Cell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifier90] retain];
        directCell = [[TAResultsTableViewCell cellWithIdentifier:TAResultsViewItemIdentifierDirect] retain];
    }
    return self;
}

- (void)dealloc {
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

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)theTableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Free";
        case 1: return @"Tolled";
        default: return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2;
        case 1: return 1;
        default: return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            switch (indexPath.row) {
                case 0: return i90Cell;
                case 1: return directCell;
                default: return nil;
            }
        case 1:
            switch (indexPath.row) {
                case 0: return wa520Cell;
                default: return nil;
            }
        default:
            return nil;
    }
}

@end
