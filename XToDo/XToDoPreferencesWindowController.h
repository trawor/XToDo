//
//  XToDoPreferencesWindowController.h
//  XToDo
//
//  Created by Georg Kaindl on 25/01/14.
//  Copyright (c) 2014 Plumn LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, XToDoTextSize) {
    kXToDoTextSizeLarge = 0,
    kXToDoTextSizeSmall = 1
};

@interface XToDoPreferencesWindowController : NSWindowController <NSPopoverDelegate>
@property (copy) NSString* searchRootDir;
@property (copy) NSString* projectName;
@end
