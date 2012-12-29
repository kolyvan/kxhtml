//
//  KxHTML.m
//  KxHTML
//
//  Created by Kolyvan on 20.12.12.
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

#import "KxHTML.h"
#import "DTHTMLParser.h"
#import "UIColor+HTML.h"
#import "NSString+HTML.h"
#import "hyphenation.h"

#define DEFAULT_FONT_FAMILY @"Helvetica"
#define DEFAULT_FONT_SIZE 14
#define DEFAULT_IMAGE_SIZE 128

#define LISTITEM_MARK @"-"
// "\u26AB" 2022 26AA

#define MAX_WIDTH 9999

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#pragma mark - render primitives

typedef struct
{
    CGPoint point;  // position for inline element
    CGFloat line;   // position for block element
    
} KxAnchor;

static CGFloat wordSpaceWidth(UIFont *font)
{
    return [@" " sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping].width;
}

static void renderTextDecoration(CGContextRef context,
                                 KxHTMLRenderStyleTextDecoration decoration,
                                 BOOL isHyperlink,
                                 UIFont *font,
                                 UIColor *color,                                 
                                 CGPoint pt,
                                 float w)
{
    if (isHyperlink) {
        
        const float ly = roundf(pt.y + font.lineHeight + font.descender + 1)+0.5f;
        CGContextSetStrokeColorWithColor(context, color.CGColor);
        CGFloat lineDash[2] = {2,2};
        CGContextSetLineDash(context, 0, lineDash, 2);
        CGContextMoveToPoint(context, pt.x, ly);
        CGContextAddLineToPoint(context, pt.x + w, ly);
        CGContextStrokePath(context);
    }
    
    else if (decoration == KxHTMLRenderStyleTextDecorationLineThrough) {
        
        const float ly = roundf(pt.y + font.lineHeight/2.0f + 1)+0.5f;
        CGContextSetGrayStrokeColor(context, 0.2, 1.0);
        CGContextSetLineDash(context, 0, NULL, 0);
        CGContextMoveToPoint(context, pt.x, ly);
        CGContextAddLineToPoint(context, pt.x + w, ly);
        CGContextStrokePath(context);
    }
    
    else if (decoration == KxHTMLRenderStyleTextDecorationUnderline) {
        
        const float ly = roundf(pt.y + font.lineHeight + font.descender + 1)+0.5f;
        CGContextSetGrayStrokeColor(context, 0.2, 1.0);
        CGContextSetLineDash(context, 0, NULL, 0);
        CGContextMoveToPoint(context, pt.x, ly);
        CGContextAddLineToPoint(context, pt.x + w, ly);
        CGContextStrokePath(context);
    }
}

static KxAnchor renderWord(CGContextRef context,
                           NSString *word,
                           UIFont *font,
                           KxAnchor anchor,
                           float X0,
                           float X1,
                           KxHTMLRenderStyleTextDecoration decoration,
                           BOOL isHyperlink, 
                           UIColor *color)
{
    float w = [word sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping].width;
    
    if (w > (X1 - anchor.point.x)) {
        
        NSArray *hyphens = isHyperlink ? hyphenateHyperlink(word) : hyphenateWord(word);
        
        for (NSNumber *n in hyphens) {
            
            const NSUInteger position = n.integerValue;
            //NSString *s = [NSString stringWithFormat:@"%@-", [word substringToIndex:position]];
            NSString *s = [word substringToIndex:position];
            CGSize sz = [s sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping];
            if (sz.width < (X1 - anchor.point.x)) {
                
                [s drawAtPoint:anchor.point
                      forWidth:(X1 - anchor.point.x)
                      withFont:font
                 lineBreakMode:NSLineBreakByClipping];
                
                if (isHyperlink || decoration != KxHTMLRenderStyleTextDecorationNone)
                    renderTextDecoration(context, decoration, isHyperlink, font, color, anchor.point, sz.width);
                
                word = [word substringFromIndex:position];
                w = [word sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping].width;
                
                break;
            }
        }
                
        anchor.point.x = X0;
        anchor.point.y += font.lineHeight;
        if (anchor.point.y < anchor.line)
            anchor.point.y = anchor.line;        
    }
    
    [word drawAtPoint:anchor.point
                 forWidth:(X1 - anchor.point.x)
                 withFont:font
            lineBreakMode:NSLineBreakByClipping];
    
    if (isHyperlink || decoration != KxHTMLRenderStyleTextDecorationNone)
        renderTextDecoration(context, decoration, isHyperlink, font, color, anchor.point, w);
    
    anchor.point.x += w;
    return anchor;
}

static KxAnchor layoutWord(NSString *word,
                           UIFont *font,
                           KxAnchor anchor,
                           float width,
                           BOOL isHyperlink)
{
    float w = [word sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping].width;
    
    if (w > (width - anchor.point.x)) {
                    
        NSArray *hyphens = isHyperlink ? hyphenateHyperlink(word) : hyphenateWord(word);
        for (NSNumber *n in hyphens) {
            
            const NSUInteger position = n.integerValue;
            //NSString *s = [NSString stringWithFormat:@"%@-", [word substringToIndex:position]];
            NSString *s = [word substringToIndex:position];
            CGSize sz = [s sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping];
            if (sz.width < (width - anchor.point.x)) {
                word = [word substringFromIndex:position];
                w = [word sizeWithFont:font forWidth:MAX_WIDTH lineBreakMode:NSLineBreakByClipping].width;
                break;
            }
        }
        
        anchor.point.x = 0;
        anchor.point.y += font.lineHeight;
        if (anchor.point.y < anchor.line)
            anchor.point.y = anchor.line;
    }
    
    anchor.point.x += w;
    return anchor;
}

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#pragma mark - nodes

@protocol KxHTMLNode <NSObject>

- (KxAnchor) render: (CGRect) bounds
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
            context: (CGContextRef) context;

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet;

- (NSString *) asHTMLString;

@optional
@property (readwrite, nonatomic, strong) KxHTMLRenderStyle *inlineStyle;

@end

@interface KxHTMLElement : NSObject<KxHTMLNode>

@property (readonly, nonatomic, strong) NSString *elementName;
@property (readwrite, nonatomic) NSString *cssClass;
@property (readonly, nonatomic, strong) NSArray *childNodes;
@property (readwrite, nonatomic, strong) KxHTMLRenderStyle *inlineStyle;

- (id) initWithElementName: (NSString *) name;
- (void) appendChild: (id<KxHTMLNode>) child;
- (NSArray *) collectNodes: (Class) klass;
- (KxHTMLRenderStyle *) actualStyle: (KxHTMLRenderStyle *) style
                         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet;
@end

@implementation KxHTMLElement {
    
    NSMutableArray *_nodes;
}

- (id) initWithElementName: (NSString *) name
{
    self = [super init];
    if (self) {
        _elementName = name;
        _nodes = [NSMutableArray array];
    }
    return self;
}

@dynamic childNodes;
- (NSArray *) childNodes
{
    return _nodes;
}

- (void) appendChild: (id<KxHTMLNode>) child
{
    [_nodes addObject:child];
}

- (KxAnchor) render: (CGRect) bounds
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
            context: (CGContextRef) context
{   
    const float Y = bounds.origin.y + bounds.size.height;
    for (id<KxHTMLNode> node in _nodes) {
        if (anchor.line > Y)
            break;
        anchor = [node render:bounds
                       anchor:anchor
                        style:style
                   styleSheet:styleSheet
                      context:context];

    }
    return anchor;
}

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
{
    for (id<KxHTMLNode> node in _nodes) {
        
        anchor = [node layout:width
                       anchor:anchor
                        style:style
                   styleSheet:styleSheet];
    }
    return anchor;
}

