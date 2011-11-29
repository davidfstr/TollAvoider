//
//  TAResultsViewController.h
//  TollAvoider
//
//  Created by David Foster on 11/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TAResultsTableViewCell;

@interface TAResultsViewController : UIViewController {
    TAResultsTableViewCell *wa520Cell;
    TAResultsTableViewCell *i90Cell;
    TAResultsTableViewCell *directCell;
    
    IBOutlet UITableView *tableView;
}

- (id)initWithSource:(CLLocationCoordinate2D)source
         destination:(CLLocationCoordinate2D)destination;

@end
