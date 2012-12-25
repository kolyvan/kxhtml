//
//  NSString+HTML.m
//  kxhtmlrender
//
//  Created by Kolyvan on 24.12.12.
//

#import "NSString+HTML.h"

static NSString * stringFromHTMLSymbol(NSString * s)
{
    if ([s hasPrefix:@"#"]) {
        
        unichar ch = (unichar)[[s substringFromIndex:1] integerValue];
        return [NSString stringWithFormat:@"%C", ch];
    }
     
    static NSDictionary *symbols;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
        
        //  This HTML symbols taken from DTFoundation
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
        
        
		symbols = [[NSDictionary alloc] initWithObjectsAndKeys:
                @"\x22", @"quot",
                @"\x26", @"amp",
                @"\x27", @"apos",
                @"\x3c", @"lt",
                @"\x3e", @"gt",
                @"\u00a0", @"nbsp",
                @"\u00a1", @"iexcl",
                @"\u00a2", @"cent",
                @"\u00a3", @"pound",
                @"\u00a4", @"curren",
                @"\u00a5", @"yen",
                @"\u00a6", @"brvbar",
                @"\u00a7", @"sect",
                @"\u00a8", @"uml",
                @"\u00a9", @"copy",
                @"\u00aa", @"ordf",
                @"\u00ab", @"laquo",
                @"\u00ac", @"not",
                @"\u00ae", @"reg",
                @"\u00af", @"macr",
                @"\u00b0", @"deg",
                @"\u00b1", @"plusmn",
                @"\u00b2", @"sup2",
                @"\u00b3", @"sup3",
                @"\u00b4", @"acute",
                @"\u00b5", @"micro",
                @"\u00b6", @"para",
                @"\u00b7", @"middot",
                @"\u00b8", @"cedil",
                @"\u00b9", @"sup1",
                @"\u00ba", @"ordm",
                @"\u00bb", @"raquo",
                @"\u00bc", @"frac14",
                @"\u00bd", @"frac12",
                @"\u00be", @"frac34",
                @"\u00bf", @"iquest",
                @"\u00c0", @"Agrave",
                @"\u00c1", @"Aacute",
                @"\u00c2", @"Acirc",
                @"\u00c3", @"Atilde",
                @"\u00c4", @"Auml",
                @"\u00c5", @"Aring",
                @"\u00c6", @"AElig",
                @"\u00c7", @"Ccedil",
                @"\u00c8", @"Egrave",
                @"\u00c9", @"Eacute",
                @"\u00ca", @"Ecirc",
                @"\u00cb", @"Euml",
                @"\u00cc", @"Igrave",
                @"\u00cd", @"Iacute",
                @"\u00ce", @"Icirc",
                @"\u00cf", @"Iuml",
                @"\u00d0", @"ETH",
                @"\u00d1", @"Ntilde",
                @"\u00d2", @"Ograve",
                @"\u00d3", @"Oacute",
                @"\u00d4", @"Ocirc",
                @"\u00d5", @"Otilde",
                @"\u00d6", @"Ouml",
                @"\u00d7", @"times",
                @"\u00d8", @"Oslash",
                @"\u00d9", @"Ugrave",
                @"\u00da", @"Uacute",
                @"\u00db", @"Ucirc",
                @"\u00dc", @"Uuml",
                @"\u00dd", @"Yacute",
                @"\u00de", @"THORN",
                @"\u00df", @"szlig",
                @"\u00e0", @"agrave",
                @"\u00e1", @"aacute",
                @"\u00e2", @"acirc",
                @"\u00e3", @"atilde",
                @"\u00e4", @"auml",
                @"\u00e5", @"aring",
                @"\u00e6", @"aelig",
                @"\u00e7", @"ccedil",
                @"\u00e8", @"egrave",
                @"\u00e9", @"eacute",
                @"\u00ea", @"ecirc",
                @"\u00eb", @"euml",
                @"\u00ec", @"igrave",
                @"\u00ed", @"iacute",
                @"\u00ee", @"icirc",
                @"\u00ef", @"iuml",
                @"\u00f0", @"eth",
                @"\u00f1", @"ntilde",
                @"\u00f2", @"ograve",
                @"\u00f3", @"oacute",
                @"\u00f4", @"ocirc",
                @"\u00f5", @"otilde",
                @"\u00f6", @"ouml",
                @"\u00f7", @"divide",
                @"\u00f8", @"oslash",
                @"\u00f9", @"ugrave",
                @"\u00fa", @"uacute",
                @"\u00fb", @"ucirc",
                @"\u00fc", @"uuml",
                @"\u00fd", @"yacute",
                @"\u00fe", @"thorn",
                @"\u00ff", @"yuml",
                @"\u0152", @"OElig",
                @"\u0153", @"oelig",
                @"\u0160", @"Scaron",
                @"\u0161", @"scaron",
                @"\u0178", @"Yuml",
                @"\u0192", @"fnof",
                @"\u02c6", @"circ",
                @"\u02dc", @"tilde",
                @"\u0393", @"Gamma",
                @"\u0394", @"Delta",
                @"\u0398", @"Theta",
                @"\u039b", @"Lambda",
                @"\u039e", @"Xi",
                @"\u03a3", @"Sigma",
                @"\u03a5", @"Upsilon",
                @"\u03a6", @"Phi",
                @"\u03a8", @"Psi",
                @"\u03a9", @"Omega",
                @"\u03b1", @"alpha",
                @"\u0391", @"Alpha",
                @"\u03b2", @"beta",
                @"\u0392", @"Beta",
                @"\u03b3", @"gamma",
                @"\u03b4", @"delta",
                @"\u03b5", @"epsilon",
                @"\u0395", @"Epsilon",
                @"\u03b6", @"zeta",
                @"\u0396", @"Zeta",
                @"\u03b7", @"eta",
                @"\u0397", @"Eta",
                @"\u03b8", @"theta",
                @"\u03b9", @"iota",
                @"\u0399", @"Iota",
                @"\u03ba", @"kappa",
                @"\u039a", @"Kappa",
                @"\u03bb", @"lambda",
                @"\u03bc", @"mu",
                @"\u039c", @"Mu",
                @"\u03bd", @"nu",
                @"\u039d", @"Nu",
                @"\u03be", @"xi",
                @"\u03bf", @"omicron",
                @"\u039f", @"Omicron",
                @"\u03c0", @"pi",
                @"\u03a0", @"Pi",
                @"\u03c1", @"rho",
                @"\u03a1", @"Rho",
                @"\u03c2", @"sigmaf",
                @"\u03c3", @"sigma",
                @"\u03c4", @"tau",
                @"\u03a4", @"Tau",
                @"\u03c5", @"upsilon",
                @"\u03c6", @"phi",
                @"\u03c7", @"chi",
                @"\u03a7", @"Chi",
                @"\u03c8", @"psi",
                @"\u03c9", @"omega",
                @"\u03d1", @"thetasym",
                @"\u03d2", @"upsih",
                @"\u03d6", @"piv",
                @"\u2002", @"ensp",
                @"\u2003", @"emsp",
                @"\u2009", @"thinsp",
                @"\u2013", @"ndash",
                @"\u2014", @"mdash",
                @"\u2018", @"lsquo",
                @"\u2019", @"rsquo",
                @"\u201a", @"sbquo",
                @"\u201c", @"ldquo",
                @"\u201d", @"rdquo",
                @"\u201e", @"bdquo",
                @"\u2020", @"dagger",
                @"\u2021", @"Dagger",
                @"\u2022", @"bull",
                @"\u2026", @"hellip",
                @"\u2030", @"permil",
                @"\u2032", @"prime",
                @"\u2033", @"Prime",
                @"\u2039", @"lsaquo",
                @"\u203a", @"rsaquo",
                @"\u203e", @"oline",
                @"\u2044", @"frasl",
                @"\u20ac", @"euro",
                @"\u2111", @"image",
                @"\u2118", @"weierp",
                @"\u211c", @"real",
                @"\u2122", @"trade",
                @"\u2135", @"alefsym",
                @"\u2190", @"larr",
                @"\u2191", @"uarr",
                @"\u2192", @"rarr",
                @"\u2193", @"darr",
                @"\u2194", @"harr",
                @"\u21b5", @"crarr",
                @"\u21d0", @"lArr",
                @"\u21d1", @"uArr",
                @"\u21d2", @"rArr",
                @"\u21d3", @"dArr",
                @"\u21d4", @"hArr",
                @"\u2200", @"forall",
                @"\u2202", @"part",
                @"\u2203", @"exist",
                @"\u2205", @"empty",
                @"\u2207", @"nabla",
                @"\u2208", @"isin",
                @"\u2209", @"notin",
                @"\u220b", @"ni",
                @"\u220f", @"prod",
                @"\u2211", @"sum",
                @"\u2212", @"minus",
                @"\u2217", @"lowast",
                @"\u221a", @"radic",
                @"\u221d", @"prop",
                @"\u221e", @"infin",
                @"\u2220", @"ang",
                @"\u2227", @"and",
                @"\u2228", @"or",
                @"\u2229", @"cap",
                @"\u222a", @"cup",
                @"\u222b", @"int",
                @"\u2234", @"there4",
                @"\u223c", @"sim",
                @"\u2245", @"cong",
                @"\u2248", @"asymp",
                @"\u2260", @"ne",
                @"\u2261", @"equiv",
                @"\u2264", @"le",
                @"\u2265", @"ge",
                @"\u2282", @"sub",
                @"\u2283", @"sup",
                @"\u2284", @"nsub",
                @"\u2286", @"sube",
                @"\u2287", @"supe",
                @"\u2295", @"oplus",
                @"\u2297", @"otimes",
                @"\u22a5", @"perp",
                @"\u22c5", @"sdot",
                @"\u2308", @"lceil",
                @"\u2309", @"rceil",
                @"\u230a", @"lfloor",
                @"\u230b", @"rfloor",
                @"\u27e8", @"lang",
                @"\u27e9", @"rang",
                @"\u25ca", @"loz",
                @"\u2660", @"spades",
                @"\u2663", @"clubs",
                @"\u2665", @"hearts",
                @"\u2666", @"diams",
                nil];
	});
    
    NSString *x = symbols[s];
    return x ? x : [NSString stringWithFormat:@"&%@;", s];
}

@implementation NSString (HTML)

- (NSString *)unescapeHTML
{
    NSMutableString *ms = [NSMutableString string];
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    while (!scanner.isAtEnd) {
        
        NSString *s;
        
        if ([scanner scanUpToString:@"&" intoString:&s])
            [ms appendString:s];
        
        if (![scanner scanString:@"&" intoString:nil])
            break;
        
        if ([scanner scanUpToString:@";" intoString:&s]) {
            
            if ([scanner scanString:@";" intoString:nil]) {
                
                [ms appendString:stringFromHTMLSymbol(s)];
                
            } else {
                
                [ms appendString:@"&"];
                [ms appendString:s];
            }
        }
    }
   
    return ms;
}

@end