- (NSArray *) collectNodes: (Class) klass
{
    NSMutableArray *ma = nil;
    
    for (id p in _nodes) {
        
        if ([p isKindOfClass:klass]) {
            
            if (!ma)
                ma = [NSMutableArray array];
            [ma addObject:p];
        }
        
        if ([p isKindOfClass:[KxHTMLElement class]]) {
            
            NSArray * a = [((KxHTMLElement*)p) collectNodes:klass];
            if (a.count) {
                
                if (ma)
                    [ma addObjectsFromArray:a];
                else
                    ma = (NSMutableArray *)a;
            }
            
        }
    }
    
    return ma;
}

- (KxHTMLRenderStyle *) actualStyle: (KxHTMLRenderStyle *) parentStyle
                         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet

{
    KxHTMLRenderStyle *style = [[KxHTMLRenderStyle alloc] init];
    
    KxHTMLRenderStyle *p;
    p = [styleSheet lookupStyle:_elementName];
    if (p)
        [style compose:p];
    
    if (_cssClass.length) {
        
        p = [styleSheet lookupStyle:[NSString stringWithFormat:@".%@", _cssClass]];
        if (p)
            [style compose:p];
        
        p = [styleSheet lookupStyle:[NSString stringWithFormat:@"%@.%@", _elementName, _cssClass]];
        if (p)
            [style compose:p];
    }
    
    if (_inlineStyle)
        [style compose:_inlineStyle];
    
    [style inherit:parentStyle];
    return style;
}

- (NSString *) description
{
    return [NSString stringWithFormat:@"<%@>", _elementName];
}

- (NSString *) asHTMLString
{
    NSMutableString *ms = [NSMutableString string];
    [ms appendFormat:@"\n<%@>\n", _elementName];
    for (id<KxHTMLNode> node in _nodes)
        [ms appendString: [node asHTMLString]];
    [ms appendFormat:@"\n</%@>\n", _elementName];
    return ms;
}

@end

///

@interface KxHTMLLineBreakNode : NSObject<KxHTMLNode>
@end

@implementation KxHTMLLineBreakNode

- (KxAnchor) render: (CGRect) bounds
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
            context: (CGContextRef) context
{
    if (anchor.point.x > bounds.origin.x)
        anchor.point.x = bounds.origin.x;
    else
        anchor.line += style.font.lineHeight;
    anchor.point.y = anchor.line;
    return anchor;
}

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
{
    if (anchor.point.x > 0)
        anchor.point.x = 0;
    else
        anchor.line += style.font.lineHeight;
    anchor.point.y = anchor.line;
    return anchor;
}

- (NSString *) asHTMLString
{
   return @"<br>";
}

@end

///

@interface KxHTMLBlockElement : KxHTMLElement

@property (readwrite, nonatomic) CGSize size;

- (void) fillBackground: (KxHTMLRenderStyle *) style
                  point: (CGPoint) point
                context: (CGContextRef) context;


- (KxAnchor) renderSelf: (CGRect) bounds
                 anchor: (KxAnchor) anchor
            actualStyle: (KxHTMLRenderStyle *) style
                context: (CGContextRef) context;

- (KxAnchor) layoutSelf: (CGFloat) width
                 anchor: (KxAnchor) anchor
            actualStyle: (KxHTMLRenderStyle *) style;

@end

@implementation KxHTMLBlockElement

- (CGRect) marginLeftRight: (KxHTMLRenderStyle *) style
                    bounds: (CGRect) bounds
{
    if (style.marginLeft) {
        
        bounds.origin.x += [style.marginLeft sizeWithFont: style.font];
        bounds.size.width -= [style.marginLeft sizeWithFont: style.font];
    }
    
    if (style.marginRight)
        bounds.size.width -= [style.marginRight sizeWithFont: style.font];
    
    return bounds;
}

- (CGFloat) marginLeftRight: (KxHTMLRenderStyle *) style
                      width: (CGFloat) width
{
    if (style.marginLeft)
        width -= [style.marginLeft sizeWithFont: style.font];
    if (style.marginRight)
        width -= [style.marginRight sizeWithFont: style.font];
    return width;
}

- (KxAnchor) marginTop: (KxHTMLRenderStyle *) style
                anchor: (KxAnchor) anchor
{
    if (style.marginTop) {
        const float m = [style.marginTop sizeWithFont: style.font];
        anchor.point.y += m;
        anchor.line += m;
    }
    return anchor;
}

- (KxAnchor) marginBottom: (KxHTMLRenderStyle *) style
                   anchor: (KxAnchor) anchor
{
    if (style.marginBottom) {
        const float m = [style.marginBottom sizeWithFont: style.font];
        anchor.point.y += m;
        anchor.line += m;
    }
    return anchor;
}

- (void) fillBackground: (KxHTMLRenderStyle *) style
                  point: (CGPoint) point
                context: (CGContextRef) context
{
    if (style.backColor) {
        
        [style.backColor set];
        CGRect r = {point, _size};
        CGContextFillRect(context, r);
    }
}
 
- (KxAnchor) render: (CGRect) bounds
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
            context: (CGContextRef) context
{
    style = [self actualStyle:style styleSheet:styleSheet];
    
    CGRect r = [self marginLeftRight:style bounds:bounds];
    anchor = [self marginTop:style anchor:anchor];
    
    anchor.point.x = r.origin.x;
    anchor.point.y = anchor.line;
    
    [self fillBackground:style point:anchor.point context:context];
    anchor = [self renderSelf:r anchor:anchor actualStyle:style context:context];
    anchor = [super render:r anchor:anchor style:style styleSheet: styleSheet context:context];
    anchor = [self marginBottom:style anchor:anchor];

    anchor.point.x = bounds.origin.x;
    anchor.point.y = anchor.line;
    
    return anchor;
}

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
{
    style = [self actualStyle:style styleSheet:styleSheet];

    width = [self marginLeftRight:style width:width];
    anchor = [self marginTop:style anchor:anchor];
    
    anchor.point.x = 0;
    anchor.point.y = anchor.line;
    
    const float Y = anchor.line;
    anchor = [self layoutSelf:width anchor:anchor actualStyle:style];
    anchor = [super layout:width anchor:anchor style:style styleSheet:styleSheet];
    
    _size.width = width;
    _size.height = anchor.line - Y;
    
    anchor = [self marginBottom:style anchor:anchor];
    
    anchor.point.x = 0;
    anchor.point.y = anchor.line;
    
    return anchor;
}

- (KxAnchor) renderSelf: (CGRect) bounds
                 anchor: (KxAnchor) anchor
           actualStyle: (KxHTMLRenderStyle *) style
               context: (CGContextRef) context
{
    return anchor;
}

- (KxAnchor) layoutSelf: (CGFloat) width
                 anchor: (KxAnchor) anchor
            actualStyle: (KxHTMLRenderStyle *) style
{
    return anchor;
}

@end

///

@interface KxHTMLInlineElement : KxHTMLElement {
    
    CGSize _headSize, _bodySize, _tailSize;
    CGRect _headRect, _bodyRect, _tailRect;
}
@end

@implementation KxHTMLInlineElement

- (void) saveRect: (KxAnchor) anchor
             left: (CGFloat) left
{
    _headRect.origin = anchor.point;
    _headRect.size = _headSize;

    _bodyRect.origin.x = left;
    _bodyRect.origin.y = anchor.line;
    _bodyRect.size = _bodySize;
    
    _tailRect.origin.x = left;
    _tailRect.origin.y = anchor.line + _bodySize.height;
    _tailRect.size = _tailSize;
}

- (void) fillBackground: (KxHTMLRenderStyle *) style
                context: (CGContextRef) context
{
    if (style.backColor) {
        
        [style.backColor set];
        
        CGContextFillRect(context, _headRect);
        if (_bodySize.width > 0 && _bodySize.height > 0)
            CGContextFillRect(context, _bodyRect);
        if (_tailSize.width > 0 && _tailSize.height > 0)
            CGContextFillRect(context, _tailRect);
    }
}

