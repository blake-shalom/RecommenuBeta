//
//  RMUProfileScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//


#import "RMUProfileScreen.h"

@interface RMUProfileScreen ()
@property (weak, nonatomic) IBOutlet UIButton *pastRatingsButton;
@property (weak, nonatomic) IBOutlet UILabel *currentRatingsLabel;
@property (weak, nonatomic) IBOutlet UIButton *friendsButton;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UITableView *profileTable;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet UILabel *topEmptyLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomEmptyLabel;
@property (weak, nonatomic) IBOutlet UIImageView *profilePic;
@property (weak, nonatomic) IBOutlet UIView *profilePicView;
@property (weak, nonatomic) IBOutlet UIView *hideNameView;
@property (weak, nonatomic) IBOutlet UIImageView *foodieImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingActivity;

@property NSMutableArray *ratingsArray;
@property NSArray *friendsArray;
@property BOOL isOnPastRatings;
@property BOOL isUserOnFacebook;

@end

@implementation RMUProfileScreen

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
    
    [self.loadingActivity setHidden:YES];
    
    self.ratingsArray = [[NSMutableArray alloc]init];
    self.friendsArray = [[NSArray alloc]init];
    
    // Set the tableview's properties
    self.profileTable.delegate = self;
    self.profileTable.dataSource = self;
    
    [self.pastRatingsButton setTintColor:[UIColor RMULogoBlueColor]];
    [self.friendsButton setTintColor:[UIColor RMUDividingGrayColor]];
    self.isOnPastRatings = YES;
    
    // Do some general setup
    [self.nameLabel setTextColor:[UIColor RMUTitleColor]];
    [self.currentRatingsLabel setTextColor:[UIColor RMUNumRatingGray]];
    
    // Pull a user and sort his/her ratings
    RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
    RMUSavedUser *user = [delegate fetchCurrentUser];
    [self sortUserRatingsIntoRatingsArray:user];
    
    [self.emptyView setBackgroundColor:[UIColor RMUSelectGrayColor]];
    
    if (!user.hasfirstPopup) {
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Welcome To Recommenu!!"
                                                           message:@"Recommend your favorite dishes around town to get started."
                                                          delegate:self
                                                 cancelButtonTitle:@"Okay"
                                                 otherButtonTitles:@"Skip", nil];
        alertView.tag = 2;
        [alertView show];
        user.hasfirstPopup = [NSNumber numberWithBool:YES];
        NSError *saveError;
        if (![delegate.managedObjectContext save:&saveError])
            NSLog(@"Error Saving %@", saveError);

    }
    
    if (user.isFoodie)
        [self.foodieImage setHidden:NO];
    else
        [self.foodieImage setHidden:YES];
    
    // Customize the Appearance of the TabBar
    UITabBarController *tabBarVC = self.tabBarController;
    UITabBar *tabBar = tabBarVC.tabBar;
    [tabBar setTintColor:[UIColor RMULogoBlueColor]];
    
    // If user has signed in with facebook start the loading screen
    if (user.facebookID){
        self.isUserOnFacebook = YES;
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"]
                                           allowLoginUI:YES
                                      completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                          if (!error){
                                              [self.facebookButton setImage:[UIImage imageNamed:@"facebook_on"] forState:UIControlStateNormal];
                                              [self.facebookButton setUserInteractionEnabled:NO];
                                              [self.hideNameView setHidden:NO];
                                              
                                              // Set some frames
                                              CGRect profPicFrame = self.profilePic.frame;
                                              CGRect modifiedProf = CGRectMake(profPicFrame.origin.x, profPicFrame.origin.y, profPicFrame.size.width - 5.0f, profPicFrame.size.height);
                                              [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                                  if (!error) {
                                                      // Success! Include your code to handle the results here
                                                      [self.nameLabel setText:[result objectForKey:@"name"]];
                                                      if (!user.savedPhotoForUser){
                                                          FBProfilePictureView *profileView = [[FBProfilePictureView alloc]initWithProfileID:[result objectForKey:@"id"] pictureCropping:FBProfilePictureCroppingSquare];
                                                          [profileView setFrame:modifiedProf];
                                                          [self.profilePicView addSubview:profileView];

                                                          
                                                          NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=normal", user.facebookID]];
                                                          NSData *data = [NSData dataWithContentsOfURL:url];
                                                          RMUSavedUserPhoto *photo = (RMUSavedUserPhoto*)[NSEntityDescription insertNewObjectForEntityForName:@"RMUSavedUserPhoto"
                                                                                                                                       inManagedObjectContext:delegate.managedObjectContext];
                                                          photo.userPhoto = data;
                                                          user.savedPhotoForUser = photo;
                                                      }
                                                      else {
                                                          UIImage *image = [user.savedPhotoForUser imageForPhotoData];
                                                          [self.profilePic setImage:image];
                                                      }
                                                      UIImageView *circleView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"profile_circle_user"]];
                                                      [circleView setFrame: profPicFrame];
                                                      [self.profilePicView addSubview:circleView];
                                                      [self.hideNameView setHidden:YES];
                                                      
                                                  }
                                                  else {
                                                      NSLog(@"error: %@", error);
                                                      // Fail silently
                                                  }
                                              }];
                                              [self refreshFacebookFriendsListWithUser:user andSession:session];
                                              
                                          }
                                          else
                                              NSLog(@"FACEBOOK ERROR : %@", error);
                                      }];
    }
    else {
        [self.nameLabel setText:@"Anonymous User"];
        [self.facebookButton setImage:[UIImage imageNamed:@"facebook_off"] forState:UIControlStateNormal];
    }
    
}

