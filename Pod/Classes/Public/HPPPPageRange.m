//
//  HPPPPageRange.m
//  Pods
//
//  Created by Christine Harris on 7/4/15.
//
//

#import "HPPPPageRange.h"

@implementation HPPPPageRange

#pragma mark - Public Instance Methods

-(id)initWithString:(NSString *)range allPagesIndicator:(NSString *)allPagesIndicator maxPageNum:(NSInteger)maxPageNum sortAscending:(BOOL)sortAscending
{
    self = [super init];
    
    if( self ) {
        _allPagesIndicator = allPagesIndicator;
        _maxPageNum = maxPageNum;
        _sortAscending = sortAscending;
        self.range = range;
    }
    
    return self;
}

- (void)setRange:(NSString *)range
{
    if (nil == range) {
        range = self.allPagesIndicator;
    } else if( ![range isEqualToString:self.allPagesIndicator] ) {
        // Make sure we only have allowed characters in the range
        NSMutableCharacterSet *acceptableCharacters = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
        [acceptableCharacters addCharactersInString:@"-,"];
        NSCharacterSet *removeSet = acceptableCharacters.invertedSet;
        if( [range rangeOfCharacterFromSet:removeSet].location != NSNotFound ) {
            NSArray *remainingRange = [range componentsSeparatedByCharactersInSet:removeSet];
            range = [remainingRange componentsJoinedByString:@""];
        }
    }
    
    _range = range;
    [self cleanPageRange];
}

- (void)setAllPagesIndicator:(NSString *)allPagesIndicator
{
    _allPagesIndicator = allPagesIndicator;
    [self cleanPageRange];
}

- (void)setMaxPageNum:(NSInteger)maxPageNum
{
    _maxPageNum = maxPageNum;
    [self cleanPageRange];
}

- (void)setSortAscending:(BOOL)sortAscending
{
    _sortAscending = sortAscending;
    [self cleanPageRange];
}

- (NSArray *) getPages
{
    return [HPPPPageRange getPagesFromPageRange:self.range allPagesIndicator:self.allPagesIndicator maxPageNum:self.maxPageNum];
}

- (void) addPage:(NSNumber *)page
{
    NSMutableArray *pages = [[self getPages] mutableCopy];
    [pages addObject:page];
    self.range = [HPPPPageRange formPageRange:pages];
    if( self.sortAscending ) {
        self.range = [HPPPPageRange sortPageRange:self.range allPagesIndicator:self.allPagesIndicator maxPageNum:self.maxPageNum];
    }
}

- (void) removePage:(NSNumber *)page
{
    NSArray *pages = [self getPages];
    
    NSMutableArray *newPages = [[NSMutableArray alloc] initWithCapacity:pages.count];
    for( NSNumber *pageNum in pages ) {
        if ([pageNum integerValue] != [page integerValue]) {
            [newPages addObject:pageNum];
        }
    }
    
    self.range = [HPPPPageRange formPageRange:newPages];
    if( self.sortAscending ) {
        self.range = [HPPPPageRange sortPageRange:self.range allPagesIndicator:self.allPagesIndicator maxPageNum:self.maxPageNum];
    }
}

- (NSString *) description
{
    return self.range;
}

#pragma mark - Private Instance Methods

- (void)cleanPageRange
{
    _range = [HPPPPageRange cleanPageRange:self.range allPagesIndicator:self.allPagesIndicator maxPageNum:self.maxPageNum sortAscending:self.sortAscending];
}

#pragma mark - Public Class Methods

+ (NSArray *) getPagesFromPageRange:(NSString *)pageRange allPagesIndicator:(NSString *)allPagesIndicator maxPageNum:(NSInteger)maxPageNum
{
    NSMutableArray *pageNums = [[NSMutableArray alloc] initWithCapacity:maxPageNum];
    
    if( [allPagesIndicator isEqualToString:pageRange] ) {
        for (int i=1; i <= maxPageNum; i++) {
            [pageNums addObject:[NSNumber numberWithInt:i]];
        }
    } else {
        // split on commas
        NSArray *chunks = [pageRange componentsSeparatedByString:@","];
        for (NSString *chunk in chunks) {
            if( [chunk containsString:@"-"] ) {
                // split on the dash
                NSArray *rangeChunks = [chunk componentsSeparatedByString:@"-"];
                NSAssert(2 == rangeChunks.count, @"Bad page range");
                int startOfRange = [(NSString *)rangeChunks[0] intValue];
                int endOfRange = [(NSString *)rangeChunks[1] intValue];
                
                if( startOfRange < endOfRange ) {
                    for (int i=startOfRange; i<=endOfRange; i++) {
                        [pageNums addObject:[NSNumber numberWithInt:i]];
                    }
                } else if( startOfRange > endOfRange ) {
                    for (int i=startOfRange; i>=endOfRange; i--) {
                        [pageNums addObject:[NSNumber numberWithInt:i]];
                    }
                } else { // they are equal
                    [pageNums addObject:[NSNumber numberWithInt:startOfRange]];
                }
                
            } else if( chunk.length > 0 ){
                [pageNums addObject:[NSNumber numberWithInteger:[chunk integerValue]]];
            }
        }
    }
    
    return pageNums;
}

