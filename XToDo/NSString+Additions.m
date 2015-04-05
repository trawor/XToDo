//
//  NSString+Additions.m
//  XToDo
//
//  Created by Gregory Catellani on 05/04/15.
//

#import "NSString+Additions.h"

@implementation NSString (Additions)

#pragma mark - NSStringExtensionMethods

- (BOOL) xtodo_containsStringOrSubstrings:(NSString *)string seperatedByString:(NSString *)separator
{
    NSParameterAssert(separator);

    // Remove any trailing occurences of the separator
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:separator]];

    BOOL result = YES;

    if(string.length > 0)
    {
        // Check if self is entirely made of string => returns YES in that case
        if ([self rangeOfString:string options:NSCaseInsensitiveSearch].location == NSNotFound)
        {
            // Check if self contains the substrings provided in string
            NSArray *substrings = [string componentsSeparatedByString:separator];
            if(substrings.count > 1)
            {
                for(NSString *substring in substrings)
                {
                    if([self rangeOfString:substring options:NSCaseInsensitiveSearch].location == NSNotFound)
                    {
                        result = NO;
                        break;
                    }
                }
            }
            else
            {
                result = NO;
            }
        }
    }
    else
    {
        result = NO;
    }
    return result;
}

@end