/*
 *  Queries the DB for friends of the current user
 */

- (void)fetchFriendsOfUser:(RMUSavedUser*)user
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    
    [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/data/friend_list/%i"), user.userID.intValue]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"RESPONSE FROM GET FRIENDS LIST: %@", responseObject);
             self.friendsArray = [responseObject objectForKey:@"response"];
             self.friendsArray = [self.friendsArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                 NSString *last1 = [obj1 objectForKey:@"last_name"];
                 NSString *last2 = [obj2 objectForKey:@"last_name"];
                 return [last1 localizedCompare:last2];
             }];
             if (!self.isOnPastRatings) {
                 [self.profileTable setHidden:NO];
                 [self.emptyView setHidden:YES];
                 [self.profileTable reloadData];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"ERROR: %@, WITH RESPONSE STRING: %@",error, operation.responseString);
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate showMessage:@"Please excuse this error we will get our team on it! All friends will not show." withTitle:@"Error In Extracting Friends!"];
             self.friendsArray = [[NSArray alloc]init];
             if (!self.isOnPastRatings) {
                 [self.profileTable setHidden:NO];
                 [self.emptyView setHidden:YES];
                 [self.profileTable reloadData];
             }
         }];
}

/*
 *  Sets analytics and user feedback data
 */

- (void)viewDidAppear:(BOOL)animated
{
    // SET the profile screen name for Google analytics
    self.screenName = @"Profile Screen";
    [super viewDidAppear:animated];
    RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
    RMUSavedUser *user = [delegate fetchCurrentUser];
    [self sortUserRatingsIntoRatingsArray:user];
    [self.profileTable reloadData];
}

/*
 *  Sorts a user's ratings into an object for the table storage
 */

- (void)sortUserRatingsIntoRatingsArray: (RMUSavedUser*) user
{
    // Handle rating storage
    if (user.ratingsForUser.count == 0) {
        [self.currentRatingsLabel setText:@"0 Ratings"];
        [self showPastRatings:self];
    }
    else {
        // Set UI
        [self.profileTable setHidden:NO];
        [self.currentRatingsLabel setText:[NSString stringWithFormat:@"%i Ratings", user.ratingsForUser.count]];
        
        // Sort ratings into containers
        [self.ratingsArray removeAllObjects];
        for (RMUSavedRecommendation *recommendation in user.ratingsForUser) {
            BOOL doesRestExist = NO;
            for (NSMutableDictionary *recDict in self.ratingsArray) {
                if ([[recDict objectForKey:@"restName"] isEqualToString:recommendation.restaurantName]) {
                    doesRestExist = YES;
                    [[recDict objectForKey:@"recArray"] addObject:recommendation];
                }
            }
            if (!doesRestExist) {
                NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc]initWithDictionary:@{@"restName": recommendation.restaurantName}];
                NSMutableArray *recArray = [[NSMutableArray alloc]initWithObjects:recommendation, nil];
                [newDictionary setObject:recArray forKey:@"recArray"];
                [self.ratingsArray addObject:newDictionary];
            }
        }
    }
}

