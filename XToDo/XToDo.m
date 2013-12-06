//
//  XToDo.m
//  XToDo
//
//  Created by Travis on 13-11-28.
//    Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDo.h"
#import "XToDoModel.h"
#import "XToDoWindowController.h"

static XToDo *sharedPlugin;

@interface XToDo()
@property (nonatomic, strong) XToDoWindowController *windowController;
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation XToDo

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    NSLog(@"Plugin Load:%@",[plugin description]);
    
    static id sharedPlugin = nil;
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (sharedPlugin==nil && [currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[self alloc] initWithBundle:plugin];
        });
    }
    
    
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)doMenuAction
{
    if (self.windowController==nil) {
        XToDoWindowController *wc=[[XToDoWindowController alloc] initWithWindowNibName:@"XToDoWindowController"];
        self.windowController=wc;
    }
    
    NSString *projectPath= [[[XToDoModel currentWorkspaceDocument].workspace.representingFilePath.fileURL absoluteString] stringByDeletingLastPathComponent];
    self.windowController.projectPath=projectPath;
    [self.windowController.window makeKeyAndOrderFront:nil];
}

- (id)initWithBundle:(NSBundle *)plugin {
    self = [super init];
    if (self) {
        self.bundle = plugin;
        
        
        
        
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"ToDo List"
                                                                    action:@selector(doMenuAction) keyEquivalent:@""];
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
        }
    }
    return self;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    
        return YES;
}
@end
