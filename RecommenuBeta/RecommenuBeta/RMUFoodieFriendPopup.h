//
//  RMUFoodieFriendPopup.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 2/13/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//
//  Nested view inside a view that contains a tableview and other elements for viewing specifics on recommendations

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "RMUDonutGraph.h"
#import "RMUProfileFriendCell.h"

@class RMUFoodieFriendPopup;

@protocol RMUFoodieFriendPopupDelegate

- (void)presentFriendSegueWithRMUUsername:(NSString*)username withName:(NSString*)name withFacebookID:(NSString*)fbID;
- (void)presentFoodieSegueWithRMUUsername:(NSString*)username withName:(NSString*)name withFacebookID:(NSString*)fbID withRecommenuID: (NSString*)rmuID;

@end


@interface RMUFoodieFriendPopup : UIView
<UITableViewDataSource, UITableViewDelegate>

@property (weak,nonatomic) IBOutlet UILabel* headLabel;
@property (weak,nonatomic) IBOutlet UILabel* likeLabel;
@property (weak,nonatomic) IBOutlet UILabel* dislikeLabel;
@property (weak,nonatomic) IBOutlet RMUDonutGraph* donutGraph;
@property (weak,nonatomic) IBOutlet UITableView* friendfoodTable;

@property (nonatomic,weak) id <RMUFoodieFriendPopupDelegate> delegate; 

// Populate methods for the popup

- (void)populateWithCrowdLikes:(NSInteger) likes withCrowdDislikes:(NSInteger)dislikes withNameOfEntree:(NSString*)entreeName;
- (void)populatePopupWithLikeArray:(NSArray*)likeArray withDislikeArray: (NSArray*)dislikeArray withNameofEntree:(NSString*)entreeName areFoodieRecommendations:(BOOL)isFoodie;

// Enum that tells state

typedef enum  {
    popupStateFoodieState,
    popupStateFriendState,
    popupStateCrowdState
} popupState;


@end
