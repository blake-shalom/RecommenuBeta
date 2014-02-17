//
//  RMUMenuScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/18/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUMenuScreen.h"

@interface RMUMenuScreen ()

// Regular properties
@property (weak,nonatomic) RMURestaurant *currentRestaurant;
@property (weak,nonatomic) RMUMenu *currentMenu;
@property (weak,nonatomic) RMUCourse *currentCourse;
@property BOOL isMenuVisible;

// IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *restNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *currMenuLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftSectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *currSectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightSectionLabel;
@property (weak, nonatomic) IBOutlet iCarousel *carousel;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;
@property (weak, nonatomic) IBOutlet UIView *missingMenuView;
@property (weak, nonatomic) IBOutlet RMUButton *reportMenuButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadIndicator;
@property (weak, nonatomic) IBOutlet UIView *shroudView;
@property (weak, nonatomic) IBOutlet RMUFoodieFriendPopup *popup;
@property (weak, nonatomic) IBOutlet RMUFoodieFriendPopup *crowdPopup;

@end

@implementation RMUMenuScreen

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
    [self.restNameLabel setTextColor:[UIColor RMUTitleColor]];
    [self.currMenuLabel setTextColor:[UIColor RMUTitleColor]];
    [self.leftSectionLabel setTextColor:[UIColor RMUDividingGrayColor]];
    [self.rightSectionLabel setTextColor:[UIColor RMUDividingGrayColor]];
    [self.currSectionLabel setTextColor:[UIColor RMULogoBlueColor]];
    
    // Carousel Customization
    self.carousel.type = iCarouselTypeLinear;
    self.carousel.delegate = self;
    self.carousel.dataSource = self;
    self.carousel.decelerationRate = 0.4;
    self.carousel.clipsToBounds = YES;
    self.carousel.pagingEnabled = YES;
    
    // Reveal Controller customization
    [self.revealViewController panGestureRecognizer];
    [self.revealViewController tapGestureRecognizer];
    self.revealViewController.delegate = self;
    
    // Set up button UI
    [self.reportMenuButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.reportMenuButton setBackgroundColor:[UIColor RMULogoBlueColor]];
    self.reportMenuButton.isBlue = YES;
    [self.missingMenuView setHidden:YES];
    
    // Spin Load Indicator
    [self.loadIndicator startAnimating];
	// Do any additional setup after loading the view.
    [self.shroudView setHidden:YES];
    [self.popup setHidden:YES];
    [self.crowdPopup setHidden:YES];
}


- (void)viewDidAppear:(BOOL)animated
{
    // Google Analytics screen name
    self.screenName = @"Menu Screen";
    [super viewDidAppear:animated];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupViews
{
    [self.restNameLabel setText:[self.currentRestaurant.restName uppercaseString]];
    [self.currMenuLabel setText:self.currentMenu.menuName];
    [self.currSectionLabel setText:self.currentCourse.courseName];
    // If there are more than one course set the label to each of the two courses to the left and right
    if (self.currentMenu.courses.count > 1) {
        [self.leftSectionLabel setText:@""];
        RMUCourse *course = self.currentMenu.courses[1];
        [self.rightSectionLabel setText:course.courseName];
    }
    else {
        [self.leftSectionLabel setText:@""];
        [self.rightSectionLabel setText:@""];
    }
    if (self.currentRestaurant.menus.count < 1)
        [self.missingMenuView setHidden:NO];
    [self.carousel reloadData];
    
    // Menu visited, set notifications
    if (self.currentRestaurant.menus.count > 0){
        RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
        delegate.savedRestaurant = self.currentRestaurant;
        delegate.shouldDelegateNotifyUser = YES;
    }

}

- (void)setupMenuElementsWithRestaurant:(RMURestaurant*)restaurant
{
    self.currentRestaurant = restaurant;
    if (self.currentRestaurant.menus.count > 0) {
        self.currentMenu = self.currentRestaurant.menus[0];
        self.currentCourse = self.currentMenu.courses[0];
    }
}

- (void)loadMenu: (RMUMenu*)menu
{
    self.currentMenu = menu;
    self.currentCourse = self.currentMenu.courses[0];
    [self setupViews];
    [self.carousel scrollToItemAtIndex:0 animated:NO];
    [self.carousel reloadData];
}

#pragma mark - UIAlertView Delegate

/*
 *  Returns home to the main menu
 */

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self performSegueWithIdentifier:@"menuToHome" sender:self];
}

#pragma mark - interactivity

/*
 *  Pops up the friend popup
 */

-(void) viewFriendRecsForItem:(UIButton*)sender
{
    NSLog(@"YOU TAPPED FRIEND AT INDEX %i", sender.tag);
    [self animateInGradientBeforePopupView:self.popup];
    RMUMeal *selectedMeal = self.currentCourse.meals[sender.tag];
    [self.popup populateWithFriendsLikeArray:selectedMeal.facebookLikeID
                     withFriendsDislikeArray:selectedMeal.facebookDislikeID
                            withNameofEntree:selectedMeal.mealName];
}

/*
 *  Pops up the tastemaker popup
 */