- (BOOL) hitTest: (CGPoint) loc
{
    if (CGRectContainsPoint(_headRect, loc) ||
        CGRectContainsPoint(_bodyRect, loc) ||
        CGRectContainsPoint(_tailRect, loc))
        return YES;
    return NO;
}

- (KxAnchor) render: (CGRect) bounds
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
            context: (CGContextRef) context
{
    style = [self actualStyle:style styleSheet:styleSheet];

    if (style.marginLeft)
        anchor.point.x += [style.marginLeft sizeWithFont: style.font];

    [self saveRect:anchor left:bounds.origin.x];
    [self fillBackground:style context:context];
    anchor = [super render:bounds anchor:anchor style:style styleSheet: styleSheet context:context];
    
    if (style.marginRight)
        anchor.point.x += [style.marginLeft sizeWithFont: style.font];

    return anchor;
}

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
{
    style = [self actualStyle:style styleSheet:styleSheet];
        
    if (style.marginLeft)
        anchor.point.x += [style.marginLeft sizeWithFont: style.font];
    
    KxAnchor a = anchor;
    
    anchor = [super layout:width anchor:anchor style:style styleSheet:styleSheet];
    
    if (a.point.y == anchor.point.y) {
    
        _headSize.width = anchor.point.x - a.point.x;
        _headSize.height = anchor.line - a.point.y;
        _bodySize.height = _tailSize.height = 0;
        
    } else {
    
        _headSize.width = width - a.point.x;
        _headSize.height = a.line - a.point.y;
        
        _bodySize.width = width;
        _bodySize.height = anchor.point.y - a.line;
        
        _tailSize.width = anchor.point.x;
        _tailSize.height = anchor.line - anchor.point.y;
    }
    
    if (style.marginRight)
        anchor.point.x += [style.marginRight sizeWithFont: style.font];
    
    return anchor;
}

@end

///

@interface KxHTMLTextNode : NSObject<KxHTMLNode>
@property (readwrite, nonatomic, strong) KxHTMLRenderStyle *inlineStyle;
@end

@implementation KxHTMLTextNode {
    
    NSString            *_text;
}

- (id) initWithText: (NSString *) text
{
    self = [super init];
    if (self) {
        _text = text;
    }
    return self;
}

- (KxAnchor) render: (CGRect) bounds
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
            context: (CGContextRef) context
{
    if (_inlineStyle) {
        
        style = [style copy];
        [style compose:_inlineStyle];
    }
    
    const KxHTMLRenderStyleTextDecoration decoration = style.textDecoration.integerValue;
    const BOOL isHyperlink = style.hyperlink.boolValue;
    UIFont *font = style.font;
    UIColor *color = style.color;
    [color set];
    
    const float X0 = bounds.origin.x;
    const float X1 = bounds.origin.x + bounds.size.width;
    const float Y = bounds.origin.y + bounds.size.height;
    const float W = X1 - anchor.point.x;
    
    const float w = [_text sizeWithFont:font
                               forWidth:MAX_WIDTH
                          lineBreakMode:NSLineBreakByClipping].width;
    
    if (w < W) {
        
        CGPoint point = anchor.point;
        
        if (style.textAlign) {
        
            const KxHTMLRenderStyleTextAlign align = style.textAlign.integerValue;
            
            if (align == KxHTMLRenderStyleTextAlignCenter) {
                
                point.x += (W - w) * 0.5;
                
            } else if (align == KxHTMLRenderStyleTextAlignRight) {
                
                point.x = W - w;
            }
        }
        
        [_text drawAtPoint:point
                  forWidth:MAX_WIDTH
                  withFont:font
             lineBreakMode:NSLineBreakByClipping];
        
        if (isHyperlink || decoration != KxHTMLRenderStyleTextDecorationNone)
            renderTextDecoration(context, decoration, isHyperlink, font, color, point, w);
        
        point.x += w;
        anchor.point = point;
        
    } else {
    
        const float wordSpace = wordSpaceWidth(font);
        
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray *words = [_text componentsSeparatedByCharactersInSet:whitespace];
                
        for (NSString *word in words) {
            
            if (word.length && anchor.point.y < Y) {
                
                anchor = renderWord(context, word, font, anchor, X0, X1, decoration, isHyperlink, color);
                if (word != words.lastObject) {
                    
                    if (isHyperlink || decoration != KxHTMLRenderStyleTextDecorationNone)
                        renderTextDecoration(context, decoration, isHyperlink, font, color, anchor.point, wordSpace);
                    
                    anchor.point.x += wordSpace;
                }
            }
        }
    }
        
    const float ly = anchor.point.y + font.lineHeight;
    if (ly > anchor.line)
        anchor.line = ly;
    
    return anchor;
}

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
{
    if (_inlineStyle) {
        
        style = [style copy];
        [style compose:_inlineStyle];
    }
    
    UIFont *font = style.font;
    
    const float W = width - anchor.point.x;    
    
    const float w = [_text sizeWithFont:font
                               forWidth:MAX_WIDTH
                          lineBreakMode:NSLineBreakByClipping].width;
    
    if (w < W) {
        
        CGPoint point = anchor.point;
        
        if (style.textAlign) {
            
            const KxHTMLRenderStyleTextAlign align = style.textAlign.integerValue;
            
            if (align == KxHTMLRenderStyleTextAlignCenter) {
                
                point.x += (W - w) * 0.5;
                
            } else if (align == KxHTMLRenderStyleTextAlignRight) {
                
                point.x = W - w;
            }
        }
        
        point.x += w;
        anchor.point = point;
        
    } else {
    
        const float wordSpace = wordSpaceWidth(font);
        
        NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray *words = [_text componentsSeparatedByCharactersInSet:whitespace];
        
        for (NSString *word in words) {
            
            if (word.length) {
                
                anchor = layoutWord(word, font, anchor, width, style.hyperlink.boolValue);
                if (word != words.lastObject)
                    anchor.point.x += wordSpace;
            }
        }
    }
    
    const float ly = anchor.point.y + font.lineHeight;
    if (ly > anchor.line)
        anchor.line = ly;
    
    return anchor;
}

- (NSString *) asHTMLString
{
    return _text;
}

@end

///

@interface KxHTMLImageNode : NSObject<KxHTMLNode>
@property (readonly, nonatomic, strong) NSString *src;
@end

@implementation KxHTMLImageNode {
    
    NSString    *_alt;
    NSUInteger  _width;
    NSUInteger  _height;
    UIImage     *_image;
    BOOL        _loaded;
}

- (id) initWithSource: (NSString *) src
              altText: (NSString *) alt
           imageWidth: (NSUInteger) width
          imageHeight: (NSUInteger) height
{
    self = [super init];
    if (self) {
        
        _src = src;
        _alt = alt;
        
        if (width || height) {
            
            _width = width ? width : height ? height : DEFAULT_IMAGE_SIZE;
            _height = height ? height : width ? width : DEFAULT_IMAGE_SIZE;
            
        } else {
            
            _width = DEFAULT_IMAGE_SIZE;
            _height = DEFAULT_IMAGE_SIZE;
        }
        
    }
    return self;
}

- (KxAnchor) render: (CGRect) bounds
            anchor: (KxAnchor) anchor
             style: (KxHTMLRenderStyle *) style
        styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
           context: (CGContextRef) context
{
    const float X = bounds.origin.x;
    const float W = bounds.size.width;
    
    if (anchor.point.x > X &&
        (anchor.point.x  + _width) > W) {
        
        anchor.point.x = X;
        anchor.point.y = anchor.line;
    }
    
    CGRect r = CGRectMake(anchor.point.x, anchor.point.y, _width, _height);
        
    if (_image) {
        
        [_image drawInRect:r];
        
    } else {
        
        NSString *text = _loaded ? _alt : NSLocalizedString(@"loading..", NULL);
        
        if (text.length) {
            
            [[UIColor lightGrayColor] set];
            CGContextFillRect(context, r);
            
            [[UIColor darkGrayColor] set];
            
            const CGSize size = [text sizeWithFont:style.font];
            
            CGPoint pt = anchor.point;
            if (size.width < _width)
                pt.x +=  (_width - size.width) * 0.5;
            if (size.height < _height)
                pt.y +=  (_height - size.height) * 0.5;
            
            [text drawAtPoint:pt
                     forWidth:_width
                     withFont:style.font
                lineBreakMode:NSLineBreakByTruncatingTail];
        }
    }

    anchor.point.x += _width;
    
    const float ly = anchor.point.y + _height;
    if (ly > anchor.line)
        anchor.line = ly;
    
    return anchor;
}

