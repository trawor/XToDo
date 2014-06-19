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

static NSBundle* pluginBundle;

@implementation XToDoItem

- (NSString*)description
{
    return [NSString
        stringWithFormat:@"XToDoItem[%@]: %@", self.typeString, self.content];
}

@end

@implementation XToDoModel

+ (IDEWorkspaceTabController*)tabController
{
    NSWindowController* currentWindowController =
        [[NSApp keyWindow] windowController];
    if ([currentWindowController
            isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)currentWindowController;

        return workspaceController.activeWorkspaceTabController;
    }
    return nil;
}

+ (id)currentEditor
{
    NSWindowController* currentWindowController =
        [[NSApp mainWindow] windowController];
    if ([currentWindowController
            isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEWorkspaceWindowController* workspaceController = (IDEWorkspaceWindowController*)currentWindowController;
        IDEEditorArea* editorArea = [workspaceController editorArea];
        IDEEditorContext* editorContext = [editorArea lastActiveEditorContext];
        return [editorContext editor];
    }
    return nil;
}
+ (IDEWorkspaceDocument*)currentWorkspaceDocument
{
    NSWindowController* currentWindowController =
        [[NSApp mainWindow] windowController];
    id document = [currentWindowController document];
    if (currentWindowController &&
        [document isKindOfClass:NSClassFromString(@"IDEWorkspaceDocument")]) {
        return (IDEWorkspaceDocument*)document;
    }
    return nil;
}

+ (IDESourceCodeDocument*)currentSourceCodeDocument
{

    IDESourceCodeEditor* editor = [self currentEditor];

    if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
        return editor.sourceCodeDocument;
    }

    if ([editor
            isKindOfClass:NSClassFromString(@"IDESourceCodeComparisonEditor")]) {
        if ([[(IDESourceCodeComparisonEditor*)editor primaryDocument]
                isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")]) {
            return (id)[(IDESourceCodeComparisonEditor*)editor primaryDocument];
        }
    }

    return nil;
}

// TESTME: some tests!

+ (NSString*)scannedStrings
{
    NSArray* prefsStrings =
        [[NSUserDefaults standardUserDefaults] objectForKey:kXToDoTagsKey];
    NSMutableArray* escapedStrings =
        [NSMutableArray arrayWithCapacity:[prefsStrings count]];

    for (NSString* origStr in prefsStrings) {
        NSMutableString* str = [NSMutableString string];

        for (NSUInteger i = 0; i < [origStr length]; i++) {
            unichar c = [origStr characterAtIndex:i];

            if (!isalpha(c) && !isnumber(c)) {
                [str appendFormat:@"\\%C", c];
            } else {
                [str appendFormat:@"%C", c];
            }
        }

        [escapedStrings addObject:str];
    }

    return [escapedStrings componentsJoinedByString:@"|"];
}

typedef void (^OnFindedItem)(NSString* fullPath, BOOL isDirectory,
                             BOOL* skipThis, BOOL* stopAll);
+ (void)scanFolder:(NSString*)folder
    findedItemBlock:(OnFindedItem)findedItemBlock
{
    BOOL stopAll = NO;

    NSFileManager* localFileManager = [[NSFileManager alloc] init];
    NSDirectoryEnumerationOptions option = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants;
    NSDirectoryEnumerator* directoryEnumerator =
        [localFileManager enumeratorAtURL:[NSURL fileURLWithPath:folder]
               includingPropertiesForKeys:nil
                                  options:option
                             errorHandler:nil];
    for (NSURL* theURL in directoryEnumerator) {
        if (stopAll) {
            break;
        }

        NSString* fileName = nil;
        [theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];

        NSNumber* isDirectory = nil;
        [theURL getResourceValue:&isDirectory
                          forKey:NSURLIsDirectoryKey
                           error:NULL];

        BOOL skinThis = NO;

        BOOL directory = [isDirectory boolValue];

        findedItemBlock([theURL path], directory, &skinThis, &stopAll);

        if (skinThis) {
            [directoryEnumerator skipDescendents];
        }
    }
}

+ (NSArray*)removeSubDirs:(NSArray*)dirs
{
    // TODO:
    return dirs;
}

+ (NSSet*)lowercaseFileTypes:(NSSet*)fileTypes
{
    NSMutableSet* set = [NSMutableSet setWithCapacity:[fileTypes count]];
    for (NSString* fileType in fileTypes) {
        [set addObject:[fileType lowercaseString]];
    }
    return set;
}

+ (NSArray*)findFileNameWithProjectPath:(NSString*)projectPath
                            includeDirs:(NSArray*)includeDirs
                            excludeDirs:(NSArray*)excludeDirs
                              fileTypes:(NSSet*)fileTypes
{
    includeDirs =
        [XToDoModel explandRootPathMacros:includeDirs projectPath:projectPath];
    includeDirs = [XToDoModel removeSubDirs:includeDirs];
    excludeDirs =
        [XToDoModel explandRootPathMacros:excludeDirs projectPath:projectPath];
    excludeDirs = [XToDoModel removeSubDirs:excludeDirs];
    fileTypes = [XToDoModel lowercaseFileTypes:fileTypes];
    NSMutableArray* allFilePaths = [NSMutableArray arrayWithCapacity:1000];
    for (NSString* includeDir in includeDirs) {
        [XToDoModel
                 scanFolder:includeDir
            findedItemBlock:^(NSString* fullPath, BOOL isDirectory, BOOL* skipThis,
                              BOOL* stopAll) {
            if (isDirectory) {
              for (NSString *excludeDir in excludeDirs) {
                if ([fullPath hasPrefix:excludeDir]) {
                  *skipThis = YES;
                  return;
                }
              }
            } else {
              if ([fileTypes containsObject:
                                 [[fullPath pathExtension] lowercaseString]]) {
                [allFilePaths addObject:fullPath];
              }
            }
            }];
    }
    return allFilePaths;
}

/**
 *  find all XToDoItem by specified paths
 *  @param projectPath for expland @(SRC_ROOT)
 *  @param includeDirs one or more path that contains source files
 *  @param excludeDirs dirs that SHOULD NOT search for
 *  @param fileTypes [NSSet setWithObject:@"mm", @"m", ...]
 *
 *  @return array contains XToDoItem
 */
+ (NSArray*)findItemsWithProjectPath:(NSString*)projectPath
                         includeDirs:(NSArray*)includeDirs
                         excludeDirs:(NSArray*)excludeDirs
                           fileTypes:(NSSet*)fileTypes
                        tempFilePath:(NSString*)tempFilePath
{
    // find all files match dirs and extnames
    NSArray* filePaths = [XToDoModel findFileNameWithProjectPath:projectPath
                                                     includeDirs:includeDirs
                                                     excludeDirs:excludeDirs
                                                       fileTypes:fileTypes];

    // xargs -0 need "\0" as separtor
    NSData* dataAllFilePaths = [[filePaths componentsJoinedByString:@"\0"]
        dataUsingEncoding:NSUTF8StringEncoding];

    NSTask* task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/bash"];
    NSString* shellPath =
        [[NSBundle bundleForClass:[self class]] pathForResource:@"find"
                                                         ofType:@"sh"];
    [task setArguments:@[ shellPath, [self scannedStrings] ]];

    if ([dataAllFilePaths writeToFile:tempFilePath atomically:NO] == NO) {
        return nil;
    }
    NSFileHandle* inputFileHandle =
        [NSFileHandle fileHandleForReadingAtPath:tempFilePath];
    if (inputFileHandle == nil) {
        return nil;
    }

    [task setStandardInput:inputFileHandle];
    [task setStandardOutput:[NSPipe pipe]];
    NSFileHandle* readHandle = [[task standardOutput] fileHandleForReading];

    [task launch];

    NSData* data = [readHandle readDataToEndOfFile];
    [inputFileHandle closeFile];

    NSArray* dataArray = [data componentsSeparatedByByte:'\n'];
    NSMutableArray* results =
        [NSMutableArray arrayWithCapacity:[dataArray count]];
    for (NSData* dataItem in dataArray) {
        NSString* string =
            [[NSString alloc] initWithData:dataItem encoding:NSUTF8StringEncoding];
        if (string != nil) {
            [results addObject:string];
        }
    }

    NSMutableArray* arr = [NSMutableArray array];
    for (NSString* line in results) {
        if (line.length > 4) {
            id anItem = [self itemFromLine:line];

            if (nil != anItem) {
                [arr addObject:anItem];
            }
        }
    }
    return arr;
}

+ (NSArray*)findItemsWithProjectSetting:(ProjectSetting*)projectSetting
                            projectPath:(NSString*)projectPath
{
    NSArray* includeDirs = [projectSetting includeDirs];
    if ([includeDirs count] == 0) {
        return 0;
    }

    NSArray* items = nil;
    NSString* tempFilePath = [[XToDoModel _tempFileDirectory]
        stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    @try {
        items = [XToDoModel
            findItemsWithProjectPath:projectPath
                         includeDirs:[projectSetting includeDirs]
                         excludeDirs:[projectSetting excludeDirs]
                           fileTypes:[NSSet setWithObjects:@"H", @"hpp", @"M",
                                                           @"Mm", @"c", @"cpp",
                                                           @"cc", @"swift", nil]
                        tempFilePath:tempFilePath];
    }
    @catch (NSException* exception)
    {
    }
    @finally
    {
        [[NSFileManager defaultManager]
            removeItemAtPath:tempFilePath
                       error:nil]; // HAVE TO delete temp file.
    }
    return items;
}

+ (XToDoItem*)itemFromLine:(NSString*)line
{
    NSArray* lineComponents = [line componentsSeparatedByString:@":"];

    // Validate the line
    if (lineComponents.count < 3) {
        return nil;
    }

    // Prepare to populate the TODO item
    XToDoItem* item = [[XToDoItem alloc] init];

    // Extract metadata from the line
    item.filePath = lineComponents[0];
    item.lineNumber = [lineComponents[1] integerValue];
    item.typeString = lineComponents[2];

    // Everything on the line after the keyword becomes description content shown
    // in the ToDo List window.
    // Glue the string back together in case there were delimeters after the type
    // string
    // Gratiutous colons and leading / trailing white space is already trimmed by
    // the regex in find.sh
    NSString* trailingComment = @"";
    for (NSUInteger i = 3; i < lineComponents.count; i++) {
        trailingComment =
            [trailingComment stringByAppendingString:lineComponents[i]];
    }

    // Put something in the content just in case...
    // This should really be handled in the window view
    if ([trailingComment isEqualToString:@""]) {
        trailingComment =
            [NSString stringWithFormat:@"Line %lu", (unsigned long)item.lineNumber];
    }

    item.content = trailingComment;

    return item;
}

+ (void)highlightItem:(XToDoItem*)item inTextView:(NSTextView*)textView
{
    NSUInteger lineNumber = item.lineNumber - 1;
    NSString* text = [textView string];

    NSRegularExpression* re =
        [NSRegularExpression regularExpressionWithPattern:@"\n"
                                                  options:0
                                                    error:nil];

    NSArray* result = [re matchesInString:text
                                  options:NSMatchingReportCompletion
                                    range:NSMakeRange(0, text.length)];

    if (result.count <= lineNumber) {
        return;
    }

    NSUInteger location = 0;
    NSTextCheckingResult* aim = result[lineNumber];
    location = aim.range.location;

    NSRange range = [text lineRangeForRange:NSMakeRange(location, 0)];

    [textView scrollRangeToVisible:range];

    [textView setSelectedRange:range];
}

+ (BOOL)openItem:(XToDoItem*)item
{

    NSWindowController* currentWindowController =
        [[NSApp mainWindow] windowController];

    // NSLog(@"currentWindowController %@",[currentWindowController description]);

    if ([currentWindowController
            isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {

        // NSLog(@"Open in current Xocde");
        if ([[NSApp delegate] application:NSApp openFile:item.filePath]) {

            IDESourceCodeEditor* editor = [XToDoModel currentEditor];
            if ([editor isKindOfClass:NSClassFromString(@"IDESourceCodeEditor")]) {
                NSTextView* textView = editor.textView;
                if (textView) {

                    [self highlightItem:item inTextView:textView];

                    return YES;
                }
            }
        }
    }

    // open the file
    BOOL result = [[NSWorkspace sharedWorkspace] openFile:item.filePath
                                          withApplication:@"Xcode"];

    // open the line
    if (result) {

        // pretty slow to open file with applescript

        NSString* theSource = [NSString
            stringWithFormat:
                @"do shell script \"xed --line %ld \" & quoted form of \"%@\"",
                item.lineNumber, item.filePath];
        NSAppleScript* theScript = [[NSAppleScript alloc] initWithSource:theSource];
        [theScript performSelectorInBackground:@selector(executeAndReturnError:)
                                    withObject:nil];

        return NO;
    }

    return result;
}

+ (NSString*)_settingDirectory
{
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    // TODO [path count] == 0
    NSString* settingDirectory = [(NSString*)[paths objectAtIndex:0]
        stringByAppendingPathComponent:@"XToDo"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:settingDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:settingDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    return settingDirectory;
}

+ (NSString*)_tempFileDirectory
{
    NSString* tempFileDirectory =
        [[XToDoModel _settingDirectory] stringByAppendingPathComponent:@"Temp"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFileDirectory] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:tempFileDirectory
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];
    }
    return tempFileDirectory;
}

+ (void)cleanAllTempFiles
{
    [XToDoModel
             scanFolder:[XToDoModel _tempFileDirectory]
        findedItemBlock:^(NSString* fullPath, BOOL isDirectory, BOOL* skipThis,
                          BOOL* stopAll) {
          [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        }];
}

+ (NSString*)rootPathMacro
{
    return [XToDoModel addPathSlash:@"$(SRCROOT)"];
}

+ (NSArray*)explandRootPathMacros:(NSArray*)paths
                      projectPath:(NSString*)projectPath
{
    if (projectPath == nil) {
        return paths;
    }

    NSMutableArray* explandPaths =
        [NSMutableArray arrayWithCapacity:[paths count]];
    for (NSString* path in paths) {
        [explandPaths addObject:[XToDoModel explandRootPathMacro:path
                                                     projectPath:projectPath]];
    }
    return explandPaths;
}

+ (NSString*)addPathSlash:(NSString*)path
{
    if ([path length] > 0) {
        if ([path characterAtIndex:([path length] - 1)] != '/') {
            path = [NSString stringWithFormat:@"%@/", path];
        }
    }
    return path;
}

+ (NSString*)explandRootPathMacro:(NSString*)path
                      projectPath:(NSString*)projectPath
{
    projectPath = [XToDoModel addPathSlash:projectPath];
    path = [path stringByReplacingOccurrencesOfString:[XToDoModel rootPathMacro]
                                           withString:projectPath];

    return [XToDoModel addPathSlash:path];
}

+ (NSString*)settingFilePathByProjectName:(NSString*)projectName
{
    NSString* settingDirectory = [XToDoModel _settingDirectory];
    NSString* fileName = [projectName length] ? projectName : @"Test.xcodeproj";
    return [settingDirectory
        stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",
                                                                  fileName]];
}

+ (ProjectSetting*)projectSettingByProjectName:(NSString*)projectName
{
    static NSMutableDictionary* projectName2ProjectSetting = nil;
    if (projectName2ProjectSetting == nil) {
        projectName2ProjectSetting = [[NSMutableDictionary alloc] init];
    }

    if (projectName != nil) {
        id object = [projectName2ProjectSetting objectForKey:projectName];
        if ([object isKindOfClass:[ProjectSetting class]]) {
            return object;
        }
    }

    NSString* fullPath = [XToDoModel settingFilePathByProjectName:projectName];
    ProjectSetting* projectSetting = nil;
    @try {
        projectSetting = [NSKeyedUnarchiver unarchiveObjectWithFile:fullPath];
    }
    @catch (NSException* exception)
    {
    }
    if ([projectSetting isKindOfClass:[projectSetting class]] == NO) {
        projectSetting = nil;
    }

    if (projectSetting == nil) {
        projectSetting = [ProjectSetting defaultProjectSetting];
    }
    if ((projectSetting != nil) && (projectName != nil)) {
        [projectName2ProjectSetting setObject:projectSetting forKey:projectName];
    }
    return projectSetting;
}

+ (void)saveProjectSetting:(ProjectSetting*)projectSetting
             ByProjectName:(NSString*)projectName
{
    if (projectSetting == nil) {
        return;
    }
    @try {
        NSString* filePath = [XToDoModel settingFilePathByProjectName:projectName];
        [NSKeyedArchiver archiveRootObject:projectSetting toFile:filePath];
        filePath = nil;
    }
    @catch (NSException* exception)
    {
        // NSLog(@"saveProjectSetting:exception:%@", exception);
    }
    // NSLog(@"haha");
}

@end
