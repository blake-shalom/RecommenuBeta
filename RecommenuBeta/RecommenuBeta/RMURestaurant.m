//
//  RMURestaurant.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/11/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMURestaurant.h"

@interface RMURestaurant ()

@property AFHTTPRequestOperationManager *manager;

@end

@implementation RMURestaurant

/*
 *  Start of data structure, store the name of the restaurant and iterate of its menus initializing them
 */

-(id) initWithDictionary:(NSDictionary *)restaurantDictionary andRestaurantName:(NSString*) name
{
    self = [super init];
    if (self) {
        self.restName = name;
        self.menus = [[NSMutableArray alloc]init];
        for (NSDictionary* menu in [[[restaurantDictionary objectForKey:@"menu"]objectForKey:@"menus"]objectForKey:@"items"]){
            [self.menus addObject:[[RMUMenu alloc]initWithDictionary:menu]];
        }
    }
    return self;
}

@end




