//
//  RMUAppDelegate.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/15/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUAppDelegate.h"

@implementation RMUAppDelegate

#pragma mark - Core Data Methods
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

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
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

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

#pragma mark - Launch options

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

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSError *saveError;
    if (![self.managedObjectContext save:&saveError])
        NSLog(@"Error Saving %@", saveError);

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
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
