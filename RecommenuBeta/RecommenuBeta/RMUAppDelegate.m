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

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark - Launch options

/*
 *  Called upon launching of the app, saves defaults sets up a user and adds some user properties
 */

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
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
        currentUser.dateLogged = [NSDate date];
        [self obtainUserURIForUser:currentUser];
    }
    else {
        // User has been created
        currentUser = fetchedArray[0];
        if (currentUser.hasLoggedIn) {
            // User was created and has logged in and obtained a user URI, do nothing
            NSLog(@"USER OBTAINED URI: %@", currentUser.userURI);
        }
        else {
            // User was created and has not logged in, attempt to log in and obtain a user ID
            [self obtainUserURIForUser:currentUser];
        }
    }
    
    return YES;
}

/*
 *  Attempts to log in and obtain a user URI for a given user by it's device id
 */

- (void)obtainUserURIForUser:(RMUSavedUser*)user
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *deviceId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    NSLog(@"%@",deviceId);
    
    // For now save all test fields as substrings of ID, length 10
    NSString *testFields = [deviceId substringToIndex:10];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
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

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

/*
 *  Saves state when entering background
 */

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    if (self.shouldDelegateNotifyUser) {
        // Notification needs to be set up
        UILocalNotification *notification = [[UILocalNotification alloc]init];
        [notification setAlertAction:@"rate"];
        [notification setAlertBody:@"Did you enjoy what you ordered?"];
        NSTimeInterval interval = SECS_IN_MIN * MINS_TIL_NOTIFICATION;
//        NSTimeInterval interval = 5;
        NSDate *fireDate = [[NSDate date]dateByAddingTimeInterval:interval];
        [notification setFireDate:fireDate];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    else {
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }
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
        [self.window makeKeyAndVisible];
        [self.window setRootViewController:rateViewController];
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

@end
