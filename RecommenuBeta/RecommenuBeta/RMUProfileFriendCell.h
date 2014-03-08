//
//  RMUProfileFriendCell.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 2/6/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMUProfileFriendCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *friendImage;
@property (weak, nonatomic) IBOutlet UILabel *friendNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numRatingsLabel;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@end
