//
//  UIColor+HTML.m
//  kxhtmlrender
//
//  Based on code from DTFoundation
//  https://github.com/Cocoanetics/DTFoundation
//
//  Created by Oliver Drobnik on 1/18/12.
//  Copyright (c) 2012 Cocoanetics. All rights reserved.
//

/*
 Copyright (c) 2011, Oliver Drobnik All rights reserved.
 
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

#import "UIColor+HTML.h"

static NSUInteger parseIntegerValueFromHex(NSString *hex)
{
    NSUInteger result;
    NSScanner* scanner = [NSScanner scannerWithString:hex];
    [scanner scanHexInt:&result];
    return result;
}

@implementation UIColor (HTML)

+ (UIColor *)colorWithHexString:(NSString *)hex
{
	if ([hex length]!=6 && [hex length]!=3)
	{
		return nil;
	}
	
	NSUInteger digits = [hex length]/3;
	CGFloat maxValue = (digits==1)?15.0:255.0;
	
	CGFloat red   = parseIntegerValueFromHex([hex substringWithRange:NSMakeRange(0, digits)])/maxValue;
	CGFloat green = parseIntegerValueFromHex([hex substringWithRange:NSMakeRange(digits, digits)])/maxValue;
	CGFloat blue =  parseIntegerValueFromHex([hex substringWithRange:NSMakeRange(2*digits, digits)])/maxValue;
	
	return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

// Source: http://www.w3schools.com/html/html_colornames.asp
+ (UIColor *)colorWithHTMLName:(NSString *)name
{
	if ([name hasPrefix:@"#"])
	{
		return [UIColor colorWithHexString:[name substringFromIndex:1]];
	}
	
	if ([name hasPrefix:@"rgba"]) {
		NSString *rgbaName = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"rgba() "]];
		NSArray *rgba = [rgbaName componentsSeparatedByString:@","];
		
		if ([rgba count] != 4) {
			// Incorrect syntax
			return nil;
		}
		
		return [UIColor colorWithRed:[[rgba objectAtIndex:0] floatValue] / 255
							   green:[[rgba objectAtIndex:1] floatValue] / 255
								blue:[[rgba objectAtIndex:2] floatValue] / 255
							   alpha:[[rgba objectAtIndex:3] floatValue]];
	}
	
	if([name hasPrefix:@"rgb"])
	{
		NSString * rgbName = [name stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"rbg() "]];
		NSArray* rbg = [rgbName componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
		if ([rbg count] != 3) {
			// Incorrect syntax
			return nil;
		}
		return [UIColor colorWithRed:[[rbg objectAtIndex:0]floatValue]/255
                               green:[[rbg objectAtIndex:1]floatValue]/255
                                blue:[[rbg objectAtIndex:2]floatValue]/255
                               alpha:1.0];
	}
	
    static NSDictionary *colorLookup = nil;
	static dispatch_once_t predicate;
	dispatch_once(&predicate, ^{
		colorLookup = [[NSDictionary alloc] initWithObjectsAndKeys:
                       @0xF0F8FF, @"aliceblue",
                       @0xFAEBD7, @"antiquewhite",
                       @0x00FFFF, @"aqua",
                       @0x7FFFD4, @"aquamarine",
                       @0xF0FFFF, @"azure",
                       @0xF5F5DC, @"beige",
                       @0xFFE4C4, @"bisque",
                       @0x000000, @"black",
                       @0xFFEBCD, @"blanchedalmond",
                       @0x0000FF, @"blue",
                       @0x8A2BE2, @"blueviolet",
                       @0xA52A2A, @"brown",
                       @0xDEB887, @"burlywood",
                       @0x5F9EA0, @"cadetblue",
                       @0x7FFF00, @"chartreuse",
                       @0xD2691E, @"chocolate",
                       @0xFF7F50, @"coral",
                       @0x6495ED, @"cornflowerblue",
                       @0xFFF8DC, @"cornsilk",
                       @0xDC143C, @"crimson",
                       @0x00FFFF, @"cyan",
                       @0x00008B, @"darkblue",
                       @0x008B8B, @"darkcyan",
                       @0xB8860B, @"darkgoldenrod",
                       @0xA9A9A9, @"darkgray",
                       @0xA9A9A9, @"darkgrey",
                       @0x006400, @"darkgreen",
                       @0xBDB76B, @"darkkhaki",
                       @0x8B008B, @"darkmagenta",
                       @0x556B2F, @"darkolivegreen",
                       @0xFF8C00, @"darkorange",
                       @0x9932CC, @"darkorchid",
                       @0x8B0000, @"darkred",
                       @0xE9967A, @"darksalmon",
                       @0x8FBC8F, @"darkseagreen",
                       @0x483D8B, @"darkslateblue",
                       @0x2F4F4F, @"darkslategray",
                       @0x2F4F4F, @"darkslategrey",
                       @0x00CED1, @"darkturquoise",
                       @0x9400D3, @"darkviolet",
                       @0xFF1493, @"deeppink",
                       @0x00BFFF, @"deepskyblue",
                       @0x696969, @"dimgray",
                       @0x696969, @"dimgrey",
                       @0x1E90FF, @"dodgerblue",
                       @0xB22222, @"firebrick",
                       @0xFFFAF0, @"floralwhite",
                       @0x228B22, @"forestgreen",
                       @0xFF00FF, @"fuchsia",
                       @0xDCDCDC, @"gainsboro",
                       @0xF8F8FF, @"ghostwhite",
                       @0xFFD700, @"gold",
                       @0xDAA520, @"goldenrod",
                       @0x808080, @"gray",
                       @0x808080, @"grey",
                       @0x008000, @"green",
                       @0xADFF2F, @"greenyellow",
                       @0xF0FFF0, @"honeydew",
                       @0xFF69B4, @"hotpink",
                       @0xCD5C5C, @"indianred",
                       @0x4B0082, @"indigo",
                       @0xFFFFF0, @"ivory",
                       @0xF0E68C, @"khaki",
                       @0xE6E6FA, @"lavender",
                       @0xFFF0F5, @"lavenderblush",
                       @0x7CFC00, @"lawngreen",
                       @0xFFFACD, @"lemonchiffon",
                       @0xADD8E6, @"lightblue",
                       @0xF08080, @"lightcoral",
                       @0xE0FFFF, @"lightcyan",
                       @0xFAFAD2, @"lightgoldenrodyellow",
                       @0xD3D3D3, @"lightgray",
                       @0xD3D3D3, @"lightgrey",
                       @0x90EE90, @"lightgreen",
                       @0xFFB6C1, @"lightpink",
                       @0xFFA07A, @"lightsalmon",
                       @0x20B2AA, @"lightseagreen",
                       @0x87CEFA, @"lightskyblue",
                       @0x778899, @"lightslategray",
                       @0x778899, @"lightslategrey",
                       @0xB0C4DE, @"lightsteelblue",
                       @0xFFFFE0, @"lightyellow",
                       @0x00FF00, @"lime",
                       @0x32CD32, @"limegreen",
                       @0xFAF0E6, @"linen",
                       @0xFF00FF, @"magenta",
                       @0x800000, @"maroon",
                       @0x66CDAA, @"mediumaquamarine",
                       @0x0000CD, @"mediumblue",
                       @0xBA55D3, @"mediumorchid",
                       @0x9370D8, @"mediumpurple",
                       @0x3CB371, @"mediumseagreen",
                       @0x7B68EE, @"mediumslateblue",
                       @0x00FA9A, @"mediumspringgreen",
                       @0x48D1CC, @"mediumturquoise",
                       @0xC71585, @"mediumvioletred",
                       @0x191970, @"midnightblue",
                       @0xF5FFFA, @"mintcream",
                       @0xFFE4E1, @"mistyrose",
                       @0xFFE4B5, @"moccasin",
                       @0xFFDEAD, @"navajowhite",
                       @0x000080, @"navy",
                       @0xFDF5E6, @"oldlace",
                       @0x808000, @"olive",
                       @0x6B8E23, @"olivedrab",
                       @0xFFA500, @"orange",
                       @0xFF4500, @"orangered",
                       @0xDA70D6, @"orchid",
                       @0xEEE8AA, @"palegoldenrod",
                       @0x98FB98, @"palegreen",
                       @0xAFEEEE, @"paleturquoise",
                       @0xD87093, @"palevioletred",
                       @0xFFEFD5, @"papayawhip",
                       @0xFFDAB9, @"peachpuff",
                       @0xCD853F, @"peru",
                       @0xFFC0CB, @"pink",
                       @0xDDA0DD, @"plum",
                       @0xB0E0E6, @"powderblue",
                       @0x800080, @"purple",
                       @0xFF0000, @"red",
                       @0xBC8F8F, @"rosybrown",
                       @0x4169E1, @"royalblue",
                       @0x8B4513, @"saddlebrown",
                       @0xFA8072, @"salmon",
                       @0xF4A460, @"sandybrown",
                       @0x2E8B57, @"seagreen",
                       @0xFFF5EE, @"seashell",
                       @0xA0522D, @"sienna",
                       @0xC0C0C0, @"silver",
                       @0x87CEEB, @"skyblue",
                       @0x6A5ACD, @"slateblue",
                       @0x708090, @"slategray",
                       @0x708090, @"slategrey",
                       @0xFFFAFA, @"snow",
                       @0x00FF7F, @"springgreen",
                       @0x4682B4, @"steelblue",
                       @0xD2B48C, @"tan",
                       @0x008080, @"teal",
                       @0xD8BFD8, @"thistle",
                       @0xFF6347, @"tomato",
                       @0x40E0D0, @"turquoise",
                       @0xEE82EE, @"violet",
                       @0xF5DEB3, @"wheat",
                       @0xFFFFFF, @"white",
                       @0xF5F5F5, @"whitesmoke",
                       @0xFFFF00, @"yellow",
                       @0x9ACD32, @"yellowgreen",
                       nil];
	});
	
	NSNumber *n = colorLookup[name.lowercaseString];
    if (n) {
        
        return [UIColor colorWithRed: ((n.integerValue >> 16) & 0xff) / 255.0
                               green: ((n.integerValue >>  8) & 0xff) / 255.0
                                blue: ((n.integerValue >>  0) & 0xff) / 255.0
                               alpha: 1.0];

    }
    
    return nil;
}

- (NSString *)htmlName
{
	CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];
	
	return [NSString stringWithFormat:@"#%02x%02x%02x",
            (NSUInteger)(r * (CGFloat)255),
            (NSUInteger)(g * (CGFloat)255),
            (NSUInteger)(b * (CGFloat)255)];
}

@end
