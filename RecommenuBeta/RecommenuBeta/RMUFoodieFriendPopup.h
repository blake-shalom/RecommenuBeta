//
//  RMUFoodieFriendPopup.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 2/13/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "RMUDonutGraph.h"
#import "RMUProfileFriendCell.h"

@interface RMUFoodieFriendPopup : UIView
<UITableViewDataSource, UITableViewDelegate>

@property (weak,nonatomic) IBOutlet UILabel* headLabel;
@property (weak,nonatomic) IBOutlet UILabel* likeLabel;
@property (weak,nonatomic) IBOutlet UILabel* dislikeLabel;
@property (weak,nonatomic) IBOutlet RMUDonutGraph* donutGraph;
@property (weak,nonatomic) IBOutlet UITableView* friendfoodTable;

- (void)populateWithCrowdLikes:(NSInteger) likes withCrowdDislikes:(NSInteger)dislikes withNameOfEntree:(NSString*)entreeName;
- (void)populateWithFriendsLikeArray:(NSArray*)likeArray withFriendsDislikeArray: (NSArray*)dislikeArray withNameofEntree:(NSString*)entreeName;

typedef enum  {
    popupStateFoodieState,
    popupStateFriendState,
    popupStateCrowdState
} popupState;


@end
