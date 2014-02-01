//
//  RMUSettingsScreen.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GAITrackedViewController.h"
#import "RMULocationCell.h"
#import "AFNetworking.h"
#import "RMUAppDelegate.h"
#import "RMUAnimationClass.h"


@interface RMUSettingsScreen : GAITrackedViewController
<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@end
