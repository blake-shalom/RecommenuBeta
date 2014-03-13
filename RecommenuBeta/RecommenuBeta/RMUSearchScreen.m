//
//  RMUSearchScreen.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/29/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUSearchScreen.h"

@interface RMUSearchScreen ()

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIButton *stopEditingButton;
@property (weak, nonatomic) IBOutlet UITableView *searchResultsTable;
@property (weak, nonatomic) IBOutlet UILabel *boldLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UILabel *underBoldLabel;

// Location jazz
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *location;

@property (strong, nonatomic) NSMutableArray *searchResultsArray;
@property (strong,nonatomic) NSString *restID;
@property (strong,nonatomic) NSString *restString;

@end

@implementation RMUSearchScreen

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
    [self.view sendSubviewToBack:self.stopEditingButton];
    [self.searchResultsTable setHidden:YES];
    
    self.locationManager = [[CLLocationManager alloc]init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.location = [[CLLocation alloc]init];
    [self.locationManager startUpdatingLocation];

    self.searchBar.barTintColor = [UIColor clearColor];
    self.searchResultsArray = [[NSMutableArray alloc]init];
    
    self.restID = [[NSString alloc]init];
    self.restString = [[NSString alloc]init];
    
    [self.indicator setHidden:YES];
    [self.indicator stopAnimating];
    
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    self.screenName = @"Search Screen";
    [super viewDidAppear:animated];
    [self.boldLabel setText:@"Explore Recommenu"];
    [self.underBoldLabel setText:@"Search a restaurant to find it's menu!"];
    [self.locationManager startUpdatingLocation];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Search Bar Delegate

/*
 *  Began editing, bring button to the front
 */

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [self.view bringSubviewToFront:self.stopEditingButton];
}

/*
 *  Ended editing send button backwards
 */

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    [self.view sendSubviewToBack:self.stopEditingButton];
}

/*
 *  Upon the click of the "Search" start the location manager and get a relative location
 */

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    // Resign first responder and roll the indicator
    [self.searchBar resignFirstResponder];
    [self.indicator setHidden:NO];
    [self.indicator startAnimating];
    [searchBar setUserInteractionEnabled:NO];
    
    CLLocationCoordinate2D coord = self.location.coordinate;
    [self.searchResultsArray removeAllObjects];
    NSString *latLongString = [NSString stringWithFormat:@"%f,%f", coord.latitude, coord.longitude];
    NSDictionary *paramDic = @{@"ll" : latLongString,
                               @"limit": @15,
                               @"radius" : @24800,
                               @"intent" : @"browse",
                               @"query" : searchBar.text,
                               @"categoryId" : @"4d4b7105d754a06374d81259",
                               @"client_id" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareID"],
                               @"client_secret" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareSecret"],
                               @"v" : @20140225
                               };
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"https://api.foursquare.com/v2/venues/search"
      parameters:paramDic
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"RESPONSE OBJECT: %@", responseObject);
             NSArray *respArray = [[responseObject objectForKey:@"response"] objectForKey:@"venues"];
             if (respArray.count > 0){
                 for (NSDictionary * dict in respArray){
                     [self.searchResultsArray addObject:dict];
                 }
                 [self.searchResultsTable reloadData];
                 [self.searchResultsTable setHidden:NO];
             }
             else {
                 [self.boldLabel setText:@"No results found!"];
                 [self.underBoldLabel setText:@""];
                 [self.searchResultsTable setHidden:YES];
             }
             [self.indicator setHidden:YES];
             [self.indicator stopAnimating];
             [searchBar setUserInteractionEnabled:YES];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"ERRROR : %@", error);
             RMUAppDelegate *delegate = [UIApplication sharedApplication].delegate;
             [delegate showMessage:@"Please try again!" withTitle:@"Error in searching for a restaurant!"];
             [searchBar setUserInteractionEnabled:YES];
         }];
}

#pragma mark - Location 

/*
 *  Override location with first location when location updates
 */

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    self.location = locations[0];
    
    if (![RMUAppDelegate isInValidLocationWithCoordinate:self.location.coordinate]) {
        [manager stopUpdatingLocation];
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
 *  If the location manager fails because of auth, tell user
 */

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied){
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"No Location Services"
                                                           message:@"Sorry, the search feature requires location services please adjust these in your iPhone's Settings < Privacy < Location Services"
                                                          delegate:self cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil];
        [alertView show];
    }
}


#pragma mark - Interactivity

/*
 *  Stop editing button clicked, stop editing
 */

- (IBAction)stopEditing:(id)sender
{
    [self.searchBar resignFirstResponder];
}

#pragma mark - Table View

/*
 *  CELL FOR ROW BECHEZ, cells are rather boring
 */

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"sCell";
    RMUSearchCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (cell == nil) {
        cell = [[RMUSearchCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [cell.resultLabel setText:[self.searchResultsArray[[indexPath row]] objectForKey:@"name"]];
    [cell.addressLabel setText:[[self.searchResultsArray[[indexPath row]] objectForKey:@"location"] objectForKey:@"address"]];

    return cell;
}

/*
 *  Number of cells in the results
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.searchResultsArray.count;
}

/*
 *  Selected row instigates segue
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@", [self.searchResultsArray[[indexPath row]] objectForKey:@"id"]);
    NSDictionary *selRest = self.searchResultsArray[indexPath.row];
    self.restID = [selRest objectForKey:@"id"];
    self.restString = [selRest objectForKey:@"name"];
    [self performSegueWithIdentifier:@"searchToMenu" sender:self];
}

#pragma mark - Segue Methods

/*
 *  Sets up the segue unto the REVEAL controller
 */

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"searchToMenu"]) {
        RMURevealViewController *nextScreen = (RMURevealViewController*) segue.destinationViewController;
        nextScreen.hidesBottomBarWhenPushed = YES;
        [nextScreen getRestaurantWithFoursquareID:self.restID andName:self.restString];
    }
    else {
        NSLog(@"ERROR: UNKNOWN SEGUE %@", segue.identifier);
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

@end
