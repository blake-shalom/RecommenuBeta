//
//  RMUSideMenuScreen.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/27/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMURestaurant.h"
#import "SWRevealViewController.h"

@class RMUSideMenuScreen;

@protocol RMUSideMenuScreenDelegate

- (void)loadMenuScreenWithMenu: (RMUMenu*)menu;

@end

@interface RMUSideMenuScreen : UIViewController
<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic,weak)  id <RMUSideMenuScreenDelegate> delegate;

- (void)loadCurrentRestaurant: (RMURestaurant*)restaurant;

@end