/*
 *  Set Up User elements
 */

- (void)loadFacebookUserElements
{
        [self.facebookButton setImage:[UIImage imageNamed:@"facebook_on"] forState:UIControlStateNormal];
        [self.facebookButton setUserInteractionEnabled:NO];
        [self.hideNameView setHidden:NO];
        
        // Set some frames
        CGRect profPicFrame = self.profilePic.frame;
        CGRect modifiedProf = CGRectMake(profPicFrame.origin.x, profPicFrame.origin.y, profPicFrame.size.width - 5.0f, profPicFrame.size.height);
                                          [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                                              if (!error) {
                                                  // Success! Include your code to handle the results here
                                                  NSLog(@"user info: %@", result);
                                                  [self.nameLabel setText:[result objectForKey:@"name"]];
                                                  FBProfilePictureView *profileView = [[FBProfilePictureView alloc]initWithProfileID:[result objectForKey:@"id"] pictureCropping:FBProfilePictureCroppingSquare];
                                                  [profileView setFrame:modifiedProf];
                                                  [self.profilePicView addSubview:profileView];
                                                  UIImageView *circleView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"profile_circle_user"]];
                                                  [circleView setFrame: profPicFrame];
                                                  [self.profilePicView addSubview:circleView];
                                                  [self.hideNameView setHidden:YES];
                                              }
                                              else {
                                                  NSLog(@"error: %@", error);
                                                  // An error occurred, we need to handle the error
                                              }
                                          }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableView Data source

/*
 *  Return the right height, depending on the selected index
 */

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isOnPastRatings)
        return 80.0;
    else
        return 67.0;
}

/*
 *  Cell for row uses Rating cells
 */

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (self.isOnPastRatings) {
        static NSString *CellIdentifier = @"ratingCell";
        RMUProfileRatingCell *rateCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSArray *recArray = [self.ratingsArray[indexPath.section] objectForKey:@"recArray"];
        RMUSavedRecommendation *rec = recArray[indexPath.row];
        [rateCell.entreeLabel setText:rec.entreeName];
        [rateCell.descriptionLabel setText:rec.entreeDesc];
        if (rec.isRecommendPositive.boolValue)
            [rateCell.likeDislikeImage setImage:[UIImage imageNamed:@"thumbs_up_profile"]];
        else
            [rateCell.likeDislikeImage setImage:[UIImage imageNamed:@"thumbs_down_profile"]];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        [formatter setDateFormat:@"MM/dd/yyy"];
        [rateCell.dateLabel setText:[formatter stringFromDate:rec.timeRated]];
        cell = rateCell;
    }
    else {
        static NSString *CellIdentifier = @"friendCell";
        RMUProfileFriendCell *friendCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        NSDictionary *friendDict = self.friendsArray[indexPath.row];
        NSString *nameOfFriend = [NSString stringWithFormat:(@"%@ %@"), [friendDict objectForKey:@"first_name"], [friendDict objectForKey:@"last_name"]];
        [friendCell.friendNameLabel setText:nameOfFriend];
        FBProfilePictureView *profileView = [[FBProfilePictureView alloc]initWithProfileID:[friendDict objectForKey:@"facebook_id"] pictureCropping:FBProfilePictureCroppingSquare];
        [friendCell.numRatingsLabel setText:@""];
        [profileView setFrame:friendCell.friendImage.frame];
        [friendCell addSubview:profileView];
        cell = friendCell;
    }
    return cell;
}

