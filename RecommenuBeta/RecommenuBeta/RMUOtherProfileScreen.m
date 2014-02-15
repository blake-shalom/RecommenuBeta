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
    
    //Handle foodie elements
    if (self.isFoodie)
        [self showFoodieElements];
    else
        [self hideFoodieElements];

    // Handle facebook elements
    if (self.facebookID)
        [self handleFacebookProfile];
    if (self.nameOfOtherUser)
        [self.nameLabel setText:self.nameOfOtherUser];
    
    // Do waiting stuff
    [self.loadindicator startAnimating];
    [self.friendNoRatingLabel setHidden:YES];
    
    // Load Recommendations
    [self loadRecommendations];
    
	// Do any additional setup after loading the view.
}

- (void)handleFacebookProfile
{
    [self.hideProfileView setHidden:NO];
    CGRect profPicFrame = self.profilePicView.frame;
    CGRect modifiedProf = CGRectMake(profPicFrame.origin.x, profPicFrame.origin.y, profPicFrame.size.width - 5.0f, profPicFrame.size.height);
    
    
    // Success! Include your code to handle the results here
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
 *  Loads Recommendations for user
 */

- (void)loadRecommendations
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
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
         }];
}

- (void)loadIntoBackStorageWithResponse: (NSArray*) response
{
    for (NSDictionary *recommendation in response) {
        NSString *restaurant = [recommendation objectForKey:@"restaurant"];
        if (![restaurant isEqualToString:@""]) {
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
    [self.navigationController popViewControllerAnimated:YES];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *rowArray = [self.ratingsArray[section] objectForKey:@"recArray"];
    return rowArray.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ratingCell";
    RMUProfileRatingCell *rateCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSArray *recArray = [self.ratingsArray[indexPath.section] objectForKey:@"recArray"];
    NSDictionary *rec = recArray[indexPath.row];
    [rateCell.entreeLabel setText:[rec objectForKey:@""]];
    [rateCell.descriptionLabel setText:[rec objectForKey:@""]];
    if ([[rec objectForKey:@"positive"] isEqualToNumber:[NSNumber numberWithBool:YES]])
        [rateCell.likeDislikeImage setImage:[UIImage imageNamed:@"thumbs_up_profile"]];
    else
        [rateCell.likeDislikeImage setImage:[UIImage imageNamed:@"thumbs_down_profile"]];
    
    return  rateCell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.ratingsArray.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.ratingsArray[section] objectForKey:@"restName"];
}

@end
