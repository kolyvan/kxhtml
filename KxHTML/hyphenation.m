//
//  hyphenation.m
//  KxHTML
//
//  Created by Kolyvan on 14.12.12.
//

/*
 Copyright (c) 2012 Konstantin Bukreev All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 - Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// алгоритм П.Хpистова в модификации Дымченко и Ваpсанофьева.

#import "hyphenation.h"

NSArray *hyphenateWord(NSString *s)
{    
    static NSCharacterSet *X_CHARS;
    static NSCharacterSet *G_CHARS;
    static NSCharacterSet *S_CHARS;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        X_CHARS = [NSCharacterSet characterSetWithCharactersInString:@"йьъ"];
        G_CHARS = [NSCharacterSet characterSetWithCharactersInString:@"аеёиоуыэюяaeiouy"];
        S_CHARS = [NSCharacterSet characterSetWithCharactersInString:@"бвгджзклмнпрстфхцчшщbcdfghjklmnpqrstvwxz"];
    });
    
    NSMutableArray *ma = [NSMutableArray array];
    
    s = s.lowercaseString;
    
    const NSUInteger length = s.length;
    unichar chars[length];
    [s getCharacters:chars range:NSMakeRange(0, length)];
    
    // prepare, replace chars
    
    for (NSUInteger i = 0; i < length; ++i) {
        
        unichar ch = chars[i];
        if ([X_CHARS characterIsMember:ch]) {
            
            chars[i] = 'X';
            
        } else if ([G_CHARS characterIsMember:ch]) {
                
            chars[i] = 'G';
            
        } else if ([S_CHARS characterIsMember:ch]) {
            
            chars[i] = 'S';
            
        } else {
            
            //return nil;
        }
    }
    
    // find pattern
    
    for (NSUInteger i = 0; i < length - 1; ++i) {
    
        // X.
        const unichar ch0 = chars[i];
        
        if (ch0 == 'X')
            [ma addObject:@(i+1)];
        else

        // G.G        
        if (i < length - 1) {
            
            const unichar ch1 = chars[i+1];
            
            if (ch0 == 'G' && ch1 == 'G')
                [ma addObject:@(i+1)];
            else
            
            // GS.SG
            // SG.SG            
            if (i < length - 3) {
        
                const unichar ch2 = chars[i+2];
                const unichar ch3 = chars[i+3];
                
                if ((ch2 == 'S' && ch3 == 'G') &&
                    ((ch0 == 'G' && ch1 == 'S') ||  (ch0 == 'S' && ch1 == 'G')))
                    [ma addObject:@(i+2)];
                else
    
                // GS.SSG
                if (i < length - 4) {
                
                    const unichar ch4 = chars[i+4];
                    
                    if (ch0 == 'G' && ch1 == 'S' && ch2 == 'S' && ch3 == 'S' && ch4 == 'G')
                        [ma addObject:@(i+2)];
                    else
                
                    // GSS.SSG
                    if (i < length - 5) {
                        
                        const unichar ch5 = chars[i+5];
                        
                        if (ch0 == 'G' && ch1 == 'S' && ch2 == 'S' && ch3 == 'S' && ch4 == 'S' && ch5 == 'G')
                            [ma addObject:@(i+3)];
                    }
                }
            }
        }
    }
 
    if (!ma.count)
        return nil;   
    
    [ma sortUsingComparator:^NSComparisonResult(NSNumber *left, NSNumber *right) {
        const NSUInteger l = left.integerValue;
        const NSUInteger r = right.integerValue;
        if (r < l) return NSOrderedAscending;
        if (r > l) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    //return ma.unique.sorted.reverse;
    return ma;
}

NSArray *hyphenateHyperlink(NSString *s)
{
    NSMutableArray *ma = [NSMutableArray array];
    NSScanner *scanner = [NSScanner scannerWithString:s];
    
    if ([scanner scanString:@"http://" intoString:nil] ||
        [scanner scanString:@"https://" intoString:nil] ||
        [scanner scanString:@"/" intoString:nil]) {
        
        [ma addObject:@(scanner.scanLocation)];
    }
    
    while (!scanner.isAtEnd) {
        
        if ([scanner scanUpToString:@"/" intoString:nil] &&
            [scanner scanString:@"/" intoString:nil]) {
            
            [ma addObject:@(scanner.scanLocation)];
            
        } else {
            
            break;
        }
    }
    
    [ma sortUsingComparator:^NSComparisonResult(NSNumber *left, NSNumber *right) {
        const NSUInteger l = left.integerValue;
        const NSUInteger r = right.integerValue;
        if (r < l) return NSOrderedAscending;
        if (r > l) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    return ma;
}