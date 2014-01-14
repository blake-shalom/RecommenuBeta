//
//  RMUCourse.m
//  RecommenuBeta
//
//  Created by Blake Ellingham on 12/10/13.
//  Copyright (c) 2013 Blake Ellingham. All rights reserved.
//

#import "RMUCourse.h"

@implementation RMUCourse

/*
 *  Called through the RMUMenu, set's properties and then iterates through the courses initializing each one
 */

- (id)initWithDictionary:(NSDictionary*) course
{
    self = [super init];
    if (self) {
        self.courseName = [course objectForKey:@"name"];
        self.meals = [[NSMutableArray alloc]init];
        for (NSDictionary* meal in [[course objectForKey:@"entries"] objectForKey:@"items"]) {
            [self.meals addObject:[[RMUMeal alloc]initWithDictionary:meal]];
        }
    }
    return self;
}

@end
