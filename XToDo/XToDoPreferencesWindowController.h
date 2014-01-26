//
//  XToDoPreferencesWindowController.h
//  XToDo
//
//  Created by Georg Kaindl on 25/01/14.
//  Copyright (c) 2014 Plumn LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


extern NSString* const kXToDoTextSizePrefsKey;
extern NSString* const kXToDoTagsKey;

typedef NS_ENUM(NSInteger, XToDoTextSize) {
    kXToDoTextSizeLarge         = 0,
    kXToDoTextSizeSmall         = 1
};

@interface XToDoPreferencesWindowController : NSWindowController

@end
