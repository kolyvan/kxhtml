//
//  UIColor+HTML.h
//  kxhtmlrender
//

#import <UIKit/UIKit.h>

@interface UIColor (HTML)

+ (UIColor *)colorWithHexString:(NSString *)hex;
+ (UIColor *)colorWithHTMLName:(NSString *)name;

- (NSString *)htmlName;

@end
