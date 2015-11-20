//
//  NSString+Additions.h
//  XToDo
//
//  Created by Gregory Catellani on 05/04/15.
//

#import <Foundation/Foundation.h>

@interface NSString (Additions)

#pragma mark - NSStringExtensionMethods

- (BOOL) xtodo_containsStringOrSubstrings:(NSString *)string seperatedByString:(NSString *)separator;

@end