-(void) viewFoodieRecsForItem:(UIButton*)sender
{
    NSLog(@"YOU TAPPED Foodie AT INDEX %i", sender.tag);
    [self animateInGradientBeforePopupView:self.popup];
}

/*
 *  Pops up the crowd popup
 */

-(void) viewCrowdRecsForItem:(UIButton*)sender
{
    NSLog(@"YOU TAPPED Crowd AT INDEX %i", sender.tag);
    [self animateInGradientBeforePopupView:self.crowdPopup];
    RMUMeal *selectedMeal = self.currentCourse.meals[sender.tag];
    [self.crowdPopup populateWithCrowdLikes:selectedMeal.crowdLikes.integerValue
                           withCrowdDislikes:selectedMeal.crowdDislikes.integerValue
                            withNameOfEntree:selectedMeal.mealName];
}

/*
 *  Reports the menu as invalid baddy bad bad
 */


- (IBAction)reportMenu:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Menu Reported!" message:@"Thanks for reporting this menu!" delegate:self cancelButtonTitle:@"Return Home" otherButtonTitles:nil];
    
    [alert show];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
    
    RMUSavedUser *user = [delegate fetchCurrentUser];
    [manager GET:@"http://glacial-ravine-3577.herokuapp.com/api/v1/missingmenu/schema/?format=json"
       parameters:@{@"foursquare_venue_id": self.currentRestaurant.restFoursquareID,
                    @"id" : user.userID,
                    @"resource_uri" : user.userURI}
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              NSLog(@"Success reporting, response %@", responseObject);
          }
          failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              NSLog(@"Failure reporting with error: %@, response string %@", error, operation.responseString);
          }];
}

/*
 *  Views other avalable menus at the restaurant
 */

- (IBAction)viewMenus:(id)sender
{
    [self.revealViewController performSelectorOnMainThread:@selector(revealToggle:) withObject:self waitUntilDone:NO];
}

/*
 *  Upon click, moves the section forward, unless at the last index
 */

- (IBAction)moveSectionBackward:(id)sender
{
    NSInteger index = self.carousel.currentItemIndex;
    if (index > 0){
        [self.carousel scrollToItemAtIndex:index - 1  animated:YES];
    }
}

/*
 *  Upon click moves the section backward, unless at first section index
 */


- (IBAction)moveSectionForward:(id)sender
{
    NSInteger index = self.carousel.currentItemIndex;
    if (index < self.currentMenu.courses.count -1){
        [self.carousel scrollToItemAtIndex:index + 1 animated:YES];
    }
}

- (IBAction)hideShroudView:(id)sender
{
    [self.popup setHidden:YES];
    [self.crowdPopup setHidden:YES];
    [self animateOutGradient];
}

#pragma mark - UITableViewDelagate

/*
 *  Returns appropriate height for individual rows, depending on description text
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger index = tableView.tag;
    RMUCourse *course = self.currentMenu.courses[index];
    RMUMeal *currentMeal = course.meals[indexPath.row];
    NSString *descText = currentMeal.mealDescription;
    CGSize maxSize = CGSizeMake(221.0f, CGFLOAT_MAX);
    UIFont *currentFont = [UIFont fontWithName:@"Avenir-Roman" size:10.0f];
    CGRect textRect = [descText boundingRectWithSize:maxSize
                                             options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                          attributes:@{NSFontAttributeName:currentFont}
                                             context:nil];
    return ceilf(textRect.size.height) + 70.0f;
}

/*
 *  Manages Selection of cells by checkbox
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

/*
 *  Deselection of cells by unchecking checkbox
 */

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

#pragma mark - UITableViewDataSource

