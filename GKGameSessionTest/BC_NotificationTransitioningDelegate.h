//
//  BC_NotificationTransitioningDelegate.h
//  customPresentationController
//
//  Created by Bill A on 9/25/15.
//  Copyright © 2015 beaconcrawl.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BC_NotificationTransitioningDelegate : NSObject <UIViewControllerTransitioningDelegate>

@property (nonatomic) BOOL isFlipView;
@property (nonatomic) BOOL isFullScreen;

@end
