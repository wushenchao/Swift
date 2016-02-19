//
//  WWMenuViewController.swift
//  AND
//
//  Created by 吴申超 on 16/2/17.
//  Copyright © 2016年 吴申超. All rights reserved.
//

import UIKit

let WWMenuFullWidth: CGFloat = UIScreen.mainScreen().bounds.size.width - 50
let WWMenuDisplayWidth: CGFloat = WWMenuFullWidth + 5.0
let WWMenuBounceOffset: CGFloat = 10.0
let WWMenuBounceDuration: CGFloat = 0.3
let WWMenuSlideDuration: CGFloat = 0.3


enum WWMenuPanDirection: Int {
    case Left
    case Right
}

enum WWMenuPanCompletion: Int {
    case Left
    case Right
    case Root
}

struct menuFlags {
    var showingLeftView: Bool = false
    var showingRightView: Bool = false
    var canShowRight: Bool = false
    var canShowLeft: Bool = false
}

protocol WWMenuViewControllerDelegate: NSObjectProtocol {
    func menuController(controller:WWMenuViewController ,showController: UIViewController)
}

class WWMenuViewController: UIViewController , UIGestureRecognizerDelegate{
    
    var WWMenuOverlayWidth: CGFloat!
    weak var delegate: WWMenuViewControllerDelegate?
    
    var leftViewController: UIViewController? {
        didSet {
            menuFlag.canShowLeft = true
            resetNavButtons()
        }
    }
    var rightViewController: UIViewController? {
        didSet {
            menuFlag.canShowRight = true
            resetNavButtons()
        }
    }
    var rootViewController: UIViewController!
    var tap: UITapGestureRecognizer?
    var pan: UIPanGestureRecognizer?
    
    var panOriginX: CGFloat!
    var panVelocity: CGPoint!
    
    var panDirection: WWMenuPanDirection!
    var menuFlag = menuFlags()
    
    required init(rootViewController: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        self.rootViewController = rootViewController
        setRootViewController(rootViewController)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        WWMenuOverlayWidth = self.view.bounds.size.width - WWMenuDisplayWidth
        self.tap = UITapGestureRecognizer(target: self, action: "tap:")
        self.tap?.delegate = self
        self.view.addGestureRecognizer(self.tap!)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        if (rootViewController != nil) {
            rootViewController.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
            let view = rootViewController.view
            var frame = self.view.bounds
            if (menuFlag.showingRightView) {
                view.autoresizingMask = UIViewAutoresizing.FlexibleRightMargin
                frame.origin.x = frame.size.width - WWMenuOverlayWidth
            }
            else if (menuFlag.showingLeftView) {
                view.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin
                frame.origin.x = -(frame.size.width - WWMenuOverlayWidth)
            }
            else {
                view.autoresizingMask = UIViewAutoresizing.FlexibleHeight
                view.autoresizingMask = UIViewAutoresizing.FlexibleWidth
            }
            
            rootViewController.view.frame = frame
            rootViewController.view.autoresizingMask = self.view.autoresizingMask
            self.showShade(rootViewController.view.layer.shadowOpacity != 0.0)
        }
    }
    
    //MARK: - GestureRecogizers
    func tap(gesture: UITapGestureRecognizer) {
        gesture.enabled = false
        self.showRootController(true)
    }
    
    func pan(gesture: UIPanGestureRecognizer) {
        
        var velocity = gesture.velocityInView(self.view)

        if (gesture.state == UIGestureRecognizerState.Began) {
            showShade(true)
            panOriginX = self.view.frame.origin.x
            panVelocity = CGPointZero
            
            if (velocity.x > 0) {
                panDirection = WWMenuPanDirection.Right
            }
            else {
                panDirection = WWMenuPanDirection.Left
            }
        }
        
        if (gesture.state == UIGestureRecognizerState.Changed) {
            if ((velocity.x * panVelocity.x + velocity.y * panVelocity.y) < 0) {
                panDirection = (panDirection == .Right ? .Left : .Right)
            }
            
            panVelocity = velocity
            let translation = gesture.translationInView(self.view)
            var frame = rootViewController.view.frame;
            frame.origin.x = panOriginX + translation.x
            
            if (frame.origin.x > 0 && !menuFlag.showingLeftView){
                if (menuFlag.showingRightView) {
                    menuFlag.showingRightView = false
                    rightViewController!.view.removeFromSuperview()
                }
                
                if (menuFlag.canShowLeft) {
                    menuFlag.showingLeftView = true
                    var frame = self.view.bounds
                    frame.size.width = WWMenuFullWidth
                    leftViewController!.view.frame = frame
                    self.view.insertSubview(leftViewController!.view, atIndex: 0)
                }
                else {
                    frame.origin.x = 0
                }
            }
            else if (frame.origin.x < 0 && !menuFlag.showingRightView) {
                if (menuFlag.showingLeftView) {
                    menuFlag.showingLeftView = false
                    leftViewController!.view.removeFromSuperview()
                }
                
                if (menuFlag.canShowRight) {
                    menuFlag.showingRightView = true
                    var frame = self.view.bounds
                    frame.origin.x += frame.size.width - WWMenuFullWidth
                    frame.size.width = WWMenuFullWidth
                    rightViewController!.view.frame = frame
                    self.view.insertSubview(rightViewController!.view, atIndex: 0)
                }
                else {
                    frame.origin.x = 0
                }
            }
            rootViewController.view.frame = frame
        }
        else if (gesture.state == UIGestureRecognizerState.Cancelled || gesture.state == UIGestureRecognizerState.Ended) {
            
            //  Finishing moving to left, right or root view with current pan velocity
            self.view.userInteractionEnabled = false
            
            // by default animate back to the root
            var menuCompletion = WWMenuPanCompletion.Root
            
            if (panDirection == .Right && menuFlag.showingLeftView) {
                menuCompletion = .Left
            }
            else if (panDirection == .Left && menuFlag.showingRightView) {
                menuCompletion = .Right
            }
            
            if (velocity.x < 0.0) {
                velocity.x *= -1.0
            }
            let bounce = velocity.x > 800
            let originX = rootViewController.view.frame.origin.x
            let width = rootViewController.view.frame.size.width
            let span = width - WWMenuOverlayWidth
            var duration = WWMenuSlideDuration
            
            if (bounce) {
                duration = span / velocity.x
            }
            else {
                duration = (span - originX) / span
            }
            
            // animation
            CATransaction.begin()
            CATransaction.setCompletionBlock({ () -> Void in
                if (menuCompletion == .Left) {
                    self.showLeftController(false)
                }
                else if (menuCompletion == .Right) {
                    self.showRightController(false)
                }
                else {
                    self.showRootController(false)
                }
                self.rootViewController.view.layer.removeAllAnimations()
                self.view.userInteractionEnabled = true
            })
            
            let animation = CAKeyframeAnimation(keyPath: "position")
            
            let pos = rootViewController.view.layer.position
            var values :Array<NSValue> = [NSValue(CGPoint: pos)]
            var keyTimes: Array<CGFloat> = [0.0]
            var timingFunctions: Array = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)]
            if (bounce) {
                duration += WWMenuBounceDuration
                keyTimes.append(1.0 - ( WWMenuBounceDuration / duration))
                
                if (menuCompletion == .Left) {
                    values.append(NSValue(CGPoint: CGPointMake(((width / 2) + span) + WWMenuBounceOffset, pos.y)))
                }
                else if (menuCompletion == .Right) {
                    values.append(NSValue(CGPoint: CGPointMake(-((width / 2) - (WWMenuOverlayWidth-WWMenuBounceOffset)), pos.y)))
                }
                else {
                    // depending on which way we're panning add a bounce offset
                    if (panDirection == .Left) {
                        values.append(NSValue(CGPoint: CGPointMake(((width / 2) + span) - WWMenuBounceOffset, pos.y)))
                    }
                    else {
                        values.append(NSValue(CGPoint: CGPointMake(((width / 2) + span) + WWMenuBounceOffset, pos.y)))
                    }
                }
                timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
            }
            
