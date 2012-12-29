//
//  KxHTML.h
//  KxHTML
//
//  Created by Kolyvan on 20.12.12.
//  Copyright (c) 2012 Konstantin Bukreev. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    
    KxHTMLRenderStyleTextDecorationNone,
    KxHTMLRenderStyleTextDecorationLineThrough,    
    KxHTMLRenderStyleTextDecorationUnderline,
    
} KxHTMLRenderStyleTextDecoration;

typedef enum {
    
    KxHTMLRenderStyleTextAlignLeft,
    KxHTMLRenderStyleTextAlignCenter,
    KxHTMLRenderStyleTextAlignRight,
    
} KxHTMLRenderStyleTextAlign;

typedef enum {
    
    KxHTMLRenderStyleFontWeightNormal,
    KxHTMLRenderStyleFontWeightBold,
    
} KxHTMLRenderStyleFontWeight;

typedef enum {
    
    KxHTMLRenderStyleFontStyleNormal,
    KxHTMLRenderStyleFontStyleItalic,
    KxHTMLRenderStyleFontStyleOblique,
    
} KxHTMLRenderStyleFontStyle;

typedef enum {

    KxHTMLRenderStyleValueUnitPixel,    
    KxHTMLRenderStyleValueUnitEM,
    KxHTMLRenderStyleValueUnitPoint,
    //KxHTMLRenderStyleValueUnitPercentage,
    
} KxHTMLRenderStyleValueUnit;

@interface KxHTMLRenderStyleValue : NSObject

@property (readonly, nonatomic) CGFloat value;
@property (readonly, nonatomic) KxHTMLRenderStyleValueUnit unit;

+ styleValue: (CGFloat) value unit: (KxHTMLRenderStyleValueUnit) unit;
+ (id) fromCSSString: (NSString *) css;
- (CGFloat) sizeWithFont: (UIFont *) font;

@end


@interface KxHTMLRenderStyle : NSObject<NSCopying>

@property (readwrite, nonatomic, strong) UIColor *color;
@property (readwrite, nonatomic, strong) UIColor *backColor;
@property (readwrite, nonatomic, strong) KxHTMLRenderStyleValue *marginTop;
@property (readwrite, nonatomic, strong) KxHTMLRenderStyleValue *marginBottom;
@property (readwrite, nonatomic, strong) KxHTMLRenderStyleValue *marginRight;
@property (readwrite, nonatomic, strong) KxHTMLRenderStyleValue *marginLeft;
@property (readwrite, nonatomic, strong) NSNumber *textDecoration;
@property (readwrite, nonatomic, strong) NSNumber *textAlign;
@property (readwrite, nonatomic, strong) NSString *fontFamily;
@property (readwrite, nonatomic, strong) NSNumber *fontSize;
@property (readwrite, nonatomic, strong) NSNumber *fontWeight;
@property (readwrite, nonatomic, strong) NSNumber *fontStyle;
@property (readwrite, nonatomic, strong) NSNumber *hyperlink;
@property (readonly, nonatomic, strong) UIFont *font;

+ (id) defaultStyle;
+ (id) fromCSSString: (NSString *) css;
- (void) compose: (KxHTMLRenderStyle *) style;
- (void) inherit: (KxHTMLRenderStyle *) style;

@end


@interface KxHTMLRenderStyleSheet : NSObject<NSCopying>

+ (id) defaultStyleSheet;
- (void) addStyle: (KxHTMLRenderStyle *) style withSelector: (NSString *) selector;
- (void) addStyles: (NSString *) css;
- (KxHTMLRenderStyle *) lookupStyle: (NSString *) selector;

@end


@protocol KxHTMLRenderDelegate <NSObject>

- (void) loadImages: (NSArray *) sources
          completed: (void(^)(UIImage *image, NSString *source)) completed;

@end


@interface KxHTMLRender : NSObject

@property (readonly, nonatomic, strong) KxHTMLRenderStyleSheet *styleSheet;

+ (id) renderFromHTML:(NSData *) html
             encoding:(NSStringEncoding) encoding
             delegate: (id<KxHTMLRenderDelegate>) delegate;

- (CGFloat) layoutWithWidth: (CGFloat) width;

- (CGFloat) drawInRect: (CGRect) rect
               context: (CGContextRef) context;

- (BOOL) isUserInteractive;
- (NSURL *) hitTest:(CGPoint)loc;

@end


@interface KxHTMLView : UIView<KxHTMLRenderDelegate>
@property (readonly, nonatomic, strong) KxHTMLRender *htmlRender;
//@property (readonly, nonatomic) CGFloat contentHeight;
- (void) loadHtmlString: (NSString *) html;
@end