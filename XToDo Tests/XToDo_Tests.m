//
//  XToDo_Tests.m
//  XToDo Tests
//
//  Created by Travis on 13-11-28.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XToDoModel.h"

@interface XToDo_Tests : XCTestCase

@end

@implementation XToDo_Tests

-(void)cases{
    //TODO: todo1
    //FIXME: fixme1
    //???: question1
    
    //TODO: content:today
}

- (void)testFind
{
    
    NSArray *items= [XToDoModel findItemsWithPath:[NSString stringWithUTF8String:__FILE__]];
    
    XCTAssertTrue(items.count>=4, @"count find enough todo items");
}

@end