- (KxAnchor) layout: (CGFloat) width
             anchor: (KxAnchor) anchor
              style: (KxHTMLRenderStyle *) style
         styleSheet: (KxHTMLRenderStyleSheet *) styleSheet
{
    if (anchor.point.x > 0 &&
        (anchor.point.x  + _width) > width) {
        
        anchor.point.x = 0;
        anchor.point.y = anchor.line;
    }
    
    anchor.point.x += _width;
    
    const float ly = anchor.point.y + _height;
    if (ly > anchor.line)
        anchor.line = ly;
    
    return anchor;
}

- (void) didLoadImage: (UIImage *) image
{
    _image = image;
    _loaded = YES;
}

- (NSString *) asHTMLString
{
    return [NSString stringWithFormat: @"<img src='%@'>", _src];
}

@end

///

@interface KxHTMLHyperlinkElement : KxHTMLInlineElement
@property (readonly, nonatomic, strong) NSURL *url;
@end

@implementation KxHTMLHyperlinkElement {
        
}

- (id) initWithURL: (NSURL *) url
{
    self = [super initWithElementName:@"a"];
    if (self) {
        _url = url;
    }
    return self;
}
 
- (NSString *) asHTMLString
{
    NSMutableString *ms = [NSMutableString string];
    [ms appendFormat:@"<a href='%@'>", _url];
    for (id<KxHTMLNode> node in self.childNodes)
        [ms appendString: [node asHTMLString]];
    [ms appendString:@"</a>"];
    return ms;
}

@end

@interface KxHTMLListItemElement : KxHTMLBlockElement
@end

@implementation KxHTMLListItemElement

- (id) init
{
    return [super initWithElementName:@"li"];
}

- (KxAnchor) renderSelf: (CGRect) bounds
                 anchor: (KxAnchor) anchor
            actualStyle: (KxHTMLRenderStyle *) style
                context: (CGContextRef) context
{
    [[UIColor blackColor] set];
    
    anchor.point.x += [LISTITEM_MARK drawAtPoint:anchor.point
                                        forWidth:MAX_WIDTH
                                        withFont:style.font
                                   lineBreakMode:NSLineBreakByClipping].width;
    anchor.point.x += wordSpaceWidth(style.font);
    return anchor;
}

- (KxAnchor) layoutSelf: (CGFloat) width
                 anchor: (KxAnchor) anchor
            actualStyle: (KxHTMLRenderStyle *) style
{
    anchor.point.x += [LISTITEM_MARK sizeWithFont:style.font
                                         forWidth:MAX_WIDTH
                                    lineBreakMode:NSLineBreakByClipping].width;
    anchor.point.x += wordSpaceWidth(style.font);
    return anchor;
}

@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#pragma mark - parser

typedef enum {
    
    KxHTMLReaderTextAttributeNone           = 0,
    KxHTMLReaderTextAttributeBold           = 1 << 0,
    KxHTMLReaderTextAttributeItalic         = 1 << 1,
    KxHTMLReaderTextAttributeUnderline      = 1 << 2,
    KxHTMLReaderTextAttributeStrikeout      = 1 << 3,
    
} KxHTMLReaderTextAttribute;


@interface KxHTMLReader: NSObject<DTHTMLParserDelegate>
@property (readonly, nonatomic, strong)  KxHTMLElement *head;
@property (readonly, nonatomic, strong)  KxHTMLElement *body;
@property (readonly, nonatomic, strong)  KxHTMLRenderStyleSheet *styleSheet;
@end

@implementation KxHTMLReader {
    
    NSMutableArray              *_stack;
    NSMutableString             *_text;
    UIColor                     *_textColor;
    KxHTMLReaderTextAttribute   _textAttribute;
    BOOL                        _preformated;
    BOOL                        _styleElement;
}

- (id) init
{
    self = [super init];
    if (self) {
                
        _stack = [NSMutableArray array];
        _text = [NSMutableString string];
    }
    return self;
}

- (KxHTMLElement *) currentContainer
{
    return _stack.count ? _stack.lastObject : _body ? _body : _head;
}

- (void)parser:(DTHTMLParser *)parser didStartElement:(NSString *)elementName attributes:(NSDictionary *)attributeDict
{    
    [self flushText];
    
    elementName = elementName.lowercaseString;
    KxHTMLElement *container = self.currentContainer;
    KxHTMLElement *elem;
            
    if ([elementName isEqualToString:@"br"]) {
        
        id node = [[KxHTMLLineBreakNode alloc] init];
        [container appendChild:node];
        
    } else if ([elementName isEqualToString:@"a"]) {
        
        NSString *href = [attributeDict valueForKey:@"href"];
        NSURL *url = [NSURL URLWithString:href];
        if (url) {
        
            elem = [[KxHTMLHyperlinkElement alloc] initWithURL:url];
            
        } else {
            
            // invalid href, so add simple container
            elem = [[KxHTMLElement alloc] init];
        }
        
        [container appendChild:elem];
        [_stack addObject:elem];
        
    } else if ([elementName isEqualToString:@"img"]) {
        
        id node = [[KxHTMLImageNode alloc] initWithSource:attributeDict[@"src"]
                                                  altText:attributeDict[@"alt"]
                                               imageWidth:[attributeDict[@"width"] integerValue]
                                              imageHeight:[attributeDict[@"height"] integerValue]];
        [container appendChild:node];
       
        
    } else if ([elementName isEqualToString:@"font"]) {
        
        NSString *color = [attributeDict valueForKey:@"color"];
        if (color.length)
            _textColor = [UIColor colorWithHTMLName:color];
        
    } else if ([elementName isEqualToString:@"b"] ||
               [elementName isEqualToString:@"strong"]) {
        
        _textAttribute |= KxHTMLReaderTextAttributeBold;
        
    } else if ([elementName isEqualToString:@"i"] ||
               [elementName isEqualToString:@"em"]) {
        
        _textAttribute |= KxHTMLReaderTextAttributeItalic;
                
    } else if ([elementName isEqualToString:@"u"]) {
        
        _textAttribute |= KxHTMLReaderTextAttributeUnderline;
        
    } else if ([elementName isEqualToString:@"s"]) {
        
        _textAttribute |= KxHTMLReaderTextAttributeStrikeout;
        
    } else if ([elementName isEqualToString:@"pre"]) {
        
        _preformated = YES;
    
    } else if ([elementName isEqualToString:@"li"]) {
        
        elem = [[KxHTMLListItemElement alloc] init];
        [container appendChild:elem];
        [_stack addObject:elem];
        
    } else if ([elementName isEqualToString:@"span"]) {
        
        elem = [[KxHTMLInlineElement alloc] initWithElementName:@"span"];
        [container appendChild:elem];
        [_stack addObject:elem];
        
    } else if ([elementName isEqualToString:@"div"] ||
               [elementName isEqualToString:@"p"] ||
               [elementName isEqualToString:@"blockquote"] ||
               [elementName isEqualToString:@"h1"] ||
               [elementName isEqualToString:@"h2"] ||
               [elementName isEqualToString:@"h3"]) {

        elem = [[KxHTMLBlockElement alloc] initWithElementName:elementName];
        [container appendChild:elem];
        [_stack addObject:elem];
        
    } else if ([elementName isEqualToString:@"head"]) {
        
        _head = [[KxHTMLElement alloc] initWithElementName:@"head"];
        
    } else if ([elementName isEqualToString:@"body"]) {
        
        _body = [[KxHTMLBlockElement alloc] initWithElementName:@"body"];
        
    } else if ([elementName isEqualToString:@"style"]) {
        
        _styleElement = YES;
        
    } else if ([elementName isEqualToString:@"html"]) {
        
        // ignore
        
    } else {
        
        NSLog(@"unsupported tag '%@' at %d:%d", elementName, parser.lineNumber, parser.columnNumber);
    }
    
    if (elem) {
        
        elem.cssClass = attributeDict[@"class"];
        
        NSString *inlineStyle = attributeDict[@"style"];
        if (inlineStyle)
            elem.inlineStyle = [KxHTMLRenderStyle fromCSSString:inlineStyle];
        
    }
}

