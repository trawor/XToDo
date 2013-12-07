//
//  main.m
//  XToDoApp
//
//  Created by Travis on 13-12-6.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XTAppDelegate.h"
int main(int argc, const char * argv[])
{
    XTAppDelegate * delegate = [[XTAppDelegate alloc] init];
    [[NSApplication sharedApplication] setDelegate:delegate];
    [NSApp run];
    return EXIT_SUCCESS;
}
