//
//  BC_AnimationController.m
//  customPresentationController
//
//  Created by Bill A on 9/25/15.
//  Copyright © 2015 beaconcrawl.com. All rights reserved.
//

#import "BC_AnimationController.h"

@implementation BC_AnimationController

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = [fromViewController view];
    UIViewController *toViewController   = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *toView = [toViewController view];
    
    if (_isFlipAnimation)
    {
        UIView *containerView = [transitionContext containerView];
        BOOL isPresentation = [self isPresentation];
        if (isPresentation)
        {
            [containerView addSubview:toView];
        }
        UIViewController *animatingViewController = isPresentation? toViewController : fromViewController;
        UIView *animatingView = [animatingViewController view];
        
        [animatingView setFrame:[transitionContext finalFrameForViewController:animatingViewController]];
        
        CGAffineTransform presentedTransform = CGAffineTransformIdentity;
        CGAffineTransform dismissedTransform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.001, 0.001), CGAffineTransformMakeRotation(8 * M_PI));
        
        [animatingView setTransform:isPresentation ? dismissedTransform : presentedTransform];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.8 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^
         {
             [animatingView setTransform:isPresentation ? presentedTransform : dismissedTransform];
         }
                         completion:^(BOOL finished){
                             if(![self isPresentation])
                             {
                                 [fromView removeFromSuperview];
                             }
                             [transitionContext completeTransition:YES];
                         }];

    }
    else
    {
        UIView *containerView = [transitionContext containerView];
        BOOL isPresentation = [self isPresentation];
        if (isPresentation)
        {
            [containerView addSubview:toView];
        }
        
        UIViewController *animatingViewController = isPresentation? toViewController : fromViewController;
        UIView *animatingView = [animatingViewController view];
        
        [animatingView setFrame:[transitionContext finalFrameForViewController:animatingViewController]];
        
        CGAffineTransform presentedTransform = CGAffineTransformIdentity;
        CGAffineTransform dismissedTransform = CGAffineTransformMakeScale(0.001, 0.001);
        
        [animatingView setTransform:isPresentation ? dismissedTransform : presentedTransform];
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.8 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState animations:^
        {
            [animatingView setTransform:isPresentation ? presentedTransform : dismissedTransform];
                         }
                         completion:^(BOOL finished){
                             if(![self isPresentation])
                             {
                                 [fromView removeFromSuperview];
                             }
                             [transitionContext completeTransition:YES];
                         }];
    }
}

@end
