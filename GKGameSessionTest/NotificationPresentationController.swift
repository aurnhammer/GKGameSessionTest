//
//  NotificationPresentationController.swift
//  GKGameSessionTest
//
//  Created by Bill A on 3/14/17.
//  Copyright © 2017 aurnhammer. All rights reserved.
//

public let CORNER_RADIUS: CGFloat = 16.0

import UIKit

class NotificationPresentationController: UIPresentationController {
    
    var dimmingView: UIView?
    var presentationWrappingView: UIView?
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        // The presented view controller must have a modalPresentationStyle
        // of UIModalPresentationCustom for a custom presentation controller
        // to be used.
        presentedViewController.modalPresentationStyle = UIModalPresentationStyle.custom;
    }
    
    override var presentedView: UIView {
        get {
          return self.presentationWrappingView!
        }
    }
    
    //| ----------------------------------------------------------------------------
    //  This is one of the first methods invoked on the presentation controller
    //  at the start of a presentation.  By the time this method is called,
    //  the containerView has been created and the view hierarchy set up for the
    //  presentation.  However, the -presentedView has not yet been retrieved.
    //
    override func presentationTransitionWillBegin() {
        // The default implementation of -presentedView returns
        // self.presentedViewController.view.
        guard let presentedViewControllerView = super.presentedView else { return }
        
        let presentationWrapperView = UIView.init(frame: self.frameOfPresentedViewInContainerView)
        
        
        presentationWrapperView.layer.shadowOpacity = 0.44
        presentationWrapperView.layer.shadowRadius = 13.0
        presentationWrapperView.layer.shadowOffset = CGSize(width: 0, height: -6.0);
        self.presentationWrappingView = presentationWrapperView;
        
        // presentationRoundedCornerView is CORNER_RADIUS points taller than the
        // height of the presented view controller's view.  This is because
        // the cornerRadius is applied to all corners of the view.  Since the
        // effect calls for only the top two corners to be rounded we size
        // the view such that the bottom CORNER_RADIUS points lie below
        // the bottom edge of the screen.
        let presentationRoundedCornerView = UIView(frame: UIEdgeInsetsInsetRect(presentationWrapperView.bounds, UIEdgeInsetsMake(0, 0, -CORNER_RADIUS, 0)))
            
        presentationRoundedCornerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentationRoundedCornerView.layer.cornerRadius = CORNER_RADIUS
        presentationRoundedCornerView.layer.masksToBounds = true
        
        // To undo the extra height added to presentationRoundedCornerView,
        // presentedViewControllerWrapperView is inset by CORNER_RADIUS points.
        // This also matches the size of presentedViewControllerWrapperView's
        // bounds to the size of -frameOfPresentedViewInContainerView.
        let presentedViewControllerWrapperView = UIView(frame: UIEdgeInsetsInsetRect(presentationRoundedCornerView.bounds, UIEdgeInsetsMake(0, 0, CORNER_RADIUS, 0)))
        
        presentedViewControllerWrapperView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Add presentedViewControllerView -> presentedViewControllerWrapperView.
        presentedViewControllerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        presentedViewControllerView.frame = presentedViewControllerWrapperView.bounds
        presentedViewControllerWrapperView.addSubview(presentedViewControllerView)
        
        // Add presentedViewControllerWrapperView -> presentationRoundedCornerView.
        presentationRoundedCornerView.addSubview(presentedViewControllerWrapperView)
        
        // Add presentationRoundedCornerView -> presentationWrapperView.
        presentationWrapperView.addSubview(presentationRoundedCornerView)
        
        // Add a dimming view behind presentationWrapperView.  self.presentedView
        // is added later (by the animator) so any views added here will be
        // appear behind the -presentedView.
        let dimmingView = UIView.init(frame: self.containerView!.bounds)
        
        dimmingView.backgroundColor = UIColor.black
        dimmingView.isOpaque = false
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dimmingView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(dimmingViewTapped)))
        self.dimmingView = dimmingView
        self.containerView?.addSubview(dimmingView)
        
        // Get the transition coordinator for the presentation so we can
        // fade in the dimmingView alongside the presentation animation.
        let transitionCoordinator = self.presentingViewController.transitionCoordinator;
        
        self.dimmingView?.alpha = 0.0
        transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.dimmingView?.alpha = 0.5
        }, completion: nil)
    }
    
    //| ----------------------------------------------------------------------------
    override func presentationTransitionDidEnd(_ completed: Bool) {
        // The value of the 'completed' argument is the same value passed to the
        // -completeTransition: method by the animator.  It may
        // be NO in the case of a cancelled interactive transition.
        if completed == true  {
            // The system removes the presented view controller's view from its
            // superview and disposes of the containerView.  This implicitly
            // removes the views created in -presentationTransitionWillBegin: from
            // the view hierarchy.  However, we still need to relinquish our strong
            // references to those view.
            self.presentationWrappingView = nil
            self.dimmingView = nil
        }
    }
    
    
    //| ----------------------------------------------------------------------------
    override func dismissalTransitionWillBegin() {
        // Get the transition coordinator for the dismissal so we can
        // fade out the dimmingView alongside the dismissal animation.
        let transitionCoordinator = self.presentingViewController.transitionCoordinator
        transitionCoordinator?.animate(alongsideTransition: { (context) in
            self.dimmingView?.alpha = 0.5
        }, completion: nil)
    }
    
    
    //| ----------------------------------------------------------------------------
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        // The value of the 'completed' argument is the same value passed to the
        // -completeTransition: method by the animator.  It may
        // be NO in the case of a cancelled interactive transition.
        if completed == true {
            // The system removes the presented view controller's view from its
            // superview and disposes of the containerView.  This implicitly
            // removes the views created in -presentationTransitionWillBegin: from
            // the view hierarchy.  However, we still need to relinquish our strong
            // references to those view.
            self.presentationWrappingView = nil
            self.dimmingView = nil
        }
    }
    
    //MARK: - Layout
    
    //| ----------------------------------------------------------------------------
    //  This method is invoked whenever the presentedViewController's
    //  preferredContentSize property changes.  It is also invoked just before the
    //  presentation transition begins (prior to -presentationTransitionWillBegin).
    //
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
		if self.presentedViewController	== container as? UIViewController {
			self.containerView?.setNeedsLayout()
		}
    }
    
    
    //| ----------------------------------------------------------------------------
    //  When the presentation controller receives a
    //  -viewWillTransitionToSize:withTransitionCoordinator: message it calls this
    //  method to retrieve the new size for the presentedViewController's view.
    //  The presentation controller then sends a
    //  -viewWillTransitionToSize:withTransitionCoordinator: message to the
    //  presentedViewController with this size as the first argument.
    //
    //  Note that it is up to the presentation controller to adjust the frame
    //  of the presented view controller's view to match this promised size.
    //  We do this in -containerViewWillLayoutSubviews.
    //
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        if self.presentedViewController == container as? UIViewController {
            return container.preferredContentSize
        }
        else {
            return super.size(forChildContentContainer: container, withParentContainerSize: parentSize)
        }
    }
    
    
    //| ----------------------------------------------------------------------------
    override var frameOfPresentedViewInContainerView: CGRect {
        let containerViewBounds = self.containerView?.bounds
        let presentedViewContentSize = self.size(forChildContentContainer: self.presentedViewController, withParentContainerSize: containerViewBounds!.size)
        // The presented view extends presentedViewContentSize.height points from
        // the bottom edge of the screen.
        var presentedViewControllerFrame = containerViewBounds
        presentedViewControllerFrame?.size.height = presentedViewContentSize.height
        presentedViewControllerFrame?.origin.y = containerViewBounds!.maxY - presentedViewContentSize.height;
        return presentedViewControllerFrame!
    }
    
    
    //| ----------------------------------------------------------------------------
    //  This method is similar to the -viewWillLayoutSubviews method in
    //  UIViewController.  It allows the presentation controller to alter the
    //  layout of any custom views it manages.
    //
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        self.dimmingView?.frame = self.containerView!.bounds
        self.presentationWrappingView?.frame = self.frameOfPresentedViewInContainerView;
    }
    
    // MARK: -  Tap Gesture Recognizer
    
    //| ----------------------------------------------------------------------------
    //  IBAction for the tap gesture recognizer added to the dimmingView.
    //  Dismisses the presented view controller.
    //
    @IBAction func dimmingViewTapped(sender: UITapGestureRecognizer)  {
        self.presentingViewController.dismiss(animated: true, completion: nil)
    }
}


