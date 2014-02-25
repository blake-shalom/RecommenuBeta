//
//  RMUViewController.m
//  Recommenu
//
//  Created by Blake Ellingham on 2/25/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import "RMUUserTermsScreen.h"

@interface RMUUserTermsScreen ()

@end

@implementation RMUUserTermsScreen

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)popBackToSettings:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
