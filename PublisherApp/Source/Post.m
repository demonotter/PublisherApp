//
//  Post.m
//  MakeUseOf
//
//  Created by Dmitry Zheshinsky on 1/12/17.
//  Copyright © 2017 MakeUseOf. All rights reserved.
//

#import "Post.h"
@import DateTools;
@import DCKeyValueObjectMapping;
@import SDWebImage;
#import "MUOSavedPost.h"
#import "ArticleBlock.h"
#import "ReaderSettings.h"
#import "NSString+MUO.h"

@implementation FeaturedImage
@end


@implementation PostCategory
@end

@interface Post()
@property (nonatomic, strong) NSMutableDictionary* localURLs;
@property (nonatomic) NSOperationQueue* renderQueue;
@end

@implementation Post
-(instancetype)init {
   self = [super init];
   if (self) {
      self.localURLs = [NSMutableDictionary new];
   }
   return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
   [super setValue:value forKey:key];
   if ([key isEqualToString:@"_postDate"]) {
      self.relativeDateString = [[self.postDate shortTimeAgoSinceNow] localizedShortDate];
   }
   if ([key isEqualToString:@"_likesCount"]) {
      self.likesString = [NSString stringWithFormat:@"%ld", (long)self.likesCount.integerValue];
   }
}


#pragma mark - Date
-(void)setPostDate:(NSDate *)postDate {
   _postDate = postDate;
   _relativeDateString = [[_postDate shortTimeAgoSinceNow] localizedShortDate];
}


#pragma mark - Likes
- (void)setLikesCount:(NSNumber *)likesCount {
   _likesCount = likesCount;
   if (_likesCount == 0) {
      _likesString = @"";
   } else {
      _likesString = [NSString stringWithFormat:@"%ld", (long)self.likesCount.integerValue];
   }
}

#pragma mark - Configuration
+(DCParserConfiguration *)parserConfiguration {
   DCParserConfiguration *config = [DCParserConfiguration configuration];
   DCArrayMapping* blocksMapper = [DCArrayMapping mapperForClassElements:[ArticleBlock class] forAttribute:@"blocks" onClass:[Post class]];
   DCArrayMapping *mapper = [DCArrayMapping mapperForClassElements:[PostCategory class] forAttribute:@"categories" onClass:[Post class]];
   config.datePattern = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
   [config addArrayMapper:blocksMapper];
   [config addArrayMapper:mapper];
   return config;
}

- (NSURL *)imageUrl {
   return self.featuredImage.featured;
}

- (NSString*) longDate {
   return [self.postDate formattedDateWithFormat:@"MMMM dd, YYYY"];
}

#pragma mark - Saved post
-(MUOSavedPost *)postToSave:(BOOL)isBookmarked {
   MUOSavedPost* post = [MUOSavedPost new];
   
   post.ID = [self.ID integerValue];
   post.title = self.postTitle;
   post.imageUrl = [self.featuredImage.middle absoluteString];
   post.primaryCategory = [[self.categories firstObject] title];
   post.postURL = self.url;
   post.content = self.html;
   post.date = self.postDate;
   post.likesCount = [self.likesCount integerValue];
   return post;
}

+ (instancetype)postWithSavedPost:(MUOSavedPost *)savedPost {
   Post* post = [Post new];
   [post fillWithSavedPost:savedPost];
   return post;
}

-(void)fillWithSavedPost:(MUOSavedPost *)post{
   self.ID = [NSNumber numberWithInteger:post.ID];
   self.likesCount = [NSNumber numberWithInteger:post.likesCount];
   self.postTitle = post.title;
   self.featuredImage = [FeaturedImage new];
   self.featuredImage.middle = [NSURL URLWithString:post.imageUrl];
   self.html = post.content;
   self.postDate = post.date;
   self.url = post.postURL;
}

-(void)addLocalURL:(NSString *)localUrl forRemoteImage:(NSString *)imageUrl {
   [self.localURLs setObject:localUrl forKey:imageUrl];
}


-(void)replaceRemoteUrlsWithLocal {
   [self.localURLs enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* obj, BOOL *stop) {
      self.html = [self.html stringByReplacingOccurrencesOfString:key withString:obj];
   }];
}

-(void)clearLocalURLs {
   [self.localURLs removeAllObjects];
}


#pragma mark - Blocks
- (NSArray *)imagesFromBlocks {
   NSMutableArray* images = [NSMutableArray new];
   [images addObject:[self.featuredImage.featured absoluteString]];
   for (ArticleBlock* block in self.blocks) {
      if ([block.type isEqualToString:kImageBlock]) {
         [images addObject:block.properties[@"url"]];
      }
   }
   return images;
}

- (NSArray *)youtubeBlocksIDs {
   NSMutableArray* ids = [NSMutableArray new];
   for (ArticleBlock* block in self.blocks) {
      if ([block.type isEqualToString:kYoutubeBlock]) {
         [ids addObject:[block youtubeID]];
      }
   }
   return ids;
}

- (NSOperationQueue *)renderQueue {
   if (!_renderQueue) {
      _renderQueue = [NSOperationQueue new];
      _renderQueue.maxConcurrentOperationCount = 1;
   }
   return _renderQueue;
}

- (void)prerenderBlocksWithIndexes:(NSArray *)visibleIndexes updateBlock:(void (^)())updateBlock {
   if (self.renderQueue) {
      [self.renderQueue cancelAllOperations];
   }
   //High priority blocks
   NSMutableArray* renderedIndexes = [NSMutableArray new];
   if (visibleIndexes) {
      renderedIndexes = [NSMutableArray arrayWithArray:visibleIndexes];
      int indexesToAppend = 2;
      for (int i = 0; i < indexesToAppend; i++) {
         if ([renderedIndexes.firstObject integerValue] != 0) {
            [renderedIndexes insertObject:@([renderedIndexes.firstObject integerValue] - 1) atIndex:0];
         }
         if ([renderedIndexes.lastObject integerValue] != self.blocks.count - 1) {
            [renderedIndexes addObject:@([renderedIndexes.lastObject integerValue] + 1)];
         }
      }
   } else {
      for (int i = 0; i < self.blocks.count - 1; i++) {
         [renderedIndexes addObject:@(i)];
      }
   }
   
   for (NSNumber* index in renderedIndexes) {
      ArticleBlock* block = self.blocks[index.integerValue];
      NSOperation* renderOperation = [self renderOperationForBlock:block];
      if (index == [renderedIndexes lastObject] && updateBlock) {
         renderOperation.completionBlock = ^{
            updateBlock();
         };
      }
      renderOperation.queuePriority = NSOperationQueuePriorityHigh;
      [self.renderQueue addOperation:renderOperation];
   }
   
   //Low priority blocks
   for (ArticleBlock* block in self.blocks) {
      NSInteger blockIndex = [self.blocks indexOfObject:block];
      if ([renderedIndexes containsObject:[NSNumber numberWithInt:blockIndex]]) continue;
      if (visibleIndexes != nil) {
         [self.renderQueue addOperation:[self renderOperationForBlock:block]];
      }
   }
}

- (NSOperation *) renderOperationForBlock:(ArticleBlock*) block {
   NSBlockOperation* renderOperation = [NSBlockOperation blockOperationWithBlock:^{
      [block prerenderText];
   }];
   return renderOperation;
}

@end
