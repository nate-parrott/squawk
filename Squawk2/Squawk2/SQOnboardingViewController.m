//
//  SQOnboardingViewController.m
//  Squawk2
//
//  Created by Nate Parrott on 4/30/14.
//  Copyright (c) 2014 Nate Parrott. All rights reserved.
//

#import "SQOnboardingViewController.h"
#import "SQOnboardingPage.h"

@interface SQOnboardingViewController ()

@property(strong)NSString* currentPageIdentifier;

@end

@implementation SQOnboardingViewController

#pragma mark Paging
-(NSArray*)pageIdentifiers {
    // storyboard identifiers for each page:
    return @[@"Phone", @"Contacts", @"Microphone", @"Push"];
}
-(void)nextPage {
    int currentIndex = -1;
    if (self.currentPageIdentifier) {
        currentIndex = [[self pageIdentifiers] indexOfObject:self.currentPageIdentifier];
    }
    int newIndex = currentIndex+1;
    if (newIndex < [self pageIdentifiers].count) {
        SQOnboardingPage* oldPage = self.currentPage;
        self.currentPageIdentifier = [self pageIdentifiers][newIndex];
        self.currentPage = [self.storyboard instantiateViewControllerWithIdentifier:self.currentPageIdentifier];
        self.currentPage.owner = self;
        [self addChildViewController:self.currentPage];
        [self.currentPage viewWillAppear:YES];
        [self.view addSubview:self.currentPage.view];
        
        if (oldPage) {
            [oldPage viewWillDisappear:YES];
            NSTimeInterval duration = 0.5;
            
            [self transitionFromBottomButton:oldPage.nextButton toButton:self.currentPage.nextButton duration:duration];
            [oldPage animateOutWithDuration:duration];
            [self.currentPage animateInWithDuration:duration];
            
            self.currentPage.view.transform = CGAffineTransformMakeTranslation(self.currentPage.view.frame.size.width, 0);
            [UIView animateWithDuration:duration delay:0 options:0 animations:^{
                oldPage.view.transform = CGAffineTransformMakeTranslation(-oldPage.view.frame.size.width, 0);
                self.currentPage.view.transform = CGAffineTransformIdentity;
                self.view.backgroundColor = self.currentPage.backgroundColor;
            } completion:^(BOOL finished) {
                [oldPage.view removeFromSuperview];
                [oldPage viewDidDisappear:YES];
                [oldPage removeFromParentViewController];
                [self.currentPage viewDidAppear:YES];
            }];
        } else {
            [self.currentPage viewDidAppear:YES];
        }
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}
#pragma mark Views
-(void)viewDidLoad {
    [super viewDidLoad];
    [self nextPage];
}
-(void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.currentPage.view.frame = self.view.bounds;
}
#pragma mark Transitioning
-(NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    if ([[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey] isEqual:self]) {
        return 2.0;
    } else {
        return 1.0;
    }
}
-(void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController* toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView* root = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    if ([toVC isEqual:self]) {
        // presenting:
        [root addSubview:self.view];
        self.view.frame = [transitionContext finalFrameForViewController:self];
        self.view.backgroundColor = [UIColor clearColor];
        
        self.currentPage.nextButton.transform = CGAffineTransformMakeTranslation(0, self.currentPage.nextButton.frame.size.height);
        [UIView animateWithDuration:duration animations:^{
            self.currentPage.nextButton.transform = CGAffineTransformIdentity;
        }];
        [self.currentPage animateInWithDuration:duration];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.view.backgroundColor = self.currentPage.backgroundColor;
            
            [transitionContext completeTransition:YES];
        });
    } else if ([fromVC isEqual:self]) {
        // dismissing:
        [root insertSubview:toVC.view atIndex:0];
        toVC.view.frame = [transitionContext finalFrameForViewController:toVC];
        [self.currentPage animateOutWithDuration:duration];
        [UIView animateWithDuration:duration animations:^{
            self.view.backgroundColor = [UIColor clearColor];
            self.currentPage.nextButton.transform = CGAffineTransformMakeTranslation(0, self.currentPage.nextButton.frame.size.height);
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:YES];
        }];
    }
}
//                 [self transitionFromBottomButton:oldPage.nextButton toButton:self.currentPage.nextButton];
-(void)transitionFromBottomButton:(UIButton*)from toButton:(UIButton*)to duration:(NSTimeInterval)duration {
    UIView* fakeBar = [UIView new];
    [self.view addSubview:fakeBar];
    fakeBar.frame = [self.view convertRect:from.bounds fromView:from];
    fakeBar.backgroundColor = from.backgroundColor;
    UIView* fromTitle = [from.titleLabel snapshotViewAfterScreenUpdates:YES];
    [fakeBar addSubview:fromTitle];
    fromTitle.center = CGPointMake(fakeBar.bounds.size.width/2, fakeBar.bounds.size.height/2);
    UIView* toTitle = [to.titleLabel snapshotViewAfterScreenUpdates:YES];
    [fakeBar addSubview:toTitle];
    toTitle.center = fromTitle.center;
    toTitle.alpha = 0;
    toTitle.transform = CGAffineTransformMakeTranslation(100, 0);
    [UIView animateWithDuration:duration animations:^{
        toTitle.transform = CGAffineTransformIdentity;
        fromTitle.transform = CGAffineTransformMakeTranslation(-100, 0);
        fromTitle.alpha = 0;
        toTitle.alpha = 1;
        fakeBar.backgroundColor = to.backgroundColor;
    } completion:^(BOOL finished) {
        [fakeBar removeFromSuperview];
    }];
}

@end
