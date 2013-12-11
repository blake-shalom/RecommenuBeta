//
//  RMURestaurant.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/11/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMURestaurant.h"

@implementation RMURestaurant

-(id) initWithFoursquareID:(NSNumber *)foursquareID andRestaurantName:(NSString*) name
{
    self = [super init];
    if (self) {
        self.restName = name;
        self.menus = [[NSMutableArray alloc]init];
        AFHTTPRequestOperationManager * manager = [[AFHTTPRequestOperationManager alloc]init];
        [manager GET:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/%@/menu", foursquareID]
          parameters:@{@"VENUE_ID": foursquareID,
                       @"client_id" : [[NSUserDefaults standardUserDefaults] stringForKey:@"foursquareID"],
                       @"client_secret" : [[NSUserDefaults standardUserDefaults]stringForKey:@"foursquareSecret"],
                       @"v" : @20131017}
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 for (NSDictionary* menu in [[[responseObject objectForKey:@"menu"]objectForKey:@"menus"]objectForKey:@"items"]){
                     [self.menus addObject:[[RMUMenu alloc]initWithDictionary:menu]];
                 }
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 
             }];
    }
    return self;
}

//https://api.foursquare.com/v2/venues/4e4d0539bd413c4cc66e0b48/menu?format=JSON&VENUE_ID=4e4d0539bd413c4cc66e0b48&client_id=YZVWMVDV1AFEHQ5N5DX4KFLCSVPXEC1L0KUQI45NQTF3IPXT&client_secret=2GA3BI5S4Z10ONRUJRWA40OTYDED3LAGCUAXJDBBEUNR4JJN&v=20131017
@end


