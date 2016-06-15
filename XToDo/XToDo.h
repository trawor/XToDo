//
//  XToDo.h
//  XToDo
//
//  Created by Travis on 13-11-28.
//  Copyright (c) 2013 fir.im  All rights reserved.
//

#import <AppKit/AppKit.h>

@class XToDoItem;

@interface XToDo : NSObject

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, strong) XToDoItem *item;

+ (instancetype)sharedPlugin;

@end