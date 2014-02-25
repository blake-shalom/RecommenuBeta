//
//  RMUProfileScreen.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMUAppDelegate.h"
#import "RMUSavedRecommendation.h"
#import "RMUProfileRatingCell.h"
#import "RMURevealViewController.h"
#import "RMUOtherProfileScreen.h"
#import "GAITrackedViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "RMUSavedUserPhoto.h"
#import "RMUProfileFriendCell.h"

@interface RMUProfileScreen : GAITrackedViewController
<UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

- (void)fetchFriendsOfUser:(RMUSavedUser*)user;

@end
