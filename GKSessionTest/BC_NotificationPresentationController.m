//
//  BC_NotificationPresentationController.m
//  customPresentationController
//
//  Created by Bill A on 9/25/15.
//  Copyright © 2015 beaconcrawl.com. All rights reserved.
//

#import "BC_NotificationPresentationController.h"

@interface BC_NotificationPresentationController ()

@property (nonatomic) UIView *dimmingView;

@end

@implementation BC_NotificationPresentationController

- (instancetype)initWithPresentedViewController:(UIViewController *)presentedViewController presentingViewController:(UIViewController *)presentingViewController
{
    self = [super initWithPresentedViewController:presentedViewController presentingViewController:presentingViewController];
    if (self)
    {
         _dimmingView = [[UIView alloc] init];
    }
    return self;
}

- (void) setIsDimmed:(BOOL)isDimmed
{
    _isDimmed = isDimmed;
    if (!isDimmed)
    {
        [[self dimmingView] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.0]];
    }
    else
    {
        [[self dimmingView] setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.6]];
    }
}

- (CGRect)frameOfPresentedViewInContainerView
{
    if (_isFullScreen)
    {
        return [[self containerView] bounds];
    }
    else
    {
        CGRect containerBounds = [[self containerView] bounds];
        CGRect presentedViewFrame = CGRectZero;
        CGFloat width = containerBounds.size.width - 16;
        CGFloat height = ([[self traitCollection] verticalSizeClass] == UIUserInterfaceSizeClassCompact) ? 300 : containerBounds.size.height - 16;
        
        presentedViewFrame.size = CGSizeMake(width, height);
        presentedViewFrame.origin = CGPointMake(containerBounds.size.width / 2.0, containerBounds.size.height / 2.0);
        presentedViewFrame.origin.x -= presentedViewFrame.size.width / 2.0;
        presentedViewFrame.origin.y -= presentedViewFrame.size.height / 2.0;
        return presentedViewFrame;
    }
    
    
}

- (void)presentationTransitionWillBegin
{
    [super presentationTransitionWillBegin];
    [[self containerView] addSubview:[self dimmingView]];
    [[self dimmingView] setAlpha:0.0];
    [[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
    {
        [[self dimmingView] setAlpha:1.0];
        
    } completion:nil];

}

- (void)containerViewWillLayoutSubviews
{
    [[self dimmingView] setFrame:[[self containerView] bounds]];
    [[self presentedView] setFrame:[self frameOfPresentedViewInContainerView]];
}

- (void)dismissalTransitionWillBegin
{
    [super dismissalTransitionWillBegin];
    [[[self presentedViewController] transitionCoordinator] animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
        [[self dimmingView] setAlpha:0.0];
         
     } completion:nil];
}


@end
