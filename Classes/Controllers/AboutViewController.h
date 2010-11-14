//
//  AboutViewController.h
//  Facemash
//
//  Created by Peter Shih on 11/13/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AboutViewController : UIViewController <UITableViewDelegate, UITableViewDataSource> {
  IBOutlet UINavigationItem *_navBarItem;
  IBOutlet UITableView *_tableView;
}

@end