/*
 *  Number of rows checks the backend sotrage and return depending on state
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isOnPastRatings) {
        NSArray *rowArray = [self.ratingsArray[section] objectForKey:@"recArray"];
        return rowArray.count;
    }
    else
        return self.friendsArray.count;
}

/*
 *  If you are on friends aray, return one section, else return appropriate number from backend storage
 */

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.isOnPastRatings)
        return self.ratingsArray.count;
    else
        return 1;
}

/*
 *  Title is rest name if on past ratings, "Friends" otherwise
 */

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.isOnPastRatings)
        return [self.ratingsArray[section] objectForKey:@"restName"];
    else
        return @"FRIENDS";
}


#pragma mark - segue methods

/*
 *  Currently three segues is supported, profile to menu, that redirects a user to the menu of an item, and to other user
 */

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"profileToMenu"]) {
        RMURevealViewController *nextScreen = (RMURevealViewController*) segue.destinationViewController;
        nextScreen.hidesBottomBarWhenPushed = YES;
        NSIndexPath *indexPath = [self.profileTable indexPathForSelectedRow];
        NSArray *recArray = [self.ratingsArray[indexPath.section] objectForKey:@"recArray"];
        RMUSavedRecommendation *rec = recArray[indexPath.row];
        NSLog(@"%@", rec.restFoursquareID);
        [nextScreen getRestaurantWithFoursquareID:rec.restFoursquareID andName:rec.restaurantName];
    }
    else if ([segue.identifier isEqualToString:@"profileToOtherProfile"]) {

        RMUOtherProfileScreen *foodieProf = (RMUOtherProfileScreen*) segue.destinationViewController;
        foodieProf.hidesBottomBarWhenPushed = YES;
        NSIndexPath *indexPath = [self.profileTable indexPathForSelectedRow];
        NSDictionary *dict = self.friendsArray[indexPath.row];
        foodieProf.isFoodie = NO;
        NSLog(@"%@", dict);
        foodieProf.RMUUsername = [dict objectForKey:@"username"];
        foodieProf.facebookID = [dict objectForKey:@"facebook_id"];
        NSString *nameOfFriend = [NSString stringWithFormat:(@"%@ %@"), [dict objectForKey:@"first_name"], [dict objectForKey:@"last_name"]];
        foodieProf.nameOfOtherUser = nameOfFriend;
        foodieProf.RMUUserID = [dict objectForKey:@"recommenu_id"];
    }
    else {
        NSLog(@"Unknown ID: %@", segue.identifier);
    }
    
}

#pragma mark - interactivity

/*
 *  Logs in on Facebook
 */

- (IBAction)loginOnFaceBook:(id)sender
{
    [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"]
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session, FBSessionState state, NSError *error) {
         if (!error){
             // Retrieve the app delegate
             RMUAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
             [self.facebookButton setImage:[UIImage imageNamed:@"facebook_on"] forState:UIControlStateNormal];
             [self.facebookButton setUserInteractionEnabled:NO];
             [self.hideNameView setHidden:NO];
             // Call the app delegate's sessionStateChanged:state:error method to handle session state changes
             [appDelegate sessionStateChanged:session state:state error:error];
             self.isUserOnFacebook = YES;
             [self loadFacebookUserElements];
             RMUSavedUser *user = [appDelegate fetchCurrentUser];
             [self logFacebookUser:user intoRecommenuWithSession:session];
         }
         else {
             NSLog(@"ERRROR: %@", error);
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate sessionStateChanged:session state:state error:error];
         }
     }];
}

/*
 *  Logs a user with Facebook into Recommenu's DB
 */

#warning TODO handle failure cases!!!

