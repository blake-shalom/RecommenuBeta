//
//  RMUAppDelegate.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 11/15/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import <GoogleMaps/GoogleMaps.h>

#import "AFNetworking.h"
#import "RMUSavedUser.h"
#import "RMURevealViewController.h"
#import "GAI.h"

@interface RMUAppDelegate : UIResponder <UIApplicationDelegate>{
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
}

@property (strong, nonatomic) UIWindow *window;

// Core Data Jazz
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

// Push notification properties
@property BOOL shouldDelegateNotifyUser;
@property BOOL shouldUserLoginFacebook;
@property RMURestaurant *savedRestaurant;
@property FBSession *session;

// Used to save across multiple files
- (NSManagedObjectContext *) managedObjectContext;

// Handles changed state of FB
- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState) state error:(NSError *)error;
- (RMUSavedUser*)fetchCurrentUser;
- (NSString*)returnDeviceID;
- (void)showMessage:(NSString *)text withTitle:(NSString *)title;

+(BOOL)isInValidLocationWithCoordinate:(CLLocationCoordinate2D)coord;

@end