// MARK: - UIViewControllerAnimatedTransitioning

extension NotificationPresentationController: UIViewControllerAnimatedTransitioning {
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let transitionContext = transitionContext else { return 0 }
        return transitionContext.isAnimated ? 0.35 : 0
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) else { return }
        
        guard let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) else { return }
        
        let containerView: UIView = transitionContext.containerView
        
        guard let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) else { return }
        guard let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) else { return }
        
        let isPresenting = fromViewController == self.presentingViewController
        
        // This will be the current frame of fromViewController.view.
        _ = transitionContext.initialFrame(for: fromViewController)
        // For a presentation which removes the presenter's view, this will be
        // CGRectZero.  Otherwise, the current frame of fromViewController.view.
        var fromViewFinalFrame = transitionContext.finalFrame(for:fromViewController)
        
        // This will be CGRectZero.
        var toViewInitialFrame = transitionContext.initialFrame(for: toViewController)
        // For a presentation, this will be the value returned from the
        // presentation controller's -frameOfPresentedViewInContainerView method.
        let toViewFinalFrame = transitionContext.finalFrame(for: toViewController)
        // We are responsible for adding the incoming view to the containerView
        // for the presentation (will have no effect on dismissal because the
        // presenting view controller's view was not removed).
        containerView.addSubview(toView)
        
        if isPresenting {
            toViewInitialFrame.origin = CGPoint(x: containerView.bounds.minX, y: containerView.bounds.maxY);
            toViewInitialFrame.size = toViewFinalFrame.size;
            toView.frame = toViewInitialFrame;
        } else {
            // Because our presentation wraps the presented view controller's view
            // in an intermediate view hierarchy, it is more accurate to rely
            // on the current frame of fromView than fromViewInitialFrame as the
            // initial frame (though in this example they will be the same).
            fromViewFinalFrame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height);
        }
        
        let transitionDuration = self.transitionDuration(using: transitionContext)
        
        UIView.animate(withDuration: transitionDuration) { 
            
        }
        
        UIView.animate(withDuration: transitionDuration, animations: {
            if isPresenting {
                toView.frame = toViewFinalFrame
            }
            else {
                fromView.frame = fromViewFinalFrame
            }
        }) { (finished) in
            // When we complete, tell the transition context
            // passing along the BOOL that indicates whether the transition
            // finished or not.
            let wasCancelled = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!wasCancelled)
        }
     }
}