- (void)parser:(DTHTMLParser *)parser didEndElement:(NSString *)elementName
{
    [self flushText];
    
    elementName = elementName.lowercaseString;
    
    if ([elementName isEqualToString:@"font"]) {
        
        _textColor = nil;
        
    } else if ([elementName isEqualToString:@"b"] ||
               [elementName isEqualToString:@"strong"]) {
        
        _textAttribute &= ~KxHTMLReaderTextAttributeBold;
        
    } else if ([elementName isEqualToString:@"i"] ||
               [elementName isEqualToString:@"em"]) {
        
        _textAttribute &= ~KxHTMLReaderTextAttributeItalic;
        
    } else if ([elementName isEqualToString:@"u"]) {
        
        _textAttribute &= ~KxHTMLReaderTextAttributeUnderline;
        
    } else if ([elementName isEqualToString:@"s"]) {
        
        _textAttribute &= ~KxHTMLReaderTextAttributeStrikeout;
        
    } else if ([elementName isEqualToString:@"pre"]) {
        
        _preformated = NO;
        
    } else if ([elementName isEqualToString:@"style"]) {
        
        _styleElement = NO;
        
    } else if ([elementName isEqualToString:@"span"] ||
               [elementName isEqualToString:@"a"] ||
               [elementName isEqualToString:@"p"] ||
               [elementName isEqualToString:@"div"] ||
               [elementName isEqualToString:@"blockquote"] ||
               [elementName isEqualToString:@"h1"] ||
               [elementName isEqualToString:@"h2"] ||
               [elementName isEqualToString:@"h3"] ||
               [elementName isEqualToString:@"li"]) {
        
        if (_stack.count)
            [_stack removeLastObject];
        else
            NSLog(@"unexpected closing of tag '%@' at %d:%d", elementName, parser.lineNumber, parser.columnNumber);
    }
}

- (void)parser:(DTHTMLParser *)parser foundCharacters:(NSString *)string
{    
    [_text appendString:string];
}

- (void)parser:(DTHTMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"parse error '%@' at %d:%d", parseError.localizedDescription, parser.lineNumber, parser.columnNumber);
}

- (void) flushText
{
    if (!_text.length)
        return;
    
    NSString *string = _text.unescapeHTML;
    _text = [NSMutableString string];
    
    if (_styleElement) {
        
        if (!_styleSheet)
            _styleSheet = [[KxHTMLRenderStyleSheet alloc] init];
        [_styleSheet addStyles:string];
        
    } else {
        
        KxHTMLElement *container = self.currentContainer;
        KxHTMLRenderStyle *style = nil;
        
        if (_textAttribute || _textColor) {
            
            style = [[KxHTMLRenderStyle alloc] init];
            style.color = _textColor;
            
            if (0 != (_textAttribute & KxHTMLReaderTextAttributeBold))
                style.fontWeight = @(KxHTMLRenderStyleFontWeightBold);
            else if (0 != (_textAttribute & KxHTMLReaderTextAttributeItalic))
                style.fontStyle = @(KxHTMLRenderStyleFontStyleOblique);
            
            if (0 != (_textAttribute & KxHTMLReaderTextAttributeStrikeout))
                style.textDecoration = @(KxHTMLRenderStyleTextDecorationLineThrough);
            else if (0 != (_textAttribute & KxHTMLReaderTextAttributeUnderline))
                style.textDecoration = @(KxHTMLRenderStyleTextDecorationUnderline);
        }
        
        if (_preformated) {
            
            KxHTMLTextNode *textNode;
            NSCharacterSet *newline = [NSCharacterSet newlineCharacterSet];
            NSArray *lines = [string componentsSeparatedByCharactersInSet:newline];
            for (NSString *line in lines) {
                
                textNode = [[KxHTMLTextNode alloc] initWithText:line];
                textNode.inlineStyle = style;
                [container appendChild:textNode];
                
                if (line != lines.lastObject) {
                    id node = [[KxHTMLLineBreakNode alloc] init];
                    [container appendChild:node];
                }
            }
            
        } else {
            
            KxHTMLTextNode *textNode = [[KxHTMLTextNode alloc] initWithText:string];
            textNode.inlineStyle = style;
            [container appendChild:textNode];
        }
    }
}

@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#pragma mark - styles

static NSString *textDecorationAsString(KxHTMLRenderStyleTextDecoration t)
{
    switch (t) {
        case KxHTMLRenderStyleTextDecorationNone: return @"none";
        case KxHTMLRenderStyleTextDecorationLineThrough: return @"line-through";
        case KxHTMLRenderStyleTextDecorationUnderline: return @"underline";
    }
}

static NSString *textAlignAsString(KxHTMLRenderStyleTextAlign t)
{
    switch (t) {
        case KxHTMLRenderStyleTextAlignLeft: return @"left";
        case KxHTMLRenderStyleTextAlignCenter: return @"center";
        case KxHTMLRenderStyleTextAlignRight: return @"right";
    }
}

static NSString *fontWeightAsString(KxHTMLRenderStyleFontWeight t)
{
    switch (t) {
        case KxHTMLRenderStyleFontWeightNormal: return @"normal";
        case KxHTMLRenderStyleFontWeightBold: return @"bold";
    }
}

static NSString *fontStyleAsString(KxHTMLRenderStyleFontStyle t)
{
    switch (t) {
        case KxHTMLRenderStyleFontStyleNormal: return @"normal";
        case KxHTMLRenderStyleFontStyleItalic: return @"italic";
        case KxHTMLRenderStyleFontStyleOblique: return @"oblique";
    }
}
 
@implementation KxHTMLRenderStyleValue

+ styleValue: (CGFloat) value unit: (KxHTMLRenderStyleValueUnit) unit
{
    KxHTMLRenderStyleValue *p = [[KxHTMLRenderStyleValue alloc] init];
    if (p) {
        p->_value = value;
        p->_unit = unit;
    }
    return p;
}

+ (id) fromCSSString: (NSString *) css
{
    CGFloat value;
    KxHTMLRenderStyleValueUnit unit;
    
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    css = [css stringByTrimmingCharactersInSet: whitespace];
        
    if ([css hasSuffix:@"px"]) {
            
        value = [[css substringToIndex:css.length - 2] floatValue];
        unit = KxHTMLRenderStyleValueUnitPixel;
        
    } else if ([css hasSuffix:@"em"]) {
        
        value = [[css substringToIndex:css.length - 2] floatValue];
        unit = KxHTMLRenderStyleValueUnitEM;
        
    } else if ([css hasSuffix:@"pt"]) {
        
        value = [[css substringToIndex:css.length - 2] floatValue];
        unit = KxHTMLRenderStyleValueUnitPoint;
        
    // } else if ([css hasSuffix:@"%"]) {
    //
    //    value = [[css substringToIndex:css.length - 1] floatValue];
    //    unit = KxHTMLRenderStyleValueUnitPercentage;
        
    } else {
        
        return nil;
    }
    
    return [self styleValue:value unit:unit];
}

