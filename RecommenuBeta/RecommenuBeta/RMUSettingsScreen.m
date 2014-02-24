//
//  RMUSettingsScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUSettingsScreen.h"

@interface RMUSettingsScreen ()

@property (weak, nonatomic) IBOutlet UITableView *settingsTable;
@property (weak, nonatomic) IBOutlet UILabel *foodieLoginLabel;
@property (weak, nonatomic) IBOutlet RMUButton *foodieSignInButton;
@property (weak, nonatomic) IBOutlet UIImageView *foodieOnImage;
@property (weak, nonatomic) IBOutlet UIView *overlaySignInView;
@property (weak, nonatomic) IBOutlet RMUButton *confirmSignInButton;
@property (weak, nonatomic) IBOutlet UITextField *enterCodeTextField;
@property (weak, nonatomic) IBOutlet UIImageView *gradientImage;
@property (weak, nonatomic) IBOutlet UIButton *dismissKeyButton;

@end

@implementation RMUSettingsScreen

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
    self.foodieSignInButton.isBlue = YES;
    self.confirmSignInButton.isBlue = YES;
    self.enterCodeTextField.delegate = self;
    
    
    // Show correct Foodie UI
    RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
    RMUSavedUser *user = [delegate fetchCurrentUser];
    if (user.isFoodie)
        [self showFoodieActive];
    else
        [self showFoodieSignIn];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.screenName = @"Settings Screen";
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Utility functions

/*
 *  Shows Active UI for foodie
 */

- (void)showFoodieActive
{
    [self.foodieSignInButton setHidden:YES];
    [self.foodieOnImage setHidden:NO];
    [self.foodieLoginLabel setText:@"Signed in as a Tastemaker!"];
}

/*
 *  Shows sign in UI for foodie
 */

- (void)showFoodieSignIn
{
    [self.foodieSignInButton setHidden:NO];
    [self.foodieOnImage setHidden:YES];
    [self.foodieLoginLabel setText:@"Are you a Tastemaker?"];
}

#pragma mark - TableView Datasource methods

/*
 *  Cell for row, pretty lazy and non-adaptive
 */

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
//        case 0:
//            return [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
//            break;
            
        default:
            return [[UITableViewCell alloc]init];
            break;
    }
}

/*
 *  Number of cells in section, again not very adaptive
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

#pragma mark - Interactivity

/*
 *  Drops popup to prompt foodie to connect
 */

- (IBAction)connectFoodie:(id)sender
{
    //Animate in gradient + popup
    [self animateInGradient];
}

/*
 *  After popup sign in a foodie with the entered code
 */

- (IBAction)signInFoodie:(id)sender
{
    RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    RMUSavedUser *user = [delegate fetchCurrentUser];
    [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/data/foodies/%@/%@"),user.userName, self.enterCodeTextField.text]
                                 parameters:nil
                                    success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                        NSLog(@"RESPONSE: %@", responseObject);
                                        NSString *response = [responseObject objectForKey:@"status"];
                                        if ([response isEqualToString:@"wrong password"])
                                            [delegate showMessage:@"Please Try Again" withTitle:@"Wrong Password"];
                                        else if ([response isEqualToString:@"success"]) {
                                            user.isFoodie = [NSNumber numberWithBool:YES];
                                            [self dismissFoodieSignin:self];
                                            [delegate showMessage:@"Thank you for signing up for being a recognized Recommenu Foodie!" withTitle:@"Foodie Status Achieved!"];
                                            [self showFoodieActive];
                                            NSError *saveError;
                                            if (![delegate.managedObjectContext save:&saveError])
                                                NSLog(@"Error Saving %@", saveError);

                                        }
                                    }
                                    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                        NSLog(@"RESPONSE STRING: %@", operation.responseString);
                                        NSLog(@"ERROR: %@", error);
                                        RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
                                        [delegate showMessage:@"Please try again later!" withTitle:@"Error signing up foodie!"];
                                    }];

}

/*
 *  Dismisses the foodie popup from the small X on the card
 */

- (IBAction)dismissFoodieSignin:(id)sender
{
    [self.overlaySignInView setHidden:YES];
    [self animateOutGradient];
}

/*
 *  Dismiss the keyboard if back button is clicked
 */

- (IBAction)dismissKeyboard:(id)sender
{
    [self.enterCodeTextField resignFirstResponder];
}

#pragma mark - Animation Methods

/*
 *  Animates in the gradient and then calls animate popup
 */

- (void)animateInGradient
{
    [self.gradientImage setAlpha:0.0f];
    [self.gradientImage setHidden:NO];
    [UIView animateWithDuration:0.3f
                          delay:0.5f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.gradientImage setAlpha:1.0f];
                     } completion:^(BOOL finished) {
                         [self animatePopup];
                     }];
}

/*
 *  Dismisses the gradient and return to "normal" mode
 */

- (void)animateOutGradient
{
    [self.gradientImage setAlpha:1.0f];
    [self.gradientImage setHidden:NO];
    [UIView animateWithDuration:0.3f
                          delay:0.2f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.gradientImage setAlpha:0.0f];
                     } completion:^(BOOL finished) {
                         
                     }];
}

/*
 *  Animates in the popup to the right location
 */

- (void)animatePopup
{
    [self.overlaySignInView setHidden:NO];
    [RMUAnimationClass animateFlyInView:self.overlaySignInView
                           withDuration:0.1f
                              withDelay:0.0f
                          fromDirection:buttonAnimationDirectionTop
                         withCompletion:Nil
                             withBounce:YES];
}

#pragma mark - UITextView Delegate

/*
 *  Began editing, bring button to the front
 */

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.view bringSubviewToFront:self.dismissKeyButton];
}

/*
 *  Ended editing send button backwards
 */

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.view sendSubviewToBack:self.dismissKeyButton];
}


@end
