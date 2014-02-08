//
//  RMUOtherProfileScreen.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 1/16/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RMUButton.h"
#import "GAITrackedViewController.h"
#import <FacebookSDK/FacebookSDK.h>

@interface RMUOtherProfileScreen : GAITrackedViewController

- (void)hideFoodieElements;
- (void)showFoodieElements;

@property BOOL isFoodie;
@property NSString *RMUUsername;
@property NSString *facebookID;
@property NSString *nameOfOtherUser;

@end
