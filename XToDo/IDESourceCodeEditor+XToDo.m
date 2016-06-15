//
//  IDESourceCodeEditor+XToDo.m
//  XToDo
//
//  Created by Jobs on 16/6/15.
//  Copyright © 2016年 fir.im. All rights reserved.
//

#import "IDESourceCodeEditor+XToDo.h"
#import "XToDoModel.h"
#import "XToDo.h"
#import <objc/runtime.h>


@implementation IDESourceCodeEditor (XToDo)

+ (void)xtodo_hook
{
    [self swizzleSelector:@selector(didSetupEditor)
             withSelector:@selector(xtodo_didSetupEditor)];
}

+ (void)swizzleSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector
{
    Class class = [self class];

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));

    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)xtodo_didSetupEditor
{
    [self xtodo_didSetupEditor];

    // After the editor finished setup.
    XToDoItem *item = [XToDo sharedPlugin].item;
    if (item) {
        [XToDoModel highlightItem:item inTextView:self.textView];
    }
}

@end
