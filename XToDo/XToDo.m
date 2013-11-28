//
//  XToDo.m
//  XToDo
//
//  Created by Travis on 13-11-28.
//    Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDo.h"
#import "XToDoModel.h"

static XToDo *sharedPlugin;

@interface XToDo()
@property (nonatomic, strong) NSPanel *panel;
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


-(void)refresh{
    NSString *projectPath= [[[XToDoModel currentWorkspaceDocument].workspace.representingFilePath.fileURL absoluteString] stringByDeletingLastPathComponent];
    
    NSArray *items=[XToDoModel findItemsWithPath:projectPath];
    
    
    IDEWorkspaceTabController *tab= [XToDoModel tabController];
    
    
    DVTChoice *choice=[[DVTChoice alloc] initWithTitle:@"ToDo" toolTip:@"Show the ToDo Nav" image:[[NSImage alloc] initWithContentsOfFile:[self.bundle pathForImageResource:@"todoIcon.png"]] representedObject:nil];
    
    NSArrayController *ac=tab.navigatorArea.extensionsController;
    [ac addObject:choice];
    
    
    for (NSObject *obj in tab.navigatorArea.extensionsController.content) {
        NSLog([obj description]);
    }
    
}

- (void)doMenuAction
{
    if (self.panel==nil) {
        self.panel=[[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 320, 568) styleMask:2 backing:NSBackingStoreNonretained defer:YES];
        [self.panel setTitle:@"ToDo List"];
        [self.panel setHasShadow:YES];
        [self.panel setCanHide:YES];
    }
    
    [self refresh];
    
    [self.panel makeKeyAndOrderFront:nil];
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
