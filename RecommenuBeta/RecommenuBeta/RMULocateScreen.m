//
//  RMULocateScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//
#define NUMBER_OF_FALLBACK 15

#import "RMULocateScreen.h"

#warning TODO Google Analytics

@interface RMULocateScreen ()

// IBOutlets
@property (weak, nonatomic) IBOutlet UIView *mapFrameView;
@property (weak, nonatomic) IBOutlet RMUButton *yesButton;
@property (weak, nonatomic) IBOutlet RMUButton *noButton;
@property (weak, nonatomic) IBOutlet UIImageView *gradientImage;
@property (weak, nonatomic) IBOutlet UIView *popupView;
@property (weak, nonatomic) IBOutlet UILabel *restaurantLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIView *fallbackPopup;
@property (weak, nonatomic) IBOutlet UITableView *fallbackTable;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

// Regular properties
@property (strong,nonatomic) NSMutableArray *fallbackRest;
@property (strong, nonatomic) RMMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong,nonatomic) NSString *restID;
@property (strong,nonatomic) NSString *restString;
@property BOOL hasDroppedPin;

@end

@implementation RMULocateScreen

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
    self.hasDroppedPin =NO;
    self.fallbackRest = [[NSMutableArray alloc]init];
    
    // Deactivate dismiss button
    [self.dismissButton setUserInteractionEnabled:NO];
    
    // Add borders to buttons
    self.yesButton.layer.borderWidth = 1.0;
    self.yesButton.layer.borderColor = [UIColor blackColor].CGColor;
    self.noButton.layer.borderWidth = 1.0;
    self.noButton.layer.borderColor = [UIColor blackColor].CGColor;
    
    // Customize the Appearance of the TabBar
    UITabBarController *tabBarVC = self.tabBarController;
    UITabBar *tabBar = tabBarVC.tabBar;
    [tabBar setTintColor:[UIColor RMULogoBlueColor]];
    
    // Hide yo wife
    [self.popupView setHidden:YES];
    [self.gradientImage setHidden:YES];
    
    // Make the mapBox View
    RMMapBoxSource *tileSource = [[RMMapBoxSource alloc]initWithMapID:@"recommenu.gd0lbham"];
    self.mapView = [[RMMapView alloc]initWithFrame:self.mapFrameView.bounds andTilesource:tileSource];
    [self.view addSubview:self.mapView];
    [self.view sendSubviewToBack:self.mapView];
    self.mapView.draggingEnabled = NO;
    
    // Center the view around your location
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.location = [[CLLocation alloc]init];
    [self.locationManager startUpdatingLocation];
    self.restID = [[NSString alloc]init];
    self.restString = [[NSString alloc]init];

    // Connfigure the buttons
    self.yesButton.isBlue = YES;
    self.noButton.isBlue = NO;
    [self.yesButton setBackgroundColor:[UIColor RMULogoBlueColor]];
    [self.yesButton.titleLabel setTextColor:[UIColor whiteColor]];
    [self.noButton setBackgroundColor:[UIColor whiteColor]];
    
    self.fallbackTable.tableFooterView = [[UIView alloc]initWithFrame:CGRectZero];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Location manager delegate

// Handles when location manager updates
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // Find Your Location
    NSLog(@"Updating....");
    [self.locationManager stopUpdatingLocation];
    self.location = locations[0];
    CLLocationCoordinate2D coord = self.location.coordinate;
    [self.mapView setCenterCoordinate:coord animated:YES];
    
    // Drop a pin
#warning - TODO customized user annotation
#warning  TODO cache map images
    if (!self.hasDroppedPin){
        RMPointAnnotation *userAnnotation = [[RMPointAnnotation alloc] initWithMapView:self.mapView
                                                                            coordinate:coord
                                                                              andTitle:@"YOU ARE HERE"];
        [self.mapView addAnnotation:userAnnotation];
        self.hasDroppedPin = YES;
    }
    [self findRestaurantWithRadius:10.0f];
}

#pragma mark - Networking

/*
 *  Finds the current restaurant you are at
 */

- (void)findRestaurantWithRadius:(NSInteger)radius
{
    CLLocationCoordinate2D coord = self.location.coordinate;
    NSString *latLongString = [NSString stringWithFormat:@"%f,%f", coord.latitude, coord.longitude];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *paramDic = @{@"ll" : latLongString,
                               @"limit": @15,
                               @"intent" : @"browse",
                               @"radius" : [NSString stringWithFormat:@"%d", radius],
                               @"categoryId" : @"4d4b7105d754a06374d81259",
                               @"client_id" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareID"],
                               @"client_secret" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareSecret"],
                               @"v" : @20131017
                               };
    [manager GET:@"https://api.foursquare.com/v2/venues/search"
      parameters:paramDic
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSArray *respArray = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             if (respArray.count ==0)
                 [self findRestaurantWithRadius:radius * 3 / 2];
             else {
                 if ([self.restString isEqualToString:@""]) {
                     self.restString =[respArray[0] objectForKey:@"name"];
                     self.restID = [respArray[0] objectForKey:@"id"];
                     [self.restaurantLabel setText:self.restString];
                     [self.addressLabel setText:[[respArray[0] objectForKey:@"location"] objectForKey:@"address"]];
                     [self animateInGradient];
                 }
            }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"error: %@", error);
         }];
}