+ (NSString *) sortPageRange:(NSString *)pageRange allPagesIndicator:(NSString *)allPagesIndicator maxPageNum:(NSInteger)maxPageNum
{
    NSArray *pages = [HPPPPageRange getPagesFromPageRange:pageRange allPagesIndicator:allPagesIndicator maxPageNum:maxPageNum];
    
    NSMutableArray *mutablePages = [pages mutableCopy];
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [mutablePages sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    pages = mutablePages;
    
    pageRange = [HPPPPageRange formPageRangeFromPages:pages allPagesIndicator:allPagesIndicator maxPageNum:maxPageNum];
    
    return pageRange;
}

+ (NSString *) formPageRangeFromPages:(NSArray *)pages allPagesIndicator:(NSString *)allPagesIndicator maxPageNum:(NSInteger)maxPageNum
{
    NSString *pageRange = nil;
    
    // Do we need to use the allPagesIndicator?
    if( pages.count == maxPageNum ) {
        pageRange = [HPPPPageRange formPageRange:pages];
        
        NSString *fullPageRange = [NSString stringWithFormat:@"%d-%ld", 1, (long)maxPageNum];
        if( 1 == maxPageNum ) {
            fullPageRange = @"1";
        } else if( 2 == maxPageNum ) {
            fullPageRange = @"1,2";
        }
            
        if( [pageRange isEqualToString:fullPageRange] ) {
            pageRange = allPagesIndicator;
        } else {
            pageRange = nil;
        }
    }
    
    // If we didn't use the allPagesIndicator, calculate the page range
    if( nil == pageRange ) {
        pageRange = [HPPPPageRange formPageRange:pages];
    }
    
    return pageRange;
}

#pragma mark - Private Class Helpers

+ (NSString *) cleanPageRange:(NSString *)text allPagesIndicator:(NSString *)allPagesIndicator maxPageNum:(NSInteger)maxPageNum sortAscending:(BOOL)sortAscending
{
    NSString *scrubbedRange = text;
    
    // special case of attempting to use only page 0... which does not exist.  Change to page 1.
    if( [scrubbedRange isEqualToString:@"0"] ) {
        scrubbedRange = @"1";
    }
    
    if( nil == scrubbedRange  ||  [allPagesIndicator isEqualToString:scrubbedRange]  ||  scrubbedRange.length == 0) {
        scrubbedRange = allPagesIndicator;
    } else {
        // No ",-"... replace with ","
        // No "-,"... replace with ","
        // No "--"... replace with "-"
        // No ",,"... replace with ","
        // No strings starting or ending with "," or "-"
        // Replace all page numbers of 0 with 1
        // Replace all page numbers greater than the doc length with the doc length
        // No "%d1-%d2-%d3"... replace with "%d1-%d3"
        
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@",-" withString:@","];
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@"-," withString:@","];
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@",," withString:@","];
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@"--" withString:@"-"];
        
        // The first page is 1, not 0
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@"-0-" withString:@"-1-"];
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@",0," withString:@",1,"];
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@"-0," withString:@"-1,"];
        scrubbedRange = [scrubbedRange stringByReplacingOccurrencesOfString:@",0-" withString:@",1-"];
        
        scrubbedRange = [scrubbedRange stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-,"]];
        scrubbedRange = [HPPPPageRange replaceOutOfBoundsPageNumbers:scrubbedRange maxPageNum:maxPageNum];
        scrubbedRange = [HPPPPageRange replaceBadDashUsage:scrubbedRange];
        
        if( ![text isEqualToString:scrubbedRange] ) {
            text = scrubbedRange;
            
            // keep calling this function until it makes no modification
            scrubbedRange = [HPPPPageRange cleanPageRange:scrubbedRange allPagesIndicator:allPagesIndicator maxPageNum:maxPageNum sortAscending:sortAscending];
        }
    }
    
    if( sortAscending ) {
        scrubbedRange = [HPPPPageRange sortPageRange:scrubbedRange allPagesIndicator:allPagesIndicator maxPageNum:maxPageNum];
    } else {
        NSArray *pages = [HPPPPageRange getPagesFromPageRange:scrubbedRange allPagesIndicator:allPagesIndicator maxPageNum:maxPageNum];
        scrubbedRange = [HPPPPageRange formPageRangeFromPages:pages allPagesIndicator:allPagesIndicator maxPageNum:maxPageNum];
    }
    
    return scrubbedRange;
}