- (void)logFacebookUser:(RMUSavedUser*)user intoRecommenuWithSession:(FBSession*)session
{
    [FBRequestConnection startForMeWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            user.facebookID = [result objectForKey:@"id"];
            user.firstName = [result objectForKey:@"first_name"];
            user.lastName = [result objectForKey:@"last_name"];
            NSLog(@"FACEBOOKID: %@", user.facebookID);
            RMUAppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
            NSError *saveError;
            if (![appDelegate.managedObjectContext save:&saveError])
                NSLog(@"Error Saving %@", saveError);
            
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            [manager.requestSerializer setValue:@"ApiKey recommenumaster:5767146e19ab6cbcf843ad3ab162dc59e428156a"
                             forHTTPHeaderField:@"Authorization"];
            // Put first name and last name into DB
            [manager PUT:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/%@"), user.userURI]
              parameters:@{@"first_name": user.firstName,
                           @"last_name" : user.lastName}
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSLog(@"RESPONSE : %@", responseObject);
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     NSLog(@"ERROR : %@",error);
                 }];
            // Put users facebook ID into DB
            [manager PUT:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/api/v1/user_profile/%i/"), user.userID.intValue]
              parameters:@{@"facebook_id": user.facebookID}
                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                     NSLog(@"SUCCESS FROM LOGGING: %@", responseObject);
                     [self refreshFacebookFriendsListWithUser:user andSession:session];
                 }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     NSLog(@"FAIL: %@ with response: %@", error, operation.responseString);
                 }];
        }
        else
            NSLog(@"ERRRRRRRR : %@", error);
    }];
}

/*
 *  Calls the Backend's script for sorting users and gets the profile model working
 */

- (void) refreshFacebookFriendsListWithUser:(RMUSavedUser*)user andSession:(FBSession*) session
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    NSLog(@"URL QUERIED:  http://glacial-ravine-3577.herokuapp.com/data/update_friends/%@/%@", user.facebookID, session.accessTokenData.accessToken);
    [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/data/update_friends/%@/%@"), user.facebookID, session.accessTokenData.accessToken]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Response from update_fb: %@",responseObject);
             [self fetchFriendsOfUser:user];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Fail silently, ask for friends anyways
             [self fetchFriendsOfUser:user];
             NSLog(@"ERROR: %@, with RESPONSE STRING: %@", error, operation.responseString);
         }];
}

/*
 *  toggles between past ratings to friends
 */

- (IBAction)showFriendsRatings:(id)sender
{
    [self.friendsButton setTintColor:[UIColor RMULogoBlueColor]];
    [self.pastRatingsButton setTintColor:[UIColor RMUDividingGrayColor]];
    self.isOnPastRatings = NO;
    if (self.friendsArray.count > 0) {
        [self.profileTable setHidden:NO];
        [self.emptyView setHidden:YES];
        [self.profileTable reloadData];
    }
    else {
        if (self.isUserOnFacebook) {
            [self.profileTable setHidden:YES];
            [self.topEmptyLabel setHidden:YES];
            [self.bottomEmptyLabel setHidden:YES];
            [self.loadingActivity setHidden:NO];
        }
        // Else hide the Table and show the empty view
        else {
            [self.profileTable setHidden:YES];
            [self.emptyView setHidden:NO];
            [self.topEmptyLabel setText:@"You don't have any friends yet!"];
            [self.bottomEmptyLabel setText:@"Connect through Facebook to search for friends and view their ratings."];
        }
    }
}

/*
 *  Toggles between friends to past ratings
 */

- (IBAction)showPastRatings:(id)sender
{
    [self.topEmptyLabel setHidden:NO];
    [self.bottomEmptyLabel setHidden:NO];
    [self.loadingActivity setHidden:YES];
    [self.pastRatingsButton setTintColor:[UIColor RMULogoBlueColor]];
    [self.friendsButton setTintColor:[UIColor RMUDividingGrayColor]];
    self.isOnPastRatings = YES;
    if (self.ratingsArray.count > 0) {
        [self.profileTable setHidden:NO];
        [self.emptyView setHidden:YES];
        [self.profileTable reloadData];
    }
    else {

        [self.profileTable setHidden:YES];
        [self.emptyView setHidden:NO];
        [self.topEmptyLabel setText:@"Rate more items to see them on your profile!"];
        [self.bottomEmptyLabel setText:@""];
        // Show the correct headers on the missing view
    }
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 2 && buttonIndex == 0) {
        [self.tabBarController setSelectedIndex:2];
    }
}

@end