/*
 *  Finds a list of restaurants that the user could be at
 */

- (void)findFallbacksWithRadius:(NSInteger)radius
{
    CLLocationCoordinate2D coord = self.location.coordinate;
    NSString *latLongString = [NSString stringWithFormat:@"%f,%f", coord.latitude, coord.longitude];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *paramDic = @{@"ll" : latLongString,
                               @"limit": @15,
                               @"intent" : @"browse",
                               @"radius" : [NSString stringWithFormat:@"%d", radius],
                               @"categoryId" : @"4d4b7105d754a06374d81259",
                               @"client_id" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareID"],
                               @"client_secret" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareSecret"],
                               @"v" : @20131017
                               };
    [manager GET:@"https://api.foursquare.com/v2/venues/search"
      parameters:paramDic
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSArray *respArray = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             if (respArray.count < NUMBER_OF_FALLBACK)
                 [self findFallbacksWithRadius:radius * 3 / 2];
             else {
                 for (int i = 0; i < NUMBER_OF_FALLBACK; i++) {
                     [self.fallbackRest addObject:respArray[i]];
                 }
                 [self.fallbackPopup setHidden:NO];
                 [self animateFallbackPopup];
                 [self.fallbackTable reloadData];
                 
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"error: %@", error);
         }];
}


#pragma mark - Interactivity Methods

/*
 *  Allows a user to reload process should they pick the wrong restaurant
 */

- (IBAction)dismissPopups:(id)sender
{
    [self.popupView setHidden:YES];
    [self.fallbackPopup setHidden:YES];
    [self animateOutGradient];
}

/*
 *  If restaurant guessed is correct then report it's foursquare id and obtain a menu
 */

- (IBAction)confirmRestaurant:(id)sender
{
    
}


/*
 *  Finds a list of other fallback options for the location of the user
 */

- (IBAction)findFallbackLocations:(id)sender
{
    [self.noButton setUserInteractionEnabled:NO];
    [self.yesButton setUserInteractionEnabled:NO];
    [self findFallbacksWithRadius:25];
}

#pragma mark - segue methods

/*
 *  Readies the VC's for a segue
 */

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.yesButton setUserInteractionEnabled:NO];
    [self.noButton setUserInteractionEnabled:NO];
    if ([segue.identifier isEqualToString:@"locateToMenu"]) {
        RMURevealViewController *nextScreen = (RMURevealViewController*) segue.destinationViewController;
        [nextScreen getRestaurantWithFoursquareID:self.restID andName:self.restString];
    }
    else {
        NSLog(@"ERROR: UNKNOWN SEGUE %@", segue.identifier);
    }
    [self.yesButton setUserInteractionEnabled:YES];
    [self.noButton setUserInteractionEnabled:YES];

}

#pragma mark - UITableview Delegate

/*
 *  returns number of rows
 */

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.fallbackRest.count;
}

/*
 *  Accessses specific cell at an index path
 */

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell.textLabel setText:[self.fallbackRest[[indexPath row]] objectForKey:@"name"]];
    [cell.textLabel setTextColor:[UIColor RMUSelectGrayColor]];
    return cell;
}

/*
 *  Return one section fo the table
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

/*
 *  selects a row and sets an instance variable to the selected dictionary
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@", [self.fallbackRest[[indexPath row]] objectForKey:@"id"]);
    NSDictionary *selRest = self.fallbackRest[indexPath.row];
    self.restID = [selRest objectForKey:@"id"];
    self.restString = [selRest objectForKey:@"name"];
    [self performSegueWithIdentifier:@"locateToMenu" sender:self];
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
                          delay:1.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.gradientImage setAlpha:1.0f];
                         [self.popupView setAlpha:1.0f];
                     } completion:^(BOOL finished) {
                         [self.popupView setHidden:NO];
                         [self.dismissButton setUserInteractionEnabled:YES];
                         [self animatePopup];
                     }];
}

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
                         [self.dismissButton setUserInteractionEnabled:NO];
                         [self.locationManager startUpdatingLocation];
                         self.restString = @"";
                         [self.yesButton setUserInteractionEnabled:YES];
                         [self.noButton setUserInteractionEnabled:YES];
                     }];
}

/*
 *  Animates in the popup to the right location
 */

- (void)animatePopup
{
    [RMUAnimationClass animateFlyInView:self.popupView
                           withDuration:0.1f
                              withDelay:0.0f
                          fromDirection:buttonAnimationDirectionTop
                         withCompletion:Nil
                             withBounce:YES];
}

- (void)animateFallbackPopup
{
    [RMUAnimationClass animateFlyInView:self.fallbackPopup
                           withDuration:0.1f
                              withDelay:0.0f
                          fromDirection:buttonAnimationDirectionTop
                         withCompletion:Nil
                             withBounce:YES];
}
@end