+ (NSString *)formPageRange:(NSArray *)pages
{
    NSString *pageRange = @"";
    NSString *separator = @"";
    
    for( int i=0; i<pages.count; i++ ) {
        NSInteger currentPage = [pages[i] integerValue];
        
        int newIndex = i;
        NSInteger newCurrentPage = currentPage;
        
        // check for an ascending range
        while (newIndex+1 < pages.count && [pages[newIndex+1] integerValue] == newCurrentPage+1) {
            newCurrentPage++;
            newIndex++;
        }
        
        // append the ascending range
        if( newIndex-i > 1 ) {
            NSString *range = [NSString stringWithFormat:@"%ld-%ld", currentPage, (long)newCurrentPage];
            pageRange = [pageRange stringByAppendingString:separator];
            pageRange = [pageRange stringByAppendingString:range];
            
            // or look for a descending range
        } else if( newIndex == i ){
            while (newIndex+1 < pages.count && [pages[newIndex+1] integerValue] == newCurrentPage-1) {
                newCurrentPage--;
                newIndex++;
            }
            
            // append the descending range
            if( newIndex-i > 1 ) {
                NSString *range = [NSString stringWithFormat:@"%ld-%ld", currentPage, (long)newCurrentPage];
                pageRange = [pageRange stringByAppendingString:separator];
                pageRange = [pageRange stringByAppendingString:range];
            }
        }
        
        // if no ranges were found, just append the page number
        if( newIndex-i <= 1 ) {
            NSString *nextPage = [NSString stringWithFormat:@"%ld", (long)currentPage];
            pageRange = [pageRange stringByAppendingString:separator];
            pageRange = [pageRange stringByAppendingString:nextPage];
        } else {
            i = newIndex;
        }
        
        separator = @",";
    }
    
    return pageRange;
}

+ (NSArray *)getNumsFromString:(NSString *)string
{
    NSMutableArray *returnArray = nil;
    
    if( nil != string && string.length ) {
        
        NSRange range = NSMakeRange(0,[string length]);
        
        NSRegularExpression *regex = [HPPPPageRange regularExpressionWithString:@"\\d+" options:nil];
        NSArray *matches = [regex matchesInString:string options:NSMatchingReportCompletion range:range];
        
        if( matches  &&  0 < matches.count ) {
            returnArray = [[NSMutableArray alloc] init];
            
            for( NSTextCheckingResult *pageNumRes in matches ) {
                NSString *pageNumStr = [string substringWithRange:pageNumRes.range];
                [returnArray addObject:[NSNumber numberWithInteger:[pageNumStr integerValue]]];
            }
        }
    }
    return returnArray;
}

+ (NSRegularExpression *)regularExpressionWithString:(NSString *)pattern options:(NSDictionary *)options
{
    // Create a regular expression
    NSError *error = NULL;
    NSRegularExpressionOptions regexOptions = NSRegularExpressionCaseInsensitive;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:regexOptions error:&error];
    if (error)
    {
        NSLog(@"Couldn't create regex with given string and options");
    }
    
    return regex;
}

+ (NSString *)replaceBadDashUsage:(NSString *)string
{
    NSMutableString *scrubbedString = [string mutableCopy];
    
    if( nil != string && string.length ) {
        NSRange range = NSMakeRange(0,[string length]);
        
        NSRegularExpression *regex = [HPPPPageRange regularExpressionWithString:@"(\\d+)-(\\d+)-(\\d+)" options:nil];
        [regex replaceMatchesInString:scrubbedString options:0 range:range withTemplate:@"$1-$3"];
    }
    
    return scrubbedString;
}

+ (NSString *)replaceOutOfBoundsPageNumbers:(NSString *)string maxPageNum:(NSInteger)maxPageNum
{
    BOOL corrected = FALSE;
    NSString *scrubbedString = string;
    
    NSArray *matches = [HPPPPageRange getNumsFromString:string];
    if( matches  &&  0 < matches.count ) {
        for( NSNumber *pageNumber in matches ) {
            NSInteger pageNum = [pageNumber integerValue];
            if( pageNum > maxPageNum ) {
                NSLog(@"error-- page num out of range: %ld, Word on Mac responds poorly in this scenario... what should we do?", (long)pageNum);
                scrubbedString = [scrubbedString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%ld", (long)pageNum] withString:[NSString stringWithFormat:@"%ld", (long)maxPageNum]];
                corrected = TRUE;
                break;
            }
        }
        
        if( corrected ) {
            scrubbedString = [HPPPPageRange replaceOutOfBoundsPageNumbers:scrubbedString maxPageNum:maxPageNum];
        }
    }
    
    return scrubbedString;
}

@end
