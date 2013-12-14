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

static XToDo* sharedPlugin=nil;

@interface XToDo()
@property (nonatomic, strong) XToDoWindowController *windowController;
@property (nonatomic, strong) NSBundle *bundle;
@end

@implementation XToDo

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (sharedPlugin==nil && [currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin=[[self alloc] initWithBundle:plugin];
        });
    }
}


- (id)initWithBundle:(NSBundle *)plugin {
    self = [super init];
    if (self) {
        self.bundle = plugin;
        
        //insert a menuItem to MainMenu "Window"
        NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
            
            NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"ToDo List"
                                                                    action:@selector(toggleList)
                                                             keyEquivalent:@"t"];
            
            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];
            
            
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
            
            //TODO: support snippets to add TODO
            
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"ToDo Snippet"
                                                         action:@selector(insertToDo)
                                                  keyEquivalent:@"t"];
            
            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask|NSShiftKeyMask];
            
            
            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];
        }
    }
    return self;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    return [XToDoModel currentWorkspaceDocument].workspace!=nil;
}

#pragma mark ment actions
#pragma mark -
- (void)toggleList
{
    //toggle the todo list window
    if (self.windowController.window.isVisible) {
        [self.windowController.window close];
    }else{
        if (self.windowController==nil) {
            XToDoWindowController *wc=[[XToDoWindowController alloc] initWithWindowNibName:@"XToDoWindowController"];
            self.windowController=wc;
            self.windowController.window.title= [[XToDoModel currentWorkspaceDocument].displayName stringByDeletingLastPathComponent];
        }
        
        NSString *projectPath= [[[XToDoModel currentWorkspaceDocument].workspace.representingFilePath.fileURL
                                 path]
                                stringByDeletingLastPathComponent];
        
        //!!!: how about the path is nil?
        self.windowController.projectPath=projectPath;
        [self.windowController.window makeKeyAndOrderFront:nil];
        
        [self.windowController refresh:nil];
    }
    
}

-(void)insertToDo{
    NSString *cmt=[NSString stringWithFormat:@"//%@: ",@"TODO"];
    [self insertComment:cmt];
}

-(void)insertComment:(NSString*)cmt{
    IDESourceCodeEditor *editor=[XToDoModel currentEditor];
    NSTextView *textView=editor.textView;
    if (textView) {
        [textView insertText:cmt];
    }
}

@end