- (CGFloat) sizeWithFont: (UIFont *) font
{
    switch (_unit) {            
        case KxHTMLRenderStyleValueUnitPixel: return _value;
        case KxHTMLRenderStyleValueUnitEM: return _value * font.xHeight;
        case KxHTMLRenderStyleValueUnitPoint: return (font.pointSize / _value) * font.xHeight;
        //case KxHTMLRenderStyleValueUnitPercentage: return (_value * 0.01) * font.xHeight;
    }
}

- (NSString *) asCSSString
{
    switch (_unit) {
            
        case KxHTMLRenderStyleValueUnitPixel:
            return [NSString stringWithFormat:@"%.1fpx", _value];
        case KxHTMLRenderStyleValueUnitEM:
            return [NSString stringWithFormat:@"%.1fem", _value];
        case KxHTMLRenderStyleValueUnitPoint:
            return [NSString stringWithFormat:@"%.1fpt", _value];
    }
}

@end

@implementation KxHTMLRenderStyle {
   
    UIFont *_font;
}

- (UIFont *) mkFont
{    
    static dispatch_once_t onceToken;
    static NSMutableDictionary *fontCache;
    dispatch_once(&onceToken, ^{
        fontCache = [NSMutableDictionary dictionary];
    });
    
    NSString *fontName = _fontFamily ? _fontFamily : DEFAULT_FONT_FAMILY;
    CGFloat fontSize = _fontSize ? _fontSize.floatValue : DEFAULT_FONT_SIZE;
    
    // make array of possible font names (for fallback)
    
    NSMutableArray *fontNames = [NSMutableArray array];
    
    NSString *weight0 = @"", *weight1 = @"", *style0 = @"", *style1 = @"";
    
    if (_fontWeight) {
        
        if (_fontWeight.integerValue == KxHTMLRenderStyleFontWeightBold) {
            
            weight0 = @"Bold";
            weight1 = @"Medium";
        }
    }
    
    if (_fontStyle) {
        
        if (_fontStyle.integerValue == KxHTMLRenderStyleFontStyleItalic) {
            
            style0 = @"Italic";
            style1 = @"Oblique";
            
        } else if (_fontStyle.integerValue == KxHTMLRenderStyleFontStyleOblique) {
            
            style0 = @"Oblique";
            style1 = @"Italic";
        }
    }
    
    if (weight0.length || weight1.length || style0.length || style1.length) {
        
        NSString *n0 = [NSString stringWithFormat:@"%@-%@%@", fontName, weight0, style0];
        NSString *n1 = [NSString stringWithFormat:@"%@-%@%@", fontName, weight0, style1];
        NSString *n2 = [NSString stringWithFormat:@"%@-%@%@", fontName, weight1, style0];
        NSString *n3 = [NSString stringWithFormat:@"%@-%@%@", fontName, weight1, style1];
        
        [fontNames addObject:n0];
        
        if (![fontNames containsObject:n1])
            [fontNames addObject:n1];
        if (![fontNames containsObject:n2])
            [fontNames addObject:n2];
        if (![fontNames containsObject:n3])
            [fontNames addObject:n3];
    }
    
    [fontNames addObject:fontName];
    
    for (NSString *fontName in fontNames) {
    
        NSString *description = [NSString stringWithFormat:@"%@/%f", fontName, fontSize];
        
        UIFont *font = fontCache[description];
        if (font)
            return font;
        
        font = [UIFont fontWithName:fontName size:fontSize];
        if (font) {
            
            fontCache[description] = font;
            return font;
        }
    }

    return [UIFont systemFontOfSize:fontSize];
}

@dynamic font;

- (UIFont *) font
{
    if (!_font)
        _font = [self mkFont];    
    return _font;
}

+ (id) defaultStyle
{
    static KxHTMLRenderStyle *style;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.color = [UIColor darkTextColor];
    });
    
    return style;
}

+ (id) fromCSSString: (NSString *) css
{
    if (!css.length)
        return nil;
    
    css = css.lowercaseString;
    
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *sep = [NSCharacterSet characterSetWithCharactersInString:@";"];
    
    KxHTMLRenderStyle *style = [[KxHTMLRenderStyle alloc] init];
    
    for (NSString *prop in [css componentsSeparatedByCharactersInSet:sep]) {
        
        NSRange r = [prop rangeOfString:@":"];
        if (r.location != NSNotFound) {
            
            NSString *name = [[prop substringToIndex:r.location] stringByTrimmingCharactersInSet: whitespace];
            NSString *value = [[prop substringFromIndex:r.location+1] stringByTrimmingCharactersInSet: whitespace];
            
            if ([name isEqualToString:@"color"])
                style.color = [UIColor colorWithHTMLName:value];
            else if ([name isEqualToString:@"background-color"])
                style.backColor = [UIColor colorWithHTMLName:value];
            else if ([name isEqualToString:@"margin-left"])
                style.marginLeft = [KxHTMLRenderStyleValue fromCSSString:value];
            else if ([name isEqualToString:@"margin-top"])
                style.marginTop = [KxHTMLRenderStyleValue fromCSSString:value];
            else if ([name isEqualToString:@"margin-right"])
                style.marginRight = [KxHTMLRenderStyleValue fromCSSString:value];
            else if ([name isEqualToString:@"margin-bottom"])
                style.marginBottom = [KxHTMLRenderStyleValue fromCSSString:value];
            else if ([name isEqualToString:@"font-family"])
                style.fontFamily = value;
            else if ([name isEqualToString:@"font-size"])
                style.fontSize = @([value floatValue]);
                
            else if ([name isEqualToString:@"font-weight"]) {

                if ([value isEqualToString:@"normal"])
                    style.fontWeight = @(KxHTMLRenderStyleFontWeightNormal);
                else if ([value isEqualToString:@"bold"])
                    style.fontWeight = @(KxHTMLRenderStyleFontWeightBold);
                
            } else if ([name isEqualToString:@"font-style"]) {

                if ([value isEqualToString:@"normal"])
                    style.fontStyle = @(KxHTMLRenderStyleFontStyleNormal);
                else if ([value isEqualToString:@"italic"])
                    style.fontStyle = @(KxHTMLRenderStyleFontStyleItalic);
                else if ([value isEqualToString:@"oblique"])
                    style.fontStyle = @(KxHTMLRenderStyleFontStyleOblique);
                
            } else if ([name isEqualToString:@"margin"]) {
             
                NSArray *values = [value componentsSeparatedByCharactersInSet:whitespace];
                
                if (values.count == 1) {
                    
                    KxHTMLRenderStyleValue *cssVal = [KxHTMLRenderStyleValue fromCSSString:values[0]];
                    style.marginTop = style.marginRight = style.marginBottom = style.marginLeft = cssVal;
                    
                } else {
                    if (values.count > 1)
                        style.marginRight = [KxHTMLRenderStyleValue fromCSSString:values[1]];
                    
                    if (values.count > 2)
                        style.marginBottom = [KxHTMLRenderStyleValue fromCSSString:values[2]];
                    
                    if (values.count > 3)
                        style.marginLeft = [KxHTMLRenderStyleValue fromCSSString:values[3]];
                }
                
            } else if ([name isEqualToString:@"text-decoration"]) {
                
                if ([value isEqualToString:@"none"])
                    style.textDecoration = @(KxHTMLRenderStyleTextDecorationNone);
                else if ([value isEqualToString:@"underline"])
                    style.textDecoration = @(KxHTMLRenderStyleTextDecorationUnderline);
                else if ([value isEqualToString:@"line-through"])
                    style.textDecoration = @(KxHTMLRenderStyleTextDecorationLineThrough);
                
            } else if ([name isEqualToString:@"text-align"]) {
                
                if ([value isEqualToString:@"left"])
                    style.textAlign = @(KxHTMLRenderStyleTextAlignLeft);
                else if ([value isEqualToString:@"center"])
                    style.textAlign = @(KxHTMLRenderStyleTextAlignCenter);
                else if ([value isEqualToString:@"right"])
                    style.textAlign = @(KxHTMLRenderStyleTextAlignRight);
                
            } else {
                
                NSLog(@"unsupported CSS property '%@'", name);
            }
        }
    }
    
    return style;
}

