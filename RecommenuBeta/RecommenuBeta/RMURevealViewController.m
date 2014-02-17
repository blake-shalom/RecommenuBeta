//
//  RMURevealViewController.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/27/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMURevealViewController.h"

@interface RMURevealViewController ()


@end

@implementation RMURevealViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/*
 *  Override viewDidAppear to set custom subviews
 */

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // If the front VC is a rating screen then the menu was already loaded, go ahead and set the menu properties
    if ([self.frontViewController isKindOfClass:[RMURatingScreen class]]) {
        // Rating screen gets current menu
        RMURatingScreen *ratingScreen = (RMURatingScreen*) self.frontViewController;
        [ratingScreen setupMenuElementsWithRestaurant:self.currentRestaurant];
        [ratingScreen setupViews];
        
        // So does side menu
        RMUSideMenuScreen *sideMenu = (RMUSideMenuScreen*)self.rearViewController;
        [sideMenu loadCurrentRestaurant:self.currentRestaurant];
        sideMenu.delegate = self;
    }
    self.draggableBorderWidth = 20.0f;
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

/*
 *  Sets a property that the children VC's of the reveal controller use to fill their data structures
 */

- (void)getRestaurantWithFoursquareID:(NSString *)foursquareID andName:(NSString *)name
{
    // Set uploading of menu screen
    RMUMenuScreen *menuScreen = (RMUMenuScreen*) self.frontViewController;
    [menuScreen.indicator setHidden:NO];
    [menuScreen.indicator startAnimating];

    // Use networking to get menu
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    [manager GET:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/%@/menu", foursquareID]

      parameters:@{@"VENUE_ID": [NSString stringWithFormat:@"%@", foursquareID],
                   @"client_id" : [[NSUserDefaults standardUserDefaults] stringForKey:@"foursquareID"],
                   @"client_secret" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareSecret"],
                   @"v" : @20131017}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             [self.view setHidden:NO];
             NSLog(@"MENU : %@", responseObject);
             self.currentRestaurant = [[RMURestaurant alloc]initWithDictionary:[responseObject objectForKey:@"response"]
                                                             andRestaurantName:name];
             self.currentRestaurant.restFoursquareID = foursquareID;
             if (self.currentRestaurant.menus.count == 0)
                 [self setChildViewControllersUIWithCurrentRestaurant];
             else
                 [self gatherRatingsForMenu];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"error : %@", error);
         }];
}

/*
 *  Loads Menu Screen with a different menu selection, used as an intermediary between side menu and menu screen
 */

- (void)loadMenuScreenWithMenu:(RMUMenu *)menu
{
    RMUMenuScreen *menuScreen = (RMUMenuScreen*) self.frontViewController;
    [menuScreen loadMenu:menu];
}

/*
 *  Loads ratings into menu and sets current menu on other screens
 */

- (void)gatherRatingsForMenu
{
    // Start networking with our database to gather our proprietary ratings
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
    RMUSavedUser *user = [delegate fetchCurrentUser];
    [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/data/menu/%@/%i"), self.currentRestaurant.restFoursquareID, user.userID.intValue]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"response : %@",responseObject);
             
             // Take response object and put it into menus
             [self loadMenuWithRatingsWithDictionary:responseObject];
             [self setChildViewControllersUIWithCurrentRestaurant];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"error: %@ with response string: %@", error, operation.responseString);
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate showMessage:@"Please excuse this error we will get our team on it! All ratings will not show." withTitle:@"Error In Extracting Ratings!"];
             [self setChildViewControllersUIWithCurrentRestaurant];
         }];
}

/*
 *  After networking, set all of the child view controllers
 */

- (void)setChildViewControllersUIWithCurrentRestaurant
{
    // Handles menu "front" screen
    RMUMenuScreen *menuScreen = (RMUMenuScreen*) self.frontViewController;
    [menuScreen setupMenuElementsWithRestaurant:self.currentRestaurant];
    [menuScreen setupViews];
    [menuScreen.indicator setHidden:YES];
    
    // Handles side menu "rear" screen
    RMUSideMenuScreen *sideMenu = (RMUSideMenuScreen*)self.rearViewController;
    [sideMenu loadCurrentRestaurant:self.currentRestaurant];
    sideMenu.delegate = self;
}


/*
 *  simply loads each rating into a restaurant object (simple search algorithm)
 */

- (void)loadMenuWithRatingsWithDictionary: (NSDictionary*)respDictionary
{
    for (NSDictionary *rating in [respDictionary objectForKey:@"recommendations"])
        for (RMUMenu *menu in self.currentRestaurant.menus)
            for (RMUCourse *course in menu.courses)
                for (RMUMeal *meal in course.meals)
                    if ([meal.mealID isEqualToString:[rating objectForKey:@"entree_id"]])
                        [meal loadLikeDislikeInformationWithDictionary:rating];
                        
}

@end
