//
//  RMUSavedUser.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 1/2/14.
//  Copyright (c) 2014 Blake Ellingham. All rights reserved.
//
//  Saved user model

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class RMUSavedRecommendation;
@class RMUSavedUserPhoto;

@interface RMUSavedUser : NSManagedObject

@property (nonatomic, retain) NSNumber * hasfirstPopup;
@property (nonatomic, retain) NSNumber * hasSecondPopup;
@property (nonatomic, retain) NSNumber * hasThirdPopup;
@property (nonatomic, retain) NSNumber * hasFourthPopup;
@property (nonatomic, retain) NSNumber * hasLoggedIn;
@property (nonatomic, retain) NSNumber * userID;
@property (nonatomic, retain) NSString * userURI;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * facebookID;
@property (nonatomic, retain) NSString * foodieID;
@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSDate * dateLogged;
@property (nonatomic, retain) NSSet *ratingsForUser;
@property (nonatomic, retain) NSNumber * isFoodie;
@property (nonatomic, retain) NSString * userName;
@property (nonatomic, retain) RMUSavedUserPhoto * savedPhotoForUser;

@end

@interface RMUSavedUser (CoreDataGeneratedAccessors)

- (void)addRatingsForUserObject:(RMUSavedRecommendation *)value;
- (void)removeRatingsForUserObject:(RMUSavedRecommendation *)value;
- (void)addRatingsForUser:(NSSet *)values;
- (void)removeRatingsForUser:(NSSet *)values;

@end