- (id) copyWithZone:(NSZone *)zone
{
    KxHTMLRenderStyle *p = [[self.class allocWithZone:zone] init];
    if (p) {
        p.color         = _color;
        p.backColor     = _backColor;
        p.marginTop     = _marginTop;
        p.marginBottom  = _marginBottom;
        p.marginRight   = _marginRight;
        p.marginLeft    = _marginLeft;
        p.textDecoration= _textDecoration;
        p.textAlign     = _textAlign;
        p.fontFamily    = _fontFamily;
        p.fontSize      = _fontSize;
        p.fontWeight    = _fontWeight;
        p.fontStyle     = _fontStyle;
        p.hyperlink     = _hyperlink;
    }
    return p;
}

- (void) compose: (KxHTMLRenderStyle *) style
{
    if (style.color)
        _color = style.color;
    
    if (style.backColor)
        _backColor = style.backColor;
    
    if (style.marginTop)
        _marginTop = style.marginTop;
    
    if (style.marginBottom)
        _marginBottom = style.marginBottom;
    
    if (style.marginRight)
        _marginRight = style.marginRight;
    
    if (style.marginLeft)
        _marginLeft = style.marginLeft;
    
    if (style.textDecoration)
        _textDecoration = style.textDecoration;
    
    if (style.textAlign)
        _textAlign = style.textAlign;
    
    if (style.fontFamily)
        _fontFamily = style.fontFamily;
    
    if (style.fontSize)
        _fontSize = style.fontSize;
    
    if (style.fontWeight)
        _fontWeight = style.fontWeight;
    
    if (style.fontStyle)
        _fontStyle = style.fontStyle;
    
    if (style.hyperlink)
        _hyperlink = style.hyperlink;
}

- (void) inherit: (KxHTMLRenderStyle *) style
{
    if (!_color)
        _color = style.color;
    
    if (!_fontFamily)
        _fontFamily = style.fontFamily;
    
    if (!_fontSize)
        _fontSize = style.fontSize;
    
    if (!_fontWeight)
        _fontWeight = style.fontWeight;
    
    if (!_fontStyle)
        _fontStyle = style.fontStyle;
    
    if (!_textAlign)
        _textAlign = style.textAlign;
    
    if (!_hyperlink)
        _hyperlink = style.hyperlink;
    
    // only if 'value=inherit'
    //_textDecoration= _textDecoration;
    //_marginTop     = _marginTop;
    //_marginBottom  = _marginBottom;
    //_marginRight   = _marginRight;
    //_marginLeft    = _marginLeft;
}

- (NSString *) asCSSString
{
    NSMutableString *ms = [NSMutableString string];
    [ms appendString:@"{\n"];
    
    if (_color)
        [ms appendFormat:@"color:%@;\n", _color.htmlName];
    if (_backColor)
        [ms appendFormat:@"background-color:%@;\n", _color.htmlName];
    
    if (_marginLeft)
        [ms appendFormat:@"margin-left:%@;\n", _marginLeft];
    if (_marginTop)
        [ms appendFormat:@"margin-top:%@;\n", _marginTop];
    if (_marginRight)
        [ms appendFormat:@"margin-right:%@;\n", _marginRight];
    if (_marginBottom)
        [ms appendFormat:@"margin-bottom:%@;\n", _marginBottom];
    
    if (_fontFamily)
        [ms appendFormat:@"font-family:%@;\n", _fontFamily];
    if (_fontSize)
        [ms appendFormat:@"font-size:%@pt;\n", _fontSize];
    if (_fontWeight)
        [ms appendFormat:@"font-weight:%@;\n", fontWeightAsString(_fontWeight.integerValue)];
    if (_fontStyle)
        [ms appendFormat:@"font-style:%@;\n", fontStyleAsString(_fontStyle.integerValue)];
    
    if (_textDecoration)
        [ms appendFormat:@"text-decoration:%@;\n", textDecorationAsString(_textDecoration.integerValue)];
    if (_textAlign)
        [ms appendFormat:@"text-align:%@;\n", textAlignAsString(_textDecoration.integerValue)];
    
    [ms appendString:@"}\n"];
    return ms;
}

@end

@implementation KxHTMLRenderStyleSheet {
    
    NSMutableDictionary *_styles;
}

+ (id) defaultStyleSheet
{
    static KxHTMLRenderStyleSheet *styleSheet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        styleSheet = [[KxHTMLRenderStyleSheet alloc] init];
        
        KxHTMLRenderStyle *style;
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.color = [UIColor colorWithHTMLName:@"navy"];
        style.hyperlink = @(YES);
        [styleSheet addStyle:style withSelector:@"a"];

        KxHTMLRenderStyleValue *em1_0 = [KxHTMLRenderStyleValue styleValue:1.0 unit:KxHTMLRenderStyleValueUnitEM];
        KxHTMLRenderStyleValue *em0_5 = [KxHTMLRenderStyleValue styleValue:0.5 unit:KxHTMLRenderStyleValueUnitEM];
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.color = [UIColor darkGrayColor];
        style.marginLeft = em1_0;
        style.marginTop = em0_5;
        style.marginBottom = em0_5;
        [styleSheet addStyle:style withSelector:@"blockquote"];
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.marginTop = em1_0;
        style.marginBottom = em1_0;
        [styleSheet addStyle:style withSelector:@"p"];

        style = [[KxHTMLRenderStyle alloc] init];
        style.marginTop = em0_5;
        style.marginBottom = em0_5;
        style.fontWeight = @(KxHTMLRenderStyleFontWeightBold);
        style.fontSize = @(DEFAULT_FONT_SIZE + 12);
        [styleSheet addStyle:style withSelector:@"h1"];
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.marginTop = em0_5;
        style.marginBottom = em0_5;
        style.fontWeight = @(KxHTMLRenderStyleFontWeightBold);
        style.fontSize = @(DEFAULT_FONT_SIZE + 8);
        [styleSheet addStyle:style withSelector:@"h2"];
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.marginTop = em0_5;
        style.marginBottom = em0_5;
        style.fontWeight = @(KxHTMLRenderStyleFontWeightBold);        
        style.fontSize = @(DEFAULT_FONT_SIZE + 4);
        [styleSheet addStyle:style withSelector:@"h3"];
        
        style = [[KxHTMLRenderStyle alloc] init];
        style.marginLeft = em1_0;
        [styleSheet addStyle:style withSelector:@"li"];

    });
    
    return styleSheet;
}

