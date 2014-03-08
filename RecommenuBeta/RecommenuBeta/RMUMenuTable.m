//
//  RMUMenuTable.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/24/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUMenuTable.h"

@implementation RMUMenuTable

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        [self setBackgroundColor:[UIColor whiteColor]];
        [self.layer setCornerRadius:3.0f];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.8];
        [self.layer setShadowRadius:5.0];
        [self.layer setShadowOffset:CGSizeMake(1.0, 1.0)];
//        self.layer.borderColor = [UIColor blackColor].CGColor;
//        self.layer.borderWidth = 0.5f;
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
