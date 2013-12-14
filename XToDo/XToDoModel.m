//
//  XToDoModel.m
//  XToDo
//
//  Created by Travis on 13-11-28.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDoModel.h"
#import <objc/runtime.h>

static NSBundle *pluginBundle;

@implementation XToDoItem



@end

@implementation XToDoModel

+ (IDEWorkspaceTabController*)tabController{
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        
        return workspaceController.activeWorkspaceTabController;
    }
    return nil;
}

+ (id)currentEditor {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}
+ (IDEWorkspaceDocument *)currentWorkspaceDocument {
    NSWindowController *currentWindowController = [[NSApp keyWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController && [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument *)document;
    }
    return nil;
}

+ (IDESourceCodeDocument *)currentSourceCodeDocument {
    
    IDESourceCodeEditor *editor=[self currentEditor];
    
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return editor.sourceCodeDocument;
    }
    
    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        if ([[(IDESourceCodeComparisonEditor*)editor primaryDocument] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            return (id)[(IDESourceCodeComparisonEditor *)editor primaryDocument];
        }
    }
    
    return nil;
}

+ (NSArray*)findItemsWithPath:(NSString*)projectPath{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    
    NSString *shellPath=[[NSBundle bundleForClass:[self class]] pathForResource:@"find" ofType:@"sh"];
    
    [task setArguments:@[shellPath,projectPath]];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSString *string;
    string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    //NSLog(@"Path:%@\nOUTPUT:%@",projectPath,string);
    
    NSArray *results=[string componentsSeparatedByString:@"\n"];
    
    NSMutableArray *arr=[NSMutableArray array];
    for (NSString *line in results) {
        if (line.length>4) {
            [arr addObject:[self itemFromLine:line]];
        }
    }
    return arr;
}


+(XToDoItem*)itemFromLine:(NSString*)line{
    NSArray *cpt=[line componentsSeparatedByString:@":"];
    if (cpt.count<5) {
        return nil;
    }
    
    XToDoItem *item=[[XToDoItem alloc] init];
    item.filePath=cpt[0];
    item.lineNumber=[cpt[1] integerValue];
    
    item.typeString=cpt[3];
    
    if (cpt.count==5) {
        item.content=[cpt[4] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        
    }else{
        //add the other contents back
        NSString *s=cpt[4];
        int i=4;
        while (i<cpt.count-1) {
            i++;
            s=[s stringByAppendingFormat:@":%@",cpt[i]];
        }
        item.content=[s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        
        //TODO: item is completed?
        //TODO: int type
    }
    return item;
}

+(BOOL)openItem:(XToDoItem *)item{
    
    //IDESourceCodeEditor *editor=[self currentEditor];
    
    NSURL *fileURL=[NSURL fileURLWithPath:item.filePath];
    
    
    //open the file
    BOOL result=[[NSWorkspace sharedWorkspace] openFile:item.filePath withApplication:@"Xcode"];
    
    //open the line
    if (result) {
        IDESourceCodeEditor *editor=[XToDoModel currentEditor];
        NSTextView *textView=editor.textView;
        if (textView) {
            NSString *viewContent = [textView string];
            NSRange range= [viewContent lineRangeForRange:NSMakeRange(item.lineNumber, 1)];
            
            //FIXME: the line is not selected or highlighted
            [textView setSelectedRange:range];
            [textView selectLine:nil];
        }else{
            //FIXME: pretty slow to open file with applescript
            
            NSString *theSource = [NSString stringWithFormat: @"do shell script \"xed --line %ld \" & quoted form of \"%@\"", item.lineNumber,item.filePath];
            NSAppleScript *theScript = [[NSAppleScript alloc] initWithSource:theSource];
            [theScript performSelectorInBackground:@selector(executeAndReturnError:) withObject:nil];

            return NO;
        }
    }
    
    return result;
}
@end
