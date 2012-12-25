KxHTML - simple and lightweight HTML renderer for iOS
=====================================================

KxHTML supports limited sets of HTML elements and CSS styles.

### Features

* HTML elements: div,span,style,p,blockquote,pre,li,a,img,b,u,i,s,font,br,h1,h2,h3
* HTML attributes: class, style
* CSS: declared in style element and inline
* CSS styles: color, background-color, margin, font-family, font-size, font-weight, font-style, text-decoration, text-align 

Syllabification via Hyphenation algorithm 'П.Хpистова в модификации Дымченко и Ваpсанофьева'.

### Usage

	KxHTMLView *v = [[KxHTMLView alloc] initWithFrame:CGRectZero];
    [v loadHtmlString:@"<div>Hello <span style='text-decoration:underline'>world</span></div>"];

* Add KxHTML.xcodeproj as a child project
* Add KxHTML as a project dependency
* Link with libKxHTML.a and libxml2.dylib
* Add -ObjC to Other linker flag

Also look at HTMLRenderExample as DEMO project

### Requirements

at least iOS 5.1

### Screenshot:

![htmlview](https://raw.github.com/kolyvan/kxhtml/master/screenshot.png "HTML View")

### Feedback

Tweet me — [@kolyvan_ru](http://twitter.com/kolyvan_ru).

### Some code and ideas was taken from following projects, thank you.

- [DTHTMLParser](https://github.com/Cocoanetics) by Oliver Drobnik

### License

KxHtml is released under an Simplified BSD License.