- (id) init
{
    self = [super init];
    if (self) {
        _styles = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) initWithStyles: (NSDictionary *) styles
{
    self = [super init];
    if (self) {
        _styles = [styles mutableCopy];
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return [[self.class allocWithZone:zone] initWithStyles:_styles];
}

- (void) addStyle: (KxHTMLRenderStyle *) style
     withSelector: (NSString *) selector
{
    KxHTMLRenderStyle *p = _styles[selector];
    if (p)
        [p compose:style];
    else
        _styles[selector] = style;
}

- (void) addStyles: (NSString *) css
{
    if (!css.length)
        return;
    
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSCharacterSet *sep = [NSCharacterSet characterSetWithCharactersInString:@","];
        
    NSScanner *scanner = [NSScanner scannerWithString:css.lowercaseString];
    
    while (!scanner.isAtEnd) {
        
        NSString *selectors, *declarations;
        if ([scanner scanUpToString:@"{" intoString:&selectors] &&
            [scanner scanString:@"{" intoString:nil] &&
            [scanner scanUpToString:@"}" intoString:&declarations] &&
            [scanner scanString:@"}" intoString:nil]) {
            
            KxHTMLRenderStyle *style = [KxHTMLRenderStyle fromCSSString: declarations];
            if (style) {
                
                for (NSString *s in [selectors componentsSeparatedByCharactersInSet:sep]) {
                    
                    NSString *selector = [s stringByTrimmingCharactersInSet: whitespace];
                    if (selector.length)
                        [self addStyle:style withSelector:selector];
                }
            }
            
        } else {
            
            break;
        }
    }
}

- (KxHTMLRenderStyleSheet *) compose: (KxHTMLRenderStyleSheet *) styleSheet
{
    KxHTMLRenderStyleSheet *newstyleSheet = [self copy];
    
    [styleSheet->_styles enumerateKeysAndObjectsUsingBlock:^(id selector, id style, BOOL *stop) {
        
        [newstyleSheet addStyle:style withSelector:selector];
    }];
    
    return newstyleSheet;
}

- (KxHTMLRenderStyle *) lookupStyle: (NSString *) selector
{
    return _styles[selector];
}

- (NSString *) asCSSString
{
    NSMutableString *ms = [NSMutableString string];
    [_styles enumerateKeysAndObjectsUsingBlock:^(id selector, id style, BOOL *stop) {
        
        [ms appendFormat:@"%@ %@", selector, [(KxHTMLRenderStyle *)style asCSSString]];
    }];
    return ms;
}

@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#pragma mark - render

@implementation KxHTMLRender {
    
    KxHTMLElement       *_root;
    NSArray             *_links;
    NSArray             *_images;
}

+ (id) renderFromHTML:(NSData *) html
             encoding:(NSStringEncoding) encoding
             delegate: (id<KxHTMLRenderDelegate>) delegate
{    
    KxHTMLReader *reader = [[KxHTMLReader alloc] init];
    DTHTMLParser *parser = [[DTHTMLParser alloc] initWithData:html encoding:encoding];
    parser.delegate = reader;
    
    if (![parser parse] || !reader.body)
        return nil;
    
    //NSLog(@"%@", [reader.body asHTMLString]);
    //NSLog(@"%@", [reader.styleSheet asCSSString]);
        
    return [[KxHTMLRender alloc] initWithRoot:reader.body
                                   styleSheet:reader.styleSheet
                                     delegate:delegate];
}

- (id) initWithRoot: (KxHTMLElement *) root
         styleSheet: (KxHTMLRenderStyleSheet *)styleSheet
           delegate: (id<KxHTMLRenderDelegate>) delegate
{
    self = [super init];
    if (self) {
        
        _root = root;
        
        KxHTMLRenderStyleSheet *defaultCSS = [KxHTMLRenderStyleSheet defaultStyleSheet];
        _styleSheet = styleSheet ? [defaultCSS compose:styleSheet] : [defaultCSS copy];
        
        _baseStyle = [[KxHTMLRenderStyle defaultStyle] copy];
            
        _links = [_root collectNodes:[KxHTMLHyperlinkElement class]];
        
        if (delegate)
            [self loadImages:delegate];
    }
    
    return self;
}

- (CGFloat) layoutWithWidth: (CGFloat) width
{
    KxAnchor anchor = {0};
    anchor = [_root layout:width anchor:anchor style:_baseStyle styleSheet:_styleSheet];    
    return anchor.line;
}

- (CGFloat) drawInRect: (CGRect) rect
               context: (CGContextRef) context
{
    KxAnchor anchor = {rect.origin, rect.origin.y};
    anchor = [_root render:rect anchor:anchor style:_baseStyle styleSheet:_styleSheet context:context];
    return anchor.line - rect.origin.y;
}

- (BOOL) isUserInteractive
{
    return _links.count > 0;
}

- (NSURL *) hitTest:(CGPoint)loc
{
    for (KxHTMLHyperlinkElement *p in _links)
        if ([p hitTest:loc])
            return p.url;
    return nil;
}

- (void) loadImages: (id<KxHTMLRenderDelegate>) delegate
{
    _images = [_root collectNodes:[KxHTMLImageNode class]];
    
    NSMutableArray *ma = [NSMutableArray array];
    for (KxHTMLImageNode *node in _images)
        if (node.src.length && ![ma containsObject:node.src])
            [ma addObject:node.src];
    
    if (ma.count) {
        
        __weak id w = self;
        [delegate loadImages:ma
                   completed:^(UIImage *image, NSString *source)
         {
             __strong id p = w;
             if (p)
                 [p didLoadImage:image withSource:source];
         }];
    }
}

- (void) didLoadImage: (UIImage *) image
           withSource: (NSString *) src
{
    for (KxHTMLImageNode *node in _images)
        if ([src isEqualToString:node.src])
            [node didLoadImage: image];
}

@end

///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

#pragma mark - view

#define VIEW_X_MARGIN 2

@implementation KxHTMLView {
    CGFloat _contentHeight;
}

/*
@dynamic contentHeight;
- (CGFloat) contentHeight
{
    if (_contentHeight < 0) {
        CGRect rc = CGRectInset(self.bounds, VIEW_X_MARGIN, 0);
        _contentHeight = [_htmlRender layoutWithWidth:rc.size.width - VIEW_X_MARGIN * 2];
    }
    return _contentHeight;
}
*/

- (void) loadHtmlString: (NSString *) htmlString
{ 
    _htmlRender = [KxHTMLRender renderFromHTML:[htmlString dataUsingEncoding:NSUTF8StringEncoding]
                                      encoding:NSUTF8StringEncoding
                                      delegate:self];
    
    _contentHeight = -1;    
    self.userInteractionEnabled = _htmlRender.isUserInteractive;
    [self setNeedsDisplay];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    _contentHeight = -1;
}

- (CGSize)sizeThatFits:(CGSize)size
{
    size.width = self.superview.bounds.size.width;    
    if (!size.width)
        size.width = [[UIScreen mainScreen] applicationFrame].size.width;
    
    size.height = [_htmlRender layoutWithWidth:size.width - VIEW_X_MARGIN * 2];
    return size;
}

- (void) drawRect:(CGRect)r
{   
	CGContextRef context = UIGraphicsGetCurrentContext();
    
	[[UIColor whiteColor] set];
	CGContextFillRect(context, r);
    
    CGRect rc = CGRectInset(self.bounds, VIEW_X_MARGIN, 0);    
    if (_contentHeight < 0)
        _contentHeight = [_htmlRender layoutWithWidth:rc.size.width - VIEW_X_MARGIN * 2];
    [_htmlRender drawInRect:rc context:context];
    
#if 0
    [[UIColor redColor] set];
    CGContextMoveToPoint(context, rc.origin.x, rc.origin.y + _contentHeight - 1);
    CGContextAddLineToPoint(context, rc.origin.x + rc.size.width, rc.origin.y + _contentHeight - 1);
    CGContextStrokePath(context);
#endif
    
}

- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event
{
    UITouch *t = [touches anyObject];
    if ([t tapCount] > 1)
        return; // double tap
    
    CGPoint loc = [t locationInView:self];
    if (CGRectContainsPoint([self bounds], loc)) {
        
        NSURL *url = [_htmlRender hitTest:loc];
        if (url) {
            
            UIApplication *app = [UIApplication sharedApplication];
            if ([app.delegate respondsToSelector:@selector(application:handleOpenURL:)]) {
                
                if ([app.delegate application:app handleOpenURL: url])
                    return;
            }
            
            if ([app canOpenURL:url])
                [app openURL:url];
        }
    }
}

- (void) loadImages: (NSArray *) sources
          completed: (void(^)(UIImage *image, NSString *source)) completed
{
    __weak id w = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        for (NSString *source in sources) {
            
            NSURL *url = [NSURL URLWithString:source];
            if (url) {
                
                UIImage *image;
                NSData *data = [NSData dataWithContentsOfURL: url];
                if (data)
                    image = [UIImage imageWithData:data];
                
                __strong id p = w;
                if (p) {
                    
                    completed(image, source);
                    [p performSelectorOnMainThread:@selector(setNeedsDisplay)
                                        withObject:nil
                                     waitUntilDone:NO];
                    
                } else {
                    
                    break;
                }
            }
        }
    });    
}

@end