//
//  RMUAppDelegate.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/15/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//


#define SECS_IN_MIN 60
#define MINS_TIL_NOTIFICATION 30

#import "RMUAppDelegate.h"

@implementation RMUAppDelegate

#pragma mark - Core Data Methods

/*
 *  Returns a managed object context for saving core data stuffz
 */

- (NSManagedObjectContext *) managedObjectContext {
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}

/*
 *  Retuns managed object model
 */

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}

/*
 *  Returns persistent store and handles migration from ollder object models
 */

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // if persistent exists return it
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
    // else make a new one or migrate a model
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory]
                                               stringByAppendingPathComponent: @"Recommenu.sqlite"]];
    NSError *error = nil;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel:[self managedObjectModel]];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES],      NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    if(![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil URL:storeUrl options:options error:&error]) {
        NSLog(@"ERROR PERSISTENT STORE WAS NOT CREATED PROPERLY: %@", error);
        abort();
    }
    
    return persistentStoreCoordinator;
}

/*
 *  App doc directory, used in core data methods
 */

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark - Launch options

/*
 *  Called upon launching of the app, saves defaults sets up a user and adds some user properties
 */

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    [self logAvailableFontNames]; // UNCOMMENT TO LOG FONT NAMES
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
    [GAI sharedInstance].dispatchInterval = 30;
    
    // Optional: set Logger to VERBOSE for debug information.
    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker, and suppress that stupid warning.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-47533709-2"];
#pragma unused(tracker)

    // Google maps registration of API key
    [GMSServices provideAPIKey:@"AIzaSyB6XNhzk84c2OvaphAorLIMhFV6xFH7Epk"];
    
    // Save some user defaults for Foursquare
    NSString *idString = @"YZVWMVDV1AFEHQ5N5DX4KFLCSVPXEC1L0KUQI45NQTF3IPXT";
    NSString *secretString = @"2GA3BI5S4Z10ONRUJRWA40OTYDED3LAGCUAXJDBBEUNR4JJN";
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    [currentDefaults setObject:idString forKey:@"foursquareID"];
    [currentDefaults setObject:secretString forKey:@"foursquareSecret"];
    
    // Set up a user on Recommenu
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RMUSavedUser" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSError *error;
    NSArray *fetchedArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    RMUSavedUser *currentUser;
    if (fetchedArray.count == 0){
        // User hasn't been created, create a user and attempt to extract a URI from the RMU DB
        currentUser = (RMUSavedUser*) [NSEntityDescription insertNewObjectForEntityForName:@"RMUSavedUser"
                                                                    inManagedObjectContext:self.managedObjectContext];
        currentUser.hasLoggedIn = NO;
        currentUser.hasThirdPopup = NO;
        currentUser.hasSecondPopup = NO;
        currentUser.hasfirstPopup = NO;
        currentUser.hasFourthPopup = NO;
        currentUser.dateLogged = [NSDate date];
        currentUser.isFoodie = NO;
        [self obtainUserURIForUser:currentUser];
    }
    else {
        // User has been created
        currentUser = fetchedArray[0];
        if (currentUser.hasLoggedIn) {
            // User was created and has logged in and obtained a user URI, do nothing but possibly refresh fb
            NSLog(@"USER OBTAINED URI: %@", currentUser.userURI);
            NSRange range;
            range.length = 1;
            range.location = 6;
            NSString *trimString = [currentUser.userURI stringByReplacingCharactersInRange:range withString:@""];
            NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            int value = [[trimString stringByTrimmingCharactersInSet:nonDigits] intValue];
            currentUser.userID = [NSNumber numberWithInt:value];
            
        }
        else {
            // User was created and has not logged in, attempt to log in and obtain a user ID
            [self obtainUserURIForUser:currentUser];
        }
        
    }
    NSError *saveError;
    if (![self.managedObjectContext save:&saveError])
        NSLog(@"Error Saving %@", saveError);
    [self handleInitialFacebookLoginWithUser:currentUser];
    return YES;
}


/*
 *  Handles the initial login of facebook and sets if the user has logged in and has an
 */

- (void)handleInitialFacebookLoginWithUser:(RMUSavedUser*)currentUser
{
    // Whenever a person opens the app, check for a cached session
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
        
        // If there's one, just open the session silently, without showing the user the login UI
        [FBSession openActiveSessionWithReadPermissions:@[@"basic_info"]
                                           allowLoginUI:NO
                                      completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                          // Handler for session state changes
                                          if (!error)
                                              [self sessionStateChanged:session state:state error:error];
                                              // This method will be called EACH time the session state changes,
                                              // also for intermediate states and NOT just when the session open
                                          // Else facebook error, no biggie
                                          else
                                              NSLog(@"FACEBOOK ERROR: %@", error);
                                      }];
    }
    else {
        // ELSE no facebook cached session, USER needs to login
        NSLog(@"NO FB SESSION FOUND");
        self.shouldUserLoginFacebook = YES;
    }
}
/*
 *  Handles State changes on FB
 */

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error
{
    // If the session was opened successfully
    if (!error && state == FBSessionStateOpen){
        NSLog(@"Session opened");
        self.shouldUserLoginFacebook = NO;
        return;
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
        // If the session is closed
        NSLog(@"Session closed");
        self.shouldUserLoginFacebook = YES;
    }
    
    // Handle errors
    if (error){
        NSLog(@"Error");
        NSString *alertText;
        NSString *alertTitle;
        // If the error requires people using an app to make an action outside of the app in order to recover
        if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
            alertTitle = @"Something went wrong";
            alertText = [FBErrorUtility userMessageForError:error];
            [self showMessage:alertText withTitle:alertTitle];
        } else {
            
            // If the user cancelled login, do nothing
            if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                NSLog(@"User cancelled login");
                
                // Handle session closures that happen outside of the app
            } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                alertTitle = @"Facebook Error";
                alertText = @"Your current session is no longer valid. Please log in again.";
                [self showMessage:alertText withTitle:alertTitle];
                self.shouldUserLoginFacebook = YES;
                
                // For simplicity, here we just show a generic message for all other errors
                // You can learn how to handle other errors using our guide: https://developers.facebook.com/docs/ios/errors
            } else {
                //Get more error information from the error
                NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                
                // Show the user an error message
                alertTitle = @"Something went wrong";
                alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                [self showMessage:alertText withTitle:alertTitle];
                self.shouldUserLoginFacebook = YES;

            }
        }
        // Clear this token
        [FBSession.activeSession closeAndClearTokenInformation];
        // Show the user the logged-out UI
    }
}


/*
 *  Using a user's username get an error message that states if the user needs to login with params
 */

- (void)obtainUserURIForUser:(RMUSavedUser*)user
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *deviceId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    NSLog(@"%@",deviceId);
    
    // For now save all test fields as substrings of ID, length 10
    NSString *testFields = [deviceId substringToIndex:10];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager GET:[NSString stringWithFormat:(@"http://glacial-ravine-3577.herokuapp.com/data/users/%@"),testFields]
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"response: %@", responseObject);
             if ([[responseObject objectForKey:@"error"] isEqualToString:@"dne"])
                 [self registerUser:user];
             else {
                 [user setUserURI:[responseObject objectForKey:@"resource_uri"]];
                 NSRange range;
                 range.length = 1;
                 range.location = 6;
                 NSString *trimString = [user.userURI stringByReplacingCharactersInRange:range withString:@""];
                 NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
                 int value = [[trimString stringByTrimmingCharactersInSet:nonDigits] intValue];
                 user.userID = [NSNumber numberWithInt:value];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Error establishing user, just silently try again next login
             NSLog(@"ERROR: %@", error);
         }];
}


/*
 *  Attempts to log in and obtain a user URI for a given user by it's device id
 */

- (void)registerUser:(RMUSavedUser*)user
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *deviceId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    NSLog(@"%@",deviceId);
    
    // For now save all test fields as substrings of ID, length 10
    NSString *testFields = [deviceId substringToIndex:10];
    user.userName = testFields;
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:@"ApiKey recommenumaster:5767146e19ab6cbcf843ad3ab162dc59e428156a"
                     forHTTPHeaderField:@"Authorization"];
    [manager POST:@"http://glacial-ravine-3577.herokuapp.com/api/v1/create_user/"
      parameters:@{@"device_id": deviceId,
                   @"user" : @{@"email" : testFields,
                               @"username" : testFields,
                               @"first_name" : testFields,
                               @"last_name" : testFields,
                               @"password" : testFields}}
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             // Succeeded, save the URI to the user object
             user.userURI = [[responseObject objectForKey:@"user"] objectForKey:@"resource_uri"];
             NSLog(@"response : %@", responseObject);
             NSError *saveError;
             user.hasLoggedIn = [NSNumber numberWithBool:YES];
             NSRange range;
             range.length = 1;
             range.location = 6;
             NSString *trimString = [user.userURI stringByReplacingCharactersInRange:range withString:@""];
             NSCharacterSet* nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
             int value = [[trimString stringByTrimmingCharactersInSet:nonDigits] intValue];
             user.userID = [NSNumber numberWithInt:value];
             if (![self.managedObjectContext save:&saveError])
                 NSLog(@"Error Saving %@", saveError);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Failed. Save the User Regardless
             NSLog(@"error: %@ with response string: %@", error, operation.responseString);
             NSError *saveError;
             if (![self.managedObjectContext save:&saveError])
                 NSLog(@"Error Saving %@", saveError);
         }];
}

/* 
 * Show an alert message
 */
- (void)showMessage:(NSString *)text withTitle:(NSString *)title
{
    [[[UIAlertView alloc] initWithTitle:title
                                message:text
                               delegate:self
                      cancelButtonTitle:@"OK!"
                      otherButtonTitles:nil] show];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

/*
 *  Saves state and updates notifications when entering background
 */

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //If the user needs to bet notified with time that they need to rate
    if (self.shouldDelegateNotifyUser) {
        // Notification needs to be set up
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        [notification setAlertAction:@"rate"];
        [notification setAlertBody:@"Did you enjoy what you ordered?"];
        NSTimeInterval interval = SECS_IN_MIN * MINS_TIL_NOTIFICATION;
        NSDate *fireDate = [[NSDate date]dateByAddingTimeInterval:interval];
        [notification setFireDate:fireDate];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
    // Regardless save state and turn off location services
    NSError *saveError;
    if (![self.managedObjectContext save:&saveError])
        NSLog(@"Error Saving %@", saveError);
    
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // If notified user, present rate VC
    if (self.shouldDelegateNotifyUser) {
        UIStoryboard *mainstoryboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        RMURevealViewController *rateViewController = [mainstoryboard instantiateViewControllerWithIdentifier:@"RateRevealViewController"];
        NSLog(@"Current Restaurant name: %@, and ID %@", self.savedRestaurant.restName, self.savedRestaurant.restFoursquareID);
        rateViewController.currentRestaurant = self.savedRestaurant;
        [self.vc.navigationController pushViewController:rateViewController animated:YES];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - returner dudes

/*
 *  Returns the current user saved
 */

- (RMUSavedUser*)fetchCurrentUser
{
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RMUSavedUser" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSError *error;
    NSArray *fetchedArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    return (RMUSavedUser*) fetchedArray[0];
}

/*
 *  Return the username aka the device id
 */

- (NSString*)returnDeviceID
{
    NSString *deviceId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    // For now save all test fields as substrings of ID, length 10
    return [deviceId substringToIndex:10];

}

/*
 *  Logs available font names for testing
 */

-(void)logAvailableFontNames{
    
    //------- testing only -------------
    //print available fonts
    NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
    NSArray *fontNames;
    NSInteger indFamily, indFont;
    for (indFamily=0; indFamily<[familyNames count]; ++indFamily)
    {
        NSLog(@"Family name: %@", [familyNames objectAtIndex:indFamily]);
        fontNames = [[NSArray alloc] initWithArray:
                     [UIFont fontNamesForFamilyName:
                      [familyNames objectAtIndex:indFamily]]];
        for (indFont=0; indFont<[fontNames count]; ++indFont)
        {
            NSLog(@"    Font name: %@", [fontNames objectAtIndex:indFont]);
        }
    }
    //------ testing only --------------
}

/*
 *  Walls off our users to only Austin and Boston, currently disabled for testing by Apple
 */

+(BOOL)isInValidLocationWithCoordinate:(CLLocationCoordinate2D)coord
{
//    BOOL isValidinAustin = (abs(coord.latitude - 30.2669444) <= 0.5 && abs(coord.longitude - -97.7427778 <= 0.5));
//    BOOL isValidinBoston = (abs(coord.latitude - 42.3583333) <= 0.5 && abs(coord.longitude - -71.0602778 <= 0.5));
//    return (isValidinAustin || isValidinBoston);
    // Returns yes for testing by Apple :)
    return YES;
}

@end
