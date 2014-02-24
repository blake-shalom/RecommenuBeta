//
//  RMULocateScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//
#define NUMBER_OF_FALLBACK 15

#define LOCAL_QUEUE dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#import "RMULocateScreen.h"


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
@property (weak, nonatomic) IBOutlet UIView *loadingFallbackView;

// Regular properties
@property (strong,nonatomic) NSMutableArray *fallbackRest;
@property (strong, nonatomic) RMMapView *mapView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;
@property (strong,nonatomic) NSString *restID;
@property (strong,nonatomic) NSString *restString;
@property BOOL hasDroppedPin;

@end

@implementation RMULocateScreen {
    GMSMapView *mapView_;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    self.screenName = @"Locate Screen";
    [super viewDidAppear:animated];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // hide loading screen
    [self.loadingFallbackView setHidden:YES];
    
    dispatch_async(LOCAL_QUEUE, ^
                   {
                       [self performSelectorOnMainThread:@selector(loadMapElements) withObject:nil waitUntilDone:YES];
                   });
	// Do any additional setup after loading the view.
}

- (void)loadMapElements
{
    self.hasDroppedPin =NO;
    self.fallbackRest = [[NSMutableArray alloc]init];
    
    // Deactivate dismiss button
    [self.dismissButton setUserInteractionEnabled:NO];
    
    // Hide yo wife
    [self.popupView setHidden:YES];
    [self.gradientImage setHidden:YES];
    
    // Configure the Google Map
    GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:-33.86
                                                            longitude:151.20
                                                                 zoom:8];
    mapView_ = [GMSMapView mapWithFrame:self.mapFrameView.bounds camera:camera];
    [self.view addSubview:mapView_];
    [self.view sendSubviewToBack:mapView_];

    
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
    
    // Check if the coordinate is in the correct place else POPUP SOME SHIte
    
//    if ([RMUAppDelegate isInValidLocationWithCoordinate:coord]) {
    if (YES) {
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:coord.latitude
                                                                longitude:coord.longitude
                                                                     zoom:16];
        [mapView_ animateToCameraPosition:camera];
        
        
        // Drop a pin
        if (!self.hasDroppedPin){
            self.hasDroppedPin = YES;
            GMSMarker *marker = [[GMSMarker alloc] init];
            marker.position = coord;
            marker.map = mapView_;
            
        }
        [self findRestaurantWithRadius:10.0f];
    }
    else {
        UIAlertView *newAlert = [[UIAlertView alloc] initWithTitle:@"Not available yet!"
                                                           message:@"Click to request Recommenu in your city and invite your friends to do the same. Once we hit 10,000 requests, we'll launch in your city!"
                                                          delegate:self
                                                 cancelButtonTitle:@"Request!"
                                                  otherButtonTitles: nil];
        newAlert.tag = 1;
        [newAlert show];
    }
}

/*
 *  If location manager is off be sure to tell the user
 */

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied){
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"No Location Services"
                                                      message:@"Sorry, the locate feature requires location services please adjust these in your iPhone's Settings < Privacy < Location Services"
                                                     delegate:self cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
        [alertView show];
    }
}

#pragma mark - UIAlertViewDelegate

/*
 *  Click at the button to request to your city
 */

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag ==1) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        [manager.requestSerializer setValue:@"ApiKey recommenumaster:5767146e19ab6cbcf843ad3ab162dc59e428156a"
                         forHTTPHeaderField:@"Authorization"];

        [manager POST:@"http://glacial-ravine-3577.herokuapp.com/api/v1/requestedcity/"
           parameters:@{@"longitude": [NSString stringWithFormat:(@"long: %@"),[NSNumber numberWithDouble:self.location.coordinate.longitude]],
                        @"latitude" : [NSString stringWithFormat:(@"lat: %@"),[NSNumber numberWithDouble:self.location.coordinate.latitude]]}
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  NSLog(@"SUCCESS POSTING REQUEST CITY WITH RESPONSE : %@", responseObject);
              }
              failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  NSLog(@"ROYAL FAIL BRAH with error : %@ and response string : %@", error, operation.responseString);
              }];
    }
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
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate showMessage:@"Please try again" withTitle:@"Server Error!"];
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
                 [self.loadingFallbackView setHidden:YES];
                 [self animateFallbackPopup];
                 [self.fallbackTable reloadData];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"error: %@", error);
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate showMessage:@"Please try again." withTitle:@"Server Error!"];

             [self.loadingFallbackView setHidden:YES];
         }];
}


#pragma mark - Interactivity Methods

/*
 *  Allows a user to reload process should they pick the wrong restaurant
 */

- (IBAction)dismissPopups:(id)sender
{
    self.hasDroppedPin = NO;
    [mapView_ clear];
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
    [self.loadingFallbackView setHidden:NO];
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
        nextScreen.hidesBottomBarWhenPushed = YES;
        RMUAppDelegate *delegate = (RMUAppDelegate*) [UIApplication sharedApplication].delegate;
        delegate.shouldDelegateNotifyUser = YES;

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

