//
//  RMUButton.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/7/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUButton.h"
#import <QuartzCore/QuartzCore.h>

@implementation RMUButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
 *  laysout the subview and sets the corner radius to 3
 */

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.layer.cornerRadius = 3.0f;
//    self.layer.borderWidth = 0.5;
//    self.layer.borderColor = [UIColor blackColor].CGColor;

}

/*
 *  Sets highlighted color
 */

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted){
        if (self.isBlue)
            [self setBackgroundColor:[UIColor RMUBluePressedColor]];
        else
            [self setBackgroundColor:[UIColor RMUGrayPressedColor]];
    }
    else{
        if (self.isBlue)
            [self setBackgroundColor:[UIColor RMULogoBlueColor]];
        else
            [self setBackgroundColor:[UIColor whiteColor]];
    }
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.



@end
