//
//  NSData+Split.h
//
//  Created by ████
//

#import <Foundation/Foundation.h>


/// An NSData category that allows splitting the data into separate components.

@interface NSData (Split)

/** Splits the source data into any array of components separated by the specified byte.
 
 Taken from http://www.geektheory.ca/blog/splitting-nsdata-object-data-specific-byte/
 
 @param sep Byte to separate by.
 @return NSArray of components
 */
-(NSArray *)componentsSeparatedByByte:(Byte)sep;

@end