            if (menuCompletion == .Left) {
                values.append(NSValue(CGPoint: CGPointMake((width / 2) + span, pos.y)))
            }
            else if (menuCompletion == .Right) {
                values.append(NSValue(CGPoint: CGPointMake(-((width/2) - WWMenuOverlayWidth), pos.y)))
            }
            else {
                values.append(NSValue(CGPoint: CGPointMake(width / 2, pos.y)))
            }
            timingFunctions.append(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
            keyTimes.append(1.0)
            animation.timingFunctions = timingFunctions
            animation.keyTimes = keyTimes
            animation.values = values
            animation.duration = NSTimeInterval(duration)
            animation.removedOnCompletion = false
            animation.fillMode = kCAFillModeForwards
            rootViewController.view.layer.addAnimation(animation, forKey: "")
            CATransaction.commit()
        }
    }
    
    // MARK: - ShowViewController
    func showLeftController (animated: Bool) {
        if (!menuFlag.canShowLeft) {
            return
        }
        
        if (rightViewController != nil && rightViewController!.view.superview != nil) {
            rightViewController!.view.removeFromSuperview()
            menuFlag.showingRightView = false
        }
        
        // MARK: delegate
        delegate?.menuController(self, showController: leftViewController!)
        
        menuFlag.showingLeftView = true
        self.showShade(true)
        
        let view = self.leftViewController!.view
        var frame = self.view.bounds
        frame.size.width = WWMenuFullWidth
        view.frame = frame
        self.view.insertSubview(view, atIndex: 0)
        self.leftViewController!.viewWillAppear(animated)
        
        frame = rootViewController.view.frame
        frame.origin.x = CGRectGetMaxX(view.frame) - (WWMenuFullWidth - WWMenuDisplayWidth)
        self.viewControllerAnimated(animated, frame: frame)
    }
    
    func showRightController (animated: Bool) {
        if (!menuFlag.canShowRight) {
            return
        }
        
        if (leftViewController != nil && leftViewController!.view.superview != nil) {
            leftViewController!.view.removeFromSuperview()
            menuFlag.showingLeftView = false
        }
        
        // MARK: delegate
        delegate?.menuController(self, showController: rightViewController!)
        
        menuFlag.showingRightView = true
        self.showShade(true)
        let view = self.rightViewController!.view
        var frame = self.view.bounds
        frame.origin.x  += frame.size.width - WWMenuFullWidth
        frame.size.width = WWMenuFullWidth
        view.frame = frame
        self.view.insertSubview(view, atIndex: 0)
        self.rightViewController!.viewWillAppear(animated)
        
        frame = rootViewController.view.frame
        frame.origin.x = -(frame.size.width - WWMenuOverlayWidth)
        self.viewControllerAnimated(animated, frame: frame)
    }
    
    private func viewControllerAnimated(animated: Bool, frame: CGRect){
        let enable = UIView.areAnimationsEnabled()
        if (!animated) {
            UIView.setAnimationsEnabled(false)
        }
        self.rootViewController.view.userInteractionEnabled = false
        UIView.animateWithDuration(0.3, animations: { () -> Void in
            self.rootViewController.view.frame = frame
            }) { (completion) -> Void in
                self.tap?.enabled = true
        }
        if (!animated) {
            UIView.setAnimationsEnabled(enable)
        }
    }
    
    func showRootController (animated: Bool) {
        tap?.enabled = false
        rootViewController.view.userInteractionEnabled = true
        var frame = rootViewController.view.frame
        frame.origin.x = 0.0
        
        let enable = UIView.areAnimationsEnabled()
        if (!animated) {
            UIView.setAnimationsEnabled(false)
        }
        UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.rootViewController.view.frame = frame
            
            }) { (completion) -> Void in
              
                if (self.leftViewController != nil && self.leftViewController!.view.superview != nil) {
                    self.leftViewController!.view.removeFromSuperview()
                }
                
                if (self.rightViewController != nil && self.rightViewController!.view.superview != nil) {
                    self.rightViewController!.view.removeFromSuperview()
                }
                self.menuFlag.showingLeftView = false
                self.menuFlag.showingRightView = false
                self.showShade(false)
        }
        if (!animated) {
            UIView.setAnimationsEnabled(enable)
        }
    }
    
    private func showShade(val: Bool) {
        if (rootViewController != nil) {
            rootViewController.view.layer.shadowOpacity = val ? 0.8 : 0.0
            if (val) {
                rootViewController.view.layer.cornerRadius = 4.0;
                rootViewController.view.layer.shadowOffset = CGSizeZero;
                rootViewController.view.layer.shadowRadius = 4.0;
                rootViewController.view.layer.shadowPath = UIBezierPath(rect: self.view.bounds).CGPath;
            }
        }
    }
    
    // MARK: - SetRoot
    private func setRootViewController(root: UIViewController){
        let tempRoot = rootViewController;
        rootViewController = root
        if (rootViewController != nil) {
            if (tempRoot != nil) {
                tempRoot.view.removeFromSuperview()
            }
            let rootView = rootViewController.view;
            rootView.frame = self.view.bounds
            self.view.addSubview(rootView)
            
            self.pan = UIPanGestureRecognizer(target: self, action: "pan:")
            self.pan!.delegate = self
            rootView.addGestureRecognizer(self.pan!)
        }
        else {
            if (tempRoot != nil) {
                tempRoot.view.removeFromSuperview()
            }
        }
        self.resetNavButtons()
    }
    
    private func setRootViewController(controller: UIViewController, animated: Bool){
        
        if ((controller.view == nil)) {
            self.setRootViewController(controller)
            return
        }
        if (menuFlag.showingLeftView) {
            UIApplication.sharedApplication().beginIgnoringInteractionEvents()
            let root = rootViewController
            var frame = root.view.frame
            frame.origin.x = root.view.bounds.size.width
            UIView.animateWithDuration(0.1, animations: { () -> Void in
                
                    root.view.frame = frame
                }, completion: { (completion) -> Void in
                    UIApplication.sharedApplication().endIgnoringInteractionEvents()
                    self.setRootViewController(controller)
                    self.rootViewController.view.frame = frame
                    self.showRootController(animated)
            })
            
        }
        else {
            self.setRootViewController(controller)
            self.showRootController(animated)
        }
    }
    
    
    // MARK: - resetNavButtons
    private func resetNavButtons() {
        if (rootViewController == nil) {
            return;
        }
        var topController: UIViewController?
        if (rootViewController.isKindOfClass(UINavigationController)) {
            let navController = rootViewController as! UINavigationController
            if (navController.viewControllers.count > 0) {
                topController = navController.viewControllers[0]
            }
        }
        else if (rootViewController.isKindOfClass(UITabBarController)) {
            let tabController = rootViewController as! UITabBarController
            topController = tabController.selectedViewController
        }
        else {
            topController = rootViewController
        }
        
        if (menuFlag.canShowLeft) {
            let button = UIBarButtonItem(image: UIImage(named: "nav_menu_icon.png"), style: .Plain, target: self, action: "showLeft:")
            topController?.navigationItem.leftBarButtonItem = button
        }
        else {
            topController?.navigationItem.leftBarButtonItem = nil
        }
        
        if (menuFlag.canShowRight) {
            let button = UIBarButtonItem(image: UIImage(named: "nav_menu_icon.png"), style: .Plain, target: self, action: "showRight:")
            topController?.navigationItem.rightBarButtonItem = button
        }
        else {
            topController?.navigationItem.rightBarButtonItem = nil
            
        }
    }
    
    
    
    // MARK: - Actions
    func showLeft(button: UIButton){
        self.showLeftController(true)
    }
    
    func showRight(button: UIButton) {
        self.showRightController(true)
    }
    
    // MARK: - Root Controller Navigation
    
    func pushViewController(controller: UIViewController, animated: Bool) {
        
        var navController: UINavigationController!
        if (rootViewController.isKindOfClass(UINavigationController)) {
            navController = rootViewController as! UINavigationController
        }
        else if (rootViewController.isKindOfClass(UITabBarController)) {
            let rootTabBar = rootViewController as! UITabBarController
            let topController: UIViewController! = rootTabBar.selectedViewController
            if (topController.isKindOfClass(UINavigationController)) {
                navController = topController as! UINavigationController
            }
        }
        
        if (navController == nil) {
            print("root controller is not a navigation controller.")
            return
        }
        
        if (menuFlag.showingRightView) {
            let layer = CALayer()
            let layerFrame = self.view.bounds
            layer.frame = layerFrame
            
            UIGraphicsBeginImageContextWithOptions(layerFrame.size, true, 0)
            let ctx = UIGraphicsGetCurrentContext()!
            self.view.layer.renderInContext(ctx)
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            layer.contents = image.CGImage
            
            
            self.view.layer.addSublayer(layer)
            navController.pushViewController(controller, animated: false)
            
            var frame = rootViewController.view.frame
            frame.origin.x = frame.size.width
            rootViewController.view.frame = frame
            frame.origin.x = 0.0
            
            let currentTransform = self.view.transform
            UIView.animateWithDuration(0.25, animations: { () -> Void in
                
                if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication().statusBarOrientation)){
                    self.view.transform = CGAffineTransformConcat(currentTransform, CGAffineTransformMakeTranslation(0, -(UIScreen.mainScreen().bounds.size.height)))
                }
                else {
                     self.view.transform = CGAffineTransformConcat(currentTransform, CGAffineTransformMakeTranslation(-(UIScreen.mainScreen().bounds.size.width), 0))
                }
                
                }, completion: { (completion) -> Void in
                    self.showRootController(false)
                    self.view.transform = CGAffineTransformConcat(currentTransform, CGAffineTransformMakeTranslation(0.0, 0.0))
                    layer.removeFromSuperlayer()
            })
        }
        else {
            navController.pushViewController(controller, animated: animated)
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == pan) {
            let panGesture = gestureRecognizer as! UIPanGestureRecognizer
            let translation = panGesture.translationInView(self.view)
            if (panGesture.velocityInView(self.view).x < 600 &&
                translation.x / translation.y > 1) {
                return true
            }
            return false
        }
        if (gestureRecognizer == tap) {
            if (rootViewController != nil && (menuFlag.showingRightView || menuFlag.showingLeftView)) {
                return CGRectContainsPoint(rootViewController.view.frame, gestureRecognizer.locationInView(self.view))
            }
            return false
        }
        return true
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == tap) {
            return true
        }
        return false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
