//
//  SPLMPostContentViewModel.m
//  MakeUseOf
//
//  Created by Dmitry Zheshinsky on 4/22/15.
//  Copyright (c) 2015 Dmitry Zheshinsky. All rights reserved.
//

#import "MUOPostContentViewModel.h"
#import "MUOPostsRequestManager.h"
#import "Post.h"
#import "MUOHtmlEditor.h"
#import "CoreContext.h"
@import ReactiveCocoa;

@interface MUOPostContentViewModel ()

@property (nonatomic, strong) MUOPostsRequestManager* postsManager;


@end

@implementation MUOPostContentViewModel

- (instancetype)init{
    self = [super init];
    if(self)
    {
        self.postsManager = [MUOPostsRequestManager new];
    }
    return self;
}

- (RACSignal *)loadPost {
    /*@weakify(self);
    NSString* fetchIdentifier = _postId ? [_postId stringValue] : _postSlug;
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @strongify(self);
       [[self.postsManager fetchPostByID:fetchIdentifier] subscribeNext:^(Post *post) {
            
            @strongify(self);
            self.post = post;
            self.title = post.postTitle;
            [subscriber sendCompleted];
        } error:^(NSError *error) {
            [subscriber sendError:error];
        }];
        return nil;
    }];*/
   return nil;
}

- (void)loadSavedPost {
    MUOSavedPost* savedPost = [[CoreContext sharedContext].savesManager savedPostWithID:[_postId integerValue]];
    if (savedPost != nil) {
        Post* postToDisplay = [Post new];
        [postToDisplay fillWithSavedPost:savedPost];
       
        self.post = postToDisplay;
    }
}

@end