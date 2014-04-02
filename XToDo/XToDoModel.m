//
//  XToDoModel.m
//  XToDo
//
//  Created by Travis on 13-11-28.
//  Copyright (c) 2013年 Plumn LLC. All rights reserved.
//

#import "XToDoModel.h"
#import <objc/runtime.h>

#import "XToDoPreferencesWindowController.h"

#import "NSData+Split.h"

static NSBundle *pluginBundle;

@implementation XToDoItem


-(NSString*)description{
    return [NSString stringWithFormat:@"XToDoItem[%@]: %@",self.typeString,self.content];
}

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
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController *workspaceController = (IDEWorkspaceWindowController *)currentWindowController;
        IDEEditorArea *editorArea = [workspaceController editorArea];
        IDEEditorContext *editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}
+ (IDEWorkspaceDocument *)currentWorkspaceDocument {
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
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

//TESTME: some tests!

+ (NSString*)scannedStrings {
    NSArray* prefsStrings = [[NSUserDefaults standardUserDefaults] objectForKey:kXToDoTagsKey];
    NSMutableArray* escapedStrings = [NSMutableArray arrayWithCapacity:[prefsStrings count]];
    
    for (NSString* origStr in prefsStrings) {
        NSMutableString* str = [NSMutableString string];
        
        for (NSUInteger i=0; i<[origStr length]; i++) {
            unichar c = [origStr characterAtIndex:i];
            
            if (!isalpha(c) && ! isnumber(c)) {
                [str appendFormat:@"\\%C", c];
            } else {
                [str appendFormat:@"%C", c];
            }
        }
        
        [str appendFormat:@"\\:"];
        
        [escapedStrings addObject:str];
    }
    
    return [escapedStrings componentsJoinedByString:@"|"];
}

+ (NSArray*)findItemsWithPath:(NSString*)projectPath{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    
    NSString *shellPath=[[NSBundle bundleForClass:[self class]] pathForResource:@"find" ofType:@"sh"];
    
    [task setArguments:@[shellPath,projectPath, [self scannedStrings]]];

    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];

    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    NSArray *dataArray = [data componentsSeparatedByByte:'\n'];
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:[dataArray count]];
    for (NSData *dataItem in dataArray) {
        NSString *string = [[NSString alloc] initWithData:dataItem encoding:NSUTF8StringEncoding];
        if (string != nil){
            [results addObject:string];
        }
    }
    //NSLog(@"Path:%@\nOUTPUT:%@",projectPath,string);
    
    NSMutableArray *arr=[NSMutableArray array];
    for (NSString *line in results) {
        if (line.length>4) {
            id anItem = [self itemFromLine:line];
            
            if (nil != anItem) {
                [arr addObject:anItem];
            }
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
        
        //???: item is completed?
        //TODO: int type
    }
    return item;
}

+(void)highlightItem:(XToDoItem*)item inTextView:(NSTextView*)textView{
    NSUInteger lineNumber=item.lineNumber-1;
    NSString *text = [textView string];
    
    NSRegularExpression *re=[NSRegularExpression regularExpressionWithPattern:@"\n" options:0 error:nil];
    
    NSArray *result=[re matchesInString:text options:NSMatchingReportCompletion range:NSMakeRange(0, text.length)];
    
    if (result.count<=lineNumber) {
        return;
    }
    
    NSUInteger location=0;
    NSTextCheckingResult *aim=result[lineNumber];
    location= aim.range.location;
    
    NSRange range=[text lineRangeForRange:NSMakeRange(location, 0)];
    
    [textView scrollRangeToVisible:range];
    
    [textView setSelectedRange:range];
    
}


+(BOOL)openItem:(XToDoItem *)item{
    
    NSWindowController *currentWindowController = [[NSApp mainWindow] windowController];
    
    NSLog(@"currentWindowController %@",[currentWindowController description]);
    
    if ([currentWindowController isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        
        NSLog(@"Open in current Xocde");
        if ([[NSApp delegate] application:NSApp openFile:item.filePath]) {
            
            IDESourceCodeEditor *editor=[XToDoModel currentEditor];
            if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
                NSTextView *textView=editor.textView;
                if (textView) {
                    
                    [self highlightItem:item inTextView:textView];
                    
                    return YES;
                }
            }
        }
    }
    
    
    //open the file
    BOOL result=[[NSWorkspace sharedWorkspace] openFile:item.filePath withApplication:@"Xcode"];
    
    //open the line
    if (result) {
       
            //pretty slow to open file with applescript
        
            NSString *theSource = [NSString stringWithFormat: @"do shell script \"xed --line %ld \" & quoted form of \"%@\"", item.lineNumber,item.filePath];
            NSAppleScript *theScript = [[NSAppleScript alloc] initWithSource:theSource];
            [theScript performSelectorInBackground:@selector(executeAndReturnError:) withObject:nil];

            return NO;
        
    }
    
    return result;
}
@end