// MARK: - UIViewControllerTransitioningDelegate

extension NotificationPresentationController: UIViewControllerTransitioningDelegate {
    //| ----------------------------------------------------------------------------
    //  If the modalPresentationStyle of the presented view controller is
    //  UIModalPresentationCustom, the system calls this method on the presented
    //  view controller's transitioningDelegate to retrieve the presentation
    //  controller that will manage the presentation.  If your implementation
    //  returns nil, an instance of UIPresentationController is used.
    //
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if self.presentedViewController == presented {
            Log.message("You didn't initialize \(self) with the correct presentedViewController.  Expected \(presented), got \(self.presentedViewController)")
        }
        return self
    }
    //| ----------------------------------------------------------------------------
    //  The system calls this method on the presented view controller's
    //  transitioningDelegate to retrieve the animator object used for animating
    //  the presentation of the incoming view controller.  Your implementation is
    //  expected to return an object that conforms to the
    //  UIViewControllerAnimatedTransitioning protocol, or nil if the default
    //  presentation animation should be used.
    //
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    //| ----------------------------------------------------------------------------
    //  The system calls this method on the presented view controller's
    //  transitioningDelegate to retrieve the animator object used for animating
    //  the dismissal of the presented view controller.  Your implementation is
    //  expected to return an object that conforms to the
    //  UIViewControllerAnimatedTransitioning protocol, or nil if the default
    //  dismissal animation should be used.
    //
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
}
