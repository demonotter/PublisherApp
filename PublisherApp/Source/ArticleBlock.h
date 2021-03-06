//
//  ArticleBlock.h
//  Pods
//
//  Created by Dmitry Zheshinsky on 5/16/17.
//
//

#import <Foundation/Foundation.h>
#import "ReaderSettings.h"

static NSString* kTextBlock = @"text";
static NSString* kImageBlock = @"image";
static NSString* kHeaderBlock = @"title";
static NSString* kListBlock = @"list";
static NSString* kYoutubeBlock = @"youtube";
static NSString* kCodeBlock = @"code";
static NSString* kQuoteBlock = @"quote";
static NSString* kTwitterBlock = @"twitter";
static NSString* kVimeoBlock = @"vimeo";
static NSString* kHtmlBlock = @"html";

@protocol ArticleBlockExtensions <NSObject>
@optional
@property (nonatomic, readonly) NSAttributedString* prerenderedText;
- (CGFloat) blockHeight; //Used for images
- (BOOL) canDisplayLink;
- (BOOL) displaysWebContent;
- (void) prerenderText;
- (NSString*) image;
- (NSString*) youtubeID;
@end


@interface ArticleBlock : NSObject<ArticleBlockExtensions>

@property (nonatomic) FontSize appliedFontSize;

@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSDictionary* properties;
@property (nonatomic, strong) NSString* content;

@end
