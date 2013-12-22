//
//  RMUMeal.h
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/10/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RMUMeal : NSObject

@property NSString *mealID;
@property NSString *mealName;
@property NSString *mealDescription;
@property NSString *mealPrice;
@property NSNumber *crowdLikes;
@property NSNumber *crowdDislikes;
@property NSNumber *friendLikes;
@property NSNumber *expertLikes;

- (id)initWithDictionary:(NSDictionary*) mealDictionary;

@end