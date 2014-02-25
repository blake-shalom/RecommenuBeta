//
//  RMUOtherProfileScreen.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 1/16/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import <UIKit/UIKit.h>

#import "RMUButton.h"
#import "GAITrackedViewController.h"
#import "RMUSavedUser.h"
#import "RMUAppDelegate.h"
#import "AFNetworking.h"
#import "RMUProfileRatingCell.h"
#import "RMUBlogViewController.h"

@interface RMUOtherProfileScreen : GAITrackedViewController
<UITableViewDataSource, UITableViewDelegate>

- (void)hideFoodieElements;
- (void)showFoodieElements;

@property BOOL isFoodie;
@property NSString *RMUUserID;
@property NSString *RMUUsername;
@property NSString *facebookID;
@property NSString *nameOfOtherUser;

@end
