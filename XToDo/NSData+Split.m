//
//  NSData+Split.m
//
//  Created by ████
//

#import "NSData+Split.h"

@implementation NSData (Split)

-(NSArray *)componentsSeparatedByByte:(Byte)sep;
{
	unsigned long len, index, last_sep_index;
	NSData *line;
	NSMutableArray *lines = nil;
	
	len = [self length];
	Byte *cData = malloc(len);
    if (cData == NULL)
    {
        return lines;
    }
	
	[self getBytes:cData length:len];
	
	index = last_sep_index = 0;
	
	lines = [[NSMutableArray alloc] init];
	
	do
    {
		if (sep == cData[index])
		{
			NSRange startEndRange = NSMakeRange(last_sep_index, index - last_sep_index);
			line = [self subdataWithRange:startEndRange];
			
			[lines addObject:line];
			
			last_sep_index = index + 1;
			
			continue;
		}
	} while (index++ < len);
	
    free(cData);
    cData = NULL;
	
    return lines;
}

@end
