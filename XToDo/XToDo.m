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

XToDo* sharedPlugin = nil;

@interface XToDo ()
@property (nonatomic, strong) XToDoWindowController* windowController;
@end

@implementation XToDo

+ (void)pluginDidLoad:(NSBundle*)plugin
{
    static dispatch_once_t onceToken;

    NSString* currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if (sharedPlugin == nil && [currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin=[[self alloc] initWithBundle:plugin];
        });
    }
}

- (id)initWithBundle:(NSBundle*)plugin
{
    self = [super init];
    if (self) {
        self.bundle = plugin;

        //insert a menuItem to MainMenu "Window"
        NSMenuItem* menuItem = [[NSApp mainMenu] itemWithTitle:@"View"];
        if (menuItem) {
            [[menuItem submenu] addItem:[NSMenuItem separatorItem]];

            NSMenuItem* actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"ToDo List"
                                                                    action:@selector(toggleList)
                                                             keyEquivalent:@"t"];

            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask];

            [actionMenuItem setTarget:self];
            [[menuItem submenu] addItem:actionMenuItem];

            //add Snippet Group
            NSMenu* submenu = [[NSMenu alloc] init];

            NSMenuItem* mainItem = [[NSMenuItem alloc] init];
            [mainItem setTitle:@"Snippets"];

            [mainItem setSubmenu:submenu];
            [[menuItem submenu] addItem:mainItem];

            //support snippets to add TODO
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"TODO"
                                                        action:@selector(insertToDo)
                                                 keyEquivalent:@"t"];

            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSShiftKeyMask];

            [actionMenuItem setTarget:self];
            [submenu addItem:actionMenuItem];

            //support snippets to add FIXME
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"FIXME"
                                                        action:@selector(insertFixMe)
                                                 keyEquivalent:@"x"];

            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSShiftKeyMask];

            [actionMenuItem setTarget:self];
            [submenu addItem:actionMenuItem];

            //support snippets to add !!!
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"!!!"
                                                        action:@selector(insertWarn)
                                                 keyEquivalent:@"1"];

            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSShiftKeyMask];

            [actionMenuItem setTarget:self];
            [submenu addItem:actionMenuItem];

            //support snippets to add ???
            actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"???"
                                                        action:@selector(insertAsk)
                                                 keyEquivalent:@"q"];

            [actionMenuItem setKeyEquivalentModifierMask:NSControlKeyMask | NSShiftKeyMask];

            [actionMenuItem setTarget:self];
            [submenu addItem:actionMenuItem];
        }
    }
    return self;
}

- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    return [XToDoModel currentWorkspaceDocument].workspace != nil;
}

#pragma mark - ment actions
- (void)toggleList
{
    //toggle the todo list window
    if (self.windowController.window.isVisible) {
        [self.windowController.window close];
    } else {
        if (self.windowController == nil) {
            XToDoWindowController* wc = [[XToDoWindowController alloc] initWithWindowNibName:@"XToDoWindowController"];
            self.windowController = wc;
        }

        NSString* filePath = [[XToDoModel currentWorkspaceDocument].workspace.representingFilePath.fileURL path];
        NSString* projectDir = [filePath stringByDeletingLastPathComponent];
        NSString* projectName = [filePath lastPathComponent];
        {
            // register them as soon as possible
            NSUserDefaults* prefs = [NSUserDefaults standardUserDefaults];
            [prefs registerDefaults:@{
                kXToDoTextSizePrefsKey : @(0),
                kXToDoTagsKey : @[ @"TODO", @"FIXME", @"???", @"!!!" ],
            }];
        }
        [XToDoModel cleanAllTempFiles];

        self.windowController.window.title = [[XToDoModel currentWorkspaceDocument].displayName stringByDeletingLastPathComponent];
        //!!!: how about the path is nil?
        [self.windowController setSearchRootDir:projectDir projectName:projectName];
        [self.windowController.window makeKeyAndOrderFront:nil];
        [self.windowController refresh:nil];
    }
}

- (void)insertToDo
{
    NSString* cmt = [NSString stringWithFormat:@"//%@:", @"TODO"];
    [self insertComment:cmt];
}
- (void)insertFixMe
{
    NSString* cmt = [NSString stringWithFormat:@"//%@:", @"FIXME"];
    [self insertComment:cmt];
}

- (void)insertWarn
{
    NSString* cmt = [NSString stringWithFormat:@"//%@:", @"!!!"];
    [self insertComment:cmt];
}
- (void)insertAsk
{
    NSString* cmt = [NSString stringWithFormat:@"//%@:", @"???"];
    [self insertComment:cmt];
}
- (void)insertComment:(NSString*)cmt
{
    IDESourceCodeEditor* editor = [XToDoModel currentEditor];
    NSTextView* textView = editor.textView;
    if (textView) {
        [textView insertText:cmt];
        [textView insertText:@" "];
    }
}

@end