/*
 *  Cell for row at index path, oh shizz
 */

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    NSInteger index = tableView.tag;
    RMUCourse *course = self.currentMenu.courses[index];
    [tableView registerNib:[UINib nibWithNibName:@"menuTableCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:CellIdentifier];
    RMUMenuCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[RMUMenuCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    RMUMeal *currentMeal = course.meals[indexPath.row];
    [cell.mealLabel setText:currentMeal.mealName];
    [cell.descriptionLabel setText:currentMeal.mealDescription];
    [cell.priceLabel setText:currentMeal.mealPrice];
    
    NSNumber *totalCrowd = [NSNumber numberWithInt:(currentMeal.crowdLikes.intValue + currentMeal.crowdDislikes.intValue)];
    NSNumber *totalFacebook = [NSNumber numberWithInt:(currentMeal.friendLikes.intValue + currentMeal.friendDislikes.intValue)];
    NSNumber *totalFoodie = [NSNumber numberWithInt:(currentMeal.expertDislikes.intValue + currentMeal.expertLikes.intValue)];

    [cell.crowdLikeLabel setText:[totalCrowd stringValue]];
    [cell.friendLikeLabel setText:[totalFacebook stringValue]];
    [cell.expertLikeLabel setText:[totalFoodie stringValue]];
    [cell.donutGraph displayLikes:[currentMeal.crowdLikes integerValue] dislikes:[currentMeal.crowdDislikes integerValue]];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Assign the Cell a tag for later uses
    
    // Configure the Cell's various buttons
    [cell.friendsButton addTarget:self
                           action:@selector(viewFriendRecsForItem:)
                 forControlEvents:UIControlEventTouchUpInside];
    cell.friendsButton.tag = indexPath.row;

    [cell.foodieButton addTarget:self
                           action:@selector(viewFoodieRecsForItem:)
                 forControlEvents:UIControlEventTouchUpInside];
    cell.foodieButton.tag = indexPath.row;

    [cell.crowdButton addTarget:self
                           action:@selector(viewCrowdRecsForItem:)
                 forControlEvents:UIControlEventTouchUpInside];
    cell.crowdButton.tag = indexPath.row;

    
    return cell;
}

/*
 *  Returns the number of rows in each section of the table
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger index = tableView.tag;
    RMUCourse *indexedCourse = self.currentMenu.courses[index];
    return indexedCourse.meals.count;
}

#pragma mark -  iCarousel Methods

/*
 *  Returns the number of views necessary in the carousel
 */

- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    return self.currentMenu.courses.count;
}

/*
 *  Returns the view for each carousel, similar to CellForRow
 */

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    if (view == nil) {
        // if the view is nil, create a new view
        CGRect oldFrame = self.carousel.frame;
        CGRect newFrame = CGRectMake(oldFrame.origin.x + 8, oldFrame.origin.y + 8, oldFrame.size.width - 16, oldFrame.size.height -16);
        RMUMenuTable *tableView = [[RMUMenuTable alloc] initWithFrame:newFrame];
        tableView.delegate = self;
        tableView.dataSource = self;
        view = tableView;
        // Tag is assigned at the bottom to give the initial views a tag
        view.tag = index;
    }
    else {
        // View was already created, just refresh the table. Tag is assigned at the beginning before table can reload data
        view.tag = index;
        RMUMenuTable *tableview = (RMUMenuTable*) view;
        [tableview reloadData];
    }
    return view;
}

/*
 *  If the carousel index changed, switch the label's text
 */

- (void)carouselCurrentItemIndexDidChange:(iCarousel *)carousel
{
    NSInteger index = carousel.currentItemView.tag;
    self.currentCourse = self.currentMenu.courses[index];
    RMUCourse *course = self.currentMenu.courses[index];
    [self.currSectionLabel setText:course.courseName];
    if (index > 0) {
        course = self.currentMenu.courses[index-1];
        [self.leftSectionLabel setText:course.courseName];
    }
    else
        [self.leftSectionLabel setText:@""];
    
    if (index < self.currentMenu.courses.count - 1) {
        course = self.currentMenu.courses[index+1];
        [self.rightSectionLabel setText:course.courseName];
    }
    else
        [self.rightSectionLabel setText:@""];
    
}

- (CGFloat)carousel:(iCarousel *)carousel valueForOption:(iCarouselOption)option withDefault:(CGFloat)value
{
    switch (option)
    {
        case iCarouselOptionSpacing:
        {
            return 1.2;
        }
        case iCarouselOptionVisibleItems:
        {
            return 3;
        }
        default:
        {
            return value;
        }
    }
}

#pragma mark - segue methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"menuToRating"]){
        RMURevealViewController  *ratingScreen = (RMURevealViewController*)segue.destinationViewController;
        ratingScreen.currentRestaurant = self.currentRestaurant;
    }
}

#pragma mark - SWReveal Delegate

/*
 *  Freezes controls on the main page when you navigate to the rear page
 */

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    if (position == 3) {
        [self.carousel setUserInteractionEnabled:YES];
        [self.menuButton setImage:[UIImage imageNamed:@"icon_list"] forState:UIControlStateNormal];
    }
    else if (position == 4) {
        [self.carousel setUserInteractionEnabled:NO];
        [self.menuButton setImage:[UIImage imageNamed:@"icon_list_select"] forState:UIControlStateNormal];
    }
}


#pragma mark - Animation Methods

/*
 *  Animates in the gradient and then calls animate popup
 */

- (void)animateInGradientBeforePopupView:(UIView*)popup
{
    [self.shroudView setAlpha:0.0f];
    [self.shroudView setHidden:NO];
    [UIView animateWithDuration:0.3f
                          delay:0.5f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.shroudView setAlpha:1.0f];
                     } completion:^(BOOL finished) {
                         [self animatePopupView:popup];
                     }];
}

- (void)animateOutGradient
{
    [self.shroudView setAlpha:1.0f];
    [self.shroudView setHidden:NO];
    [UIView animateWithDuration:0.3f
                          delay:0.2f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.shroudView setAlpha:0.0f];
                     } completion:^(BOOL finished) {
                         [self.shroudView setHidden:YES];
                     }];
}

/*
 *  Animates in the popup to the right location
 */

- (void)animatePopupView: (UIView*)popup
{
    [popup setHidden:NO];
    [RMUAnimationClass animateFlyInView:popup
                           withDuration:0.1f
                              withDelay:0.0f
                          fromDirection:buttonAnimationDirectionTop
                         withCompletion:Nil
                             withBounce:YES];
}


@end
