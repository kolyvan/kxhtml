//
//  ViewController.m
//  KxHtmlExample
//
//  Created by Kolyvan on 20.12.12.
//  Copyright (c) 2012 Konstantin Bukreev. All rights reserved.
//

#import "ViewController.h"
#import "KxHTML.h"

@interface ViewController ()

@end

@implementation ViewController {
    
    KxHTMLView *_htmlView;
}

- (void) loadView
{    
    UIScrollView *sv = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    sv.clipsToBounds = YES;
    sv.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    sv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    //sv.autoresizesSubviews = NO;
    self.view = sv;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *s =
    @"<div class='main'>"
    @"<style>"
    @" .main { background-color:#ddfcdd; }"
    @" p { color:green; }"
    @" .bggreen { background-color:green; }"
    @" .bgyellow { background-color: yellow; }"
    @" .fgred { color: red; }"
    @"</style>"
    @"<h3>Spans and styles</h3>"
    @"<div><span class='bggreen'>A span with green background.</span><span>Then the span without style.</span><span class='bgyellow'> And span with yellow background.</span></div>"
    @"<h3>Inline style with margin and text align</h3>"
    @"<div style='margin:10px; background-color:#22AF89; text-align:center; font-size:12pt;'> &lt;div style='margin:10px; text-align:center;'&gt;"
    @"</div>"
    @"<h3>Hyperlinks</h3>"
    @"<div>"
    @"The link to <a href='http://google.com/'>google site</a>"
    @" and another link to <a href='https://github.com/kolyvan/'>https://github.com/kolyvan/</a>"
    @"</div>"
    @"<h3>Images</h3>"
    @"<div>"
    @"<img src='https://github.com/fluidicon.png' alt='github icon' width='64'>"
    @"<img src='https://github.com/fluidicon.png' alt='github icon' width='64'>"
    @"</div>"
    @"<h3>Text decorations and font attributes</h3>"
    @"<div>"
    @"<li>Via tags: <b>bold</b> <i>italic</i> <s>strikeout</s> <u>underline</u> <font color=#ff0000>colored</font>"
    @"<li>Via styles: <span style='font-weight:bold'>bold</span> <span style='font-style:italic'>italic</span> <span style='text-decoration:line-through'>strikeout</span> <span style='text-decoration:underline'>underline</span> <span class='fgred'>colored</span>"
    @"</div>"
    @"<h3>Block elements (blockquote, p, pre)</h3>"
    @"<blockquote>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</blockquote>"
    @"<p>Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>"
    @"<pre>"
    @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. "
    @"</pre>"
    @"</div>";

    
    _htmlView = [[KxHTMLView alloc] initWithFrame:CGRectZero];
    [_htmlView loadHtmlString:s];
        
    _htmlView.contentMode = UIViewContentModeRedraw;
    _htmlView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    //KxHTMLRenderStyle *style = [[KxHTMLRenderStyle alloc] init];
    //style.backColor = [UIColor yellowColor];
    //[v.htmlRender.styleSheet addStyle:style withSelector:@"p.yellow"];
        
    UIScrollView *sv = (UIScrollView *)self.view;
    [sv addSubview:_htmlView];
    
    [_htmlView sizeToFit];
    sv.contentSize = _htmlView.bounds.size;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
                                         duration:(NSTimeInterval)duration
{    
    UIScrollView *sv = (UIScrollView *)self.view;
    [_htmlView sizeToFit];
    sv.contentSize = _htmlView.bounds.size;
}

@end
