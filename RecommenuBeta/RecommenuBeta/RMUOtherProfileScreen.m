//
//  RMUOtherProfileScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 1/16/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//

#import "RMUOtherProfileScreen.h"


@interface RMUOtherProfileScreen ()

@property (weak, nonatomic) IBOutlet RMUButton *blogButton;
@property (weak, nonatomic) IBOutlet UIImageView *foodieBadge;
@property (weak, nonatomic) IBOutlet UITableView *profileTable;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *numRatingsLabel;
@property (weak, nonatomic) IBOutlet UIView *hideProfileView;
@property (weak, nonatomic) IBOutlet UIView *profilePicView;
@property (weak, nonatomic) IBOutlet UIView *topProfileView;
@property (weak, nonatomic) IBOutlet UIView *loadingView;
@property (weak, nonatomic) IBOutlet UILabel *friendNoRatingLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadindicator;
@property (weak, nonatomic) IBOutlet UITableView *ratingTable;


@property (strong,nonatomic) NSMutableArray *ratingsArray;

@end

@implementation RMUOtherProfileScreen

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
    self.blogButton.isBlue = YES;
    [self.blogButton setBackgroundColor:[UIColor RMULogoBlueColor]];
    [self.numRatingsLabel setText:@""];
    self.ratingsArray = [[NSMutableArray alloc]init];
    
    // Handle facebook elements
    if (self.facebookID)
        [self handleFacebookProfile];
    if (self.nameOfOtherUser)
        [self.nameLabel setText:self.nameOfOtherUser];
    
    [self hideFoodieElements];
    // Do waiting stuff
    [self.loadindicator startAnimating];
    [self.friendNoRatingLabel setHidden:YES];
    
    // Load Recommendations
    [self loadRecommendations];
    
    // Load the blog if it exists
    [self loadBlog];
	// Do any additional setup after loading the view.
}

- (void)handleFacebookProfile
{
    [self.hideProfileView setHidden:NO];
    CGRect profPicFrame = self.profilePicView.frame;
    CGRect modifiedProf = CGRectMake(profPicFrame.origin.x, profPicFrame.origin.y, profPicFrame.size.width - 5.0f, profPicFrame.size.height);
    FBProfilePictureView *profileView = [[FBProfilePictureView alloc]initWithProfileID:self.facebookID pictureCropping:FBProfilePictureCroppingSquare];
    [profileView setFrame:modifiedProf];
    [self.topProfileView addSubview:profileView];
    UIImageView *circleView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"profile_circle_user"]];
    [circleView setFrame: profPicFrame];
    [self.topProfileView addSubview:circleView];
    [self.hideProfileView setHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    self.screenName = @"Other Profile Screen";
    [super viewDidAppear:animated];
}

#pragma mark - Networking

/*
 *  Loads blog into the profile
 */

- (void)loadBlog
{
    if (self.RMUUserID) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager.requestSerializer setValue:@"ApiKey recommenumaster:5767146e19ab6cbcf843ad3ab162dc59e428156a"
                         forHTTPHeaderField:@"Authorization"];
        [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/api/v1/user_profile/%@/"),self.RMUUserID]
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 NSLog(@"response from user_prof: %@", responseObject);
                 NSString *website = [responseObject objectForKey:@"website"];
                 NSLog(@"Website %@", website);
                 if (!(website == (NSString*) [NSNull null])){
                     [self showFoodieElements];
                     [self.blogButton setTitle:website forState:UIControlStateNormal];
                 }
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 NSLog(@"Error from user_prof: %@ with resp string: %@", error, operation.responseString);
                 // Failed call, just don't show the blog elements
             }];
    }
}

/*
 *  Loads Recommendations for user picked
 */

- (void)loadRecommendations
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager.requestSerializer setValue:@"ApiKey recommenumaster:5767146e19ab6cbcf843ad3ab162dc59e428156a"
                     forHTTPHeaderField:@"Authorization"];
    [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/api/v1/rating/?user__username=%@"), self.RMUUsername]
      parameters:Nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"SUCCESS GETTING RATINGS RESPONSE OBJECT: %@", responseObject);
             NSString *numRatings = [NSString stringWithFormat:(@"%@ Recommendations"),[[responseObject objectForKey:@"meta"]objectForKey:@"total_count"]];
             self.numRatingsLabel.text = numRatings;
             [self loadIntoBackStorageWithResponse:[responseObject objectForKey:@"objects"]];
             [self.loadingView setHidden:YES];
             [self.ratingTable reloadData];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"ERROR: %@ with response string: %@", error, operation.responseString);
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate showMessage:@"Server error will result in no ratings showing up for this profile! We will squash to bug soon!" withTitle:@"Error In Extracting Ratings!"];
         }];
}

/*
 *  After networking events load the objects into storage to display ratings
 */

- (void)loadIntoBackStorageWithResponse: (NSArray*) response
{
    for (NSDictionary *recommendation in response) {
        NSString *restaurant = [recommendation objectForKey:@"restaurant"];
        NSString *entreeName = [recommendation objectForKey:@"dish_name"];
        if (![restaurant isEqualToString:@""] && ![entreeName isEqualToString:@""]) {
            BOOL doesRestExist = NO;
            for (NSDictionary *recDict in self.ratingsArray) {
                if ([restaurant isEqualToString:[recDict objectForKey:@"restName"]]) {
                    doesRestExist = YES;
                    [[recDict objectForKey:@"recArray"] addObject:recommendation];
                }
            }
            if (!doesRestExist) {
                NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc]initWithDictionary:@{@"restName": restaurant}];
                NSMutableArray *recArray = [[NSMutableArray alloc]initWithObjects:recommendation, nil];
                [newDictionary setObject:recArray forKey:@"recArray"];
                [self.ratingsArray addObject:newDictionary];
            }
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 *  Pops VC on press of back button
 */

- (IBAction)backScreen:(id)sender
{
    if (self.navigationController)
        [self.navigationController popViewControllerAnimated:YES];
    else
        [self performSegueWithIdentifier:@"otherProfileToHome"
                                  sender:self];
}

/*
 *  Hides elements of the foodie for other friend user
 */

- (void)hideFoodieElements
{
    [self.blogButton setHidden:YES];
    [self.foodieBadge setHidden:YES];
}

/*
 * Shows foodie elements for a foodie user
 */

- (void)showFoodieElements
{
    [self.blogButton setHidden:NO];
    [self.foodieBadge setHidden:NO];
}


#pragma mark - Table Data source

/*
 *  Look into the back storage at the certain restaurant and determine the number of recommendations
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *rowArray = [self.ratingsArray[section] objectForKey:@"recArray"];
    return rowArray.count;
}

/*
 *  Cell for row looks at each recommendation and sets labels appropriately
 */

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ratingCell";
    RMUProfileRatingCell *rateCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSArray *recArray = [self.ratingsArray[indexPath.section] objectForKey:@"recArray"];
    NSDictionary *rec = recArray[indexPath.row];
    [rateCell.entreeLabel setText:[rec objectForKey:@"dish_name"]];
    [rateCell.descriptionLabel setText:[rec objectForKey:@""]];
    if ([[rec objectForKey:@"positive"] isEqualToNumber:[NSNumber numberWithBool:YES]])
        [rateCell.likeDislikeImage setImage:[UIImage imageNamed:@"thumbs_up_profile"]];
    else
        [rateCell.likeDislikeImage setImage:[UIImage imageNamed:@"thumbs_down_profile"]];
    
    return  rateCell;
}

/*
 *  Number of sections is equal to the number of restaurants in the backend store
 */

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.ratingsArray.count;
}

/*
 *  Return the restaurant's name for each title
 */

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.ratingsArray[section] objectForKey:@"restName"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"otherProfileToMenu"
                              sender:self];
}

#pragma mark - Segue methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"otherProfileToMenu"]) {
        RMURevealViewController *nextScreen = (RMURevealViewController*) segue.destinationViewController;
        NSIndexPath *indexPath = [self.profileTable indexPathForSelectedRow];
        NSArray *recArray = [self.ratingsArray[indexPath.section] objectForKey:@"recArray"];
        NSString *foursquareID = [recArray[indexPath.row] objectForKey:@"foursquare_venue_id"];
        NSString *restaurant = [recArray [indexPath.row] objectForKey:@"restaurant"];
        NSLog(@"4[] ID: %@", foursquareID);
        [nextScreen getRestaurantWithFoursquareID:foursquareID andName:restaurant];
    }
    else if ([segue.identifier isEqualToString:@"otherProfileToBlog"]) {
        RMUBlogViewController *nextScreen = (RMUBlogViewController*) segue.destinationViewController;
        nextScreen.blogURLString = self.blogButton.titleLabel.text;
    }
}

#pragma mark - Interactivity

/*
 *  Opens a webview with the blog in it
 */

- (IBAction)openFoodBlog:(id)sender
{

}

@end
