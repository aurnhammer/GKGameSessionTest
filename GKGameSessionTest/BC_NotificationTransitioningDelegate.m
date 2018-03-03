//
//  BC_NotificationTransitioningDelegate.m
//  customPresentationController
//
//  Created by Bill A on 9/25/15.
//  Copyright © 2015 beaconcrawl.com. All rights reserved.
//

#import "BC_NotificationTransitioningDelegate.h"
#import "BC_NotificationPresentationController.h"
#import "BC_AnimationController.h"

@implementation BC_NotificationTransitioningDelegate

- (UIPresentationController *)presentationControllerForPresentedViewController:(UIViewController *)presented presentingViewController:(UIViewController *)presenting sourceViewController:(UIViewController *)source
{
   BC_NotificationPresentationController* presentationController = [[BC_NotificationPresentationController alloc] initWithPresentedViewController:presented presentingViewController:presenting];
    
    presentationController.isDimmed = _isFlipView ? NO : YES;
    presentationController.isFullScreen = _isFullScreen ? YES : NO;
    return presentationController;
}

- (BC_AnimationController *)animationController
{
    BC_AnimationController *animationController  = [[BC_AnimationController alloc] init];
    animationController.isFlipAnimation = _isFlipView ? YES : NO;
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    BC_AnimationController *animationController = [self animationController];
    [animationController setIsPresentation:YES];
    return animationController;
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    BC_AnimationController *animationController = [self animationController];
    [animationController setIsPresentation:NO];
    
    return animationController;
}


@end
