//
//  RMUSearchScreen.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFNetworking.h"
#import "RMUSearchCell.h"
#import "RMURevealViewController.h"
#import "GAITrackedViewController.h"
#import "RMUSavedUser.h"

@interface RMUSearchScreen : GAITrackedViewController
<UISearchBarDelegate, CLLocationManagerDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@end
