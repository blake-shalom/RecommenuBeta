//
//  RMUSearchCell.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 1/18/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RMUSearchCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIImageView *typeBadge;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;

@end
