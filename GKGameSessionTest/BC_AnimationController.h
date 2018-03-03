//
//  BC_AnimationController.h
//  customPresentationController
//
//  Created by Bill A on 9/25/15.
//  Copyright © 2015 beaconcrawl.com. All rights reserved.
//

@import UIKit;

@interface BC_AnimationController : NSObject <UIViewControllerAnimatedTransitioning>
@property (nonatomic) BOOL isPresentation;
@property (nonatomic) BOOL isFlipAnimation;
@property (nonatomic) BOOL isFullScreen;
@end
