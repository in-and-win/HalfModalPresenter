//
//  HalfModalPresenterViewController.swift
//  HalfModalPresenter
//
//  Created by Raphael Bischof on 15/08/16.
//  Copyright © 2016 InAndWin. All rights reserved.
//

import UIKit

public protocol OpenedView {
    var closer:ContainerView? {get set}
}

public protocol ContainerView {
    func close()
}

public class HalfModalPresenter {
    private let transitionView:UIView
    
    private let containerViewController:UIViewController
    
    private var bubble:UIImageView?
    private var expandedPanel:UIView?
    private var gesture:UITapGestureRecognizer?
    private var dismissHitBox:UIView?
    private var baseTransitionViewFrame:CGRect?
    private let animationSpeed:Double = 1
    
    public init(transitionView: UIView, containerViewController: UIViewController){
        self.transitionView = transitionView
        self.containerViewController = containerViewController
        self.baseTransitionViewFrame = transitionView.frame
    }
    
    public func presentHalfScreenView(expandedPanel: UIView, background: UIImage?){
        self.expandedPanel = expandedPanel
        self.gesture = UITapGestureRecognizer(target: self, action: #selector(HalfModalPresenter.dismissHalfScreenView))
        dismissHitBox = UIView(frame: containerViewController.view.frame)
        containerViewController.view.addSubview(dismissHitBox!)
        self.dismissHitBox!.addGestureRecognizer(gesture!)
        
        let center = transitionView.superview!.convertPoint(transitionView.center, toView: nil)
        if var expandedPanel = expandedPanel as? OpenedView,
            let delegate = containerViewController as? ContainerView {
            expandedPanel.closer = delegate
        }
        let screenHeight = UIScreen.mainScreen().bounds.height
        let screenWidth = UIScreen.mainScreen().bounds.width
        expandedPanel.frame = CGRectMake(center.x, center.y, 0, 0)
        
        
        bubble = UIImageView()
        if let bubble = bubble {
            bubble.backgroundColor = transitionView.backgroundColor
            if let background = background {
                bubble.image = background
            }
            bubble.frame = CGRectMake(-screenHeight/4, screenHeight/2, screenWidth+screenHeight/2, screenHeight/2)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.hidden = true
            self.containerViewController.view.insertSubview(bubble, belowSubview: expandedPanel)
        }
        
        expandedPanel.center = center
        expandedPanel.clipsToBounds = true
        containerViewController.view.addSubview(expandedPanel)
        
        let transitionViewFrame = self.transitionView.frame
        let futureY = transitionViewFrame.origin.y - screenHeight * 0.02
        let futureX = transitionViewFrame.origin.x
        let futureHeight = transitionViewFrame.height / 1.30
        let futureWidth = transitionViewFrame.width / 1.30
        
        let anim1: CABasicAnimation = CABasicAnimation(keyPath: "cornerRadius")
        anim1.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        anim1.fromValue = Int(self.transitionView.frame.height/2)
        anim1.toValue = Int(futureHeight/2)
        anim1.duration = 0.1/animationSpeed
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.transitionView.layer.addAnimation(anim1, forKey: "cornerRadius")
        CATransaction.commit()
        UIView.animateWithDuration(0.1/animationSpeed, animations: {
            for constraint in self.transitionView.constraints {
                if constraint.firstAttribute == .Height {
                    constraint.constant = futureHeight
                }
                if constraint.firstAttribute == .Width {
                    constraint.constant = futureWidth
                }
                if constraint.firstAttribute == .Bottom {
                    constraint.constant = constraint.constant + 0.02*screenHeight - futureHeight + transitionViewFrame.height
                }
            }
            for constraint in self.transitionView.superview!.constraints {
                if let secondItem = constraint.secondItem as? UIView where secondItem == self.transitionView && constraint.firstAttribute == .Top {
                    constraint.constant = constraint.constant + 0.02*screenHeight - futureHeight + transitionViewFrame.height
                }
            }
            self.transitionView.frame = CGRectMake(futureX, futureY, futureWidth, futureHeight)
            self.transitionView.layoutIfNeeded()
        }) { (_) in
            self.createBubbleAnimation(self.transitionView.frame,toFrame: self.bubble!.frame, expandedPanelFrame: CGRectMake(0, screenHeight/2, screenWidth, screenHeight/2),completionBlock: nil)
        }
    }
    
    private func createBubbleAnimation(fromFrame: CGRect, toFrame: CGRect, expandedPanelFrame: CGRect, completionBlock: (() -> Void)?){
        self.bubble!.hidden = false
        let mask = self.createCAShapeLayer(self.bubble!, frame: fromFrame, containerFrame: self.bubble!.frame)
        self.bubble!.layer.mask = mask
        
        // define your new path to animate the mask layer to
        let path: UIBezierPath = UIBezierPath(roundedRect: CGRectMake(toFrame.origin.x - self.bubble!.frame.origin.x, toFrame.origin.y - self.bubble!.frame.origin.y, toFrame.size.width, toFrame.size.height), cornerRadius: min(toFrame.size.width, toFrame.size.height))
        
        // create new animation
        let anim = CABasicAnimation(keyPath: "path")
        
        // from value is the current mask path
        anim.fromValue = mask.path
        
        // to value is the new path
        anim.toValue = path.CGPath
        
        // duration of your animation
        anim.duration = 0.4/self.animationSpeed
        
        // custom timing function to make it look smooth
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        
        // update the path property on the mask layer, using a CATransaction to prevent an implicit animation
        CATransaction.begin()
        CATransaction.setCompletionBlock(completionBlock)
        CATransaction.setDisableActions(true)
        // add animation
        mask.addAnimation(anim, forKey: nil)
        mask.path = path.CGPath
        CATransaction.commit()
        UIView.animateWithDuration(0.4/animationSpeed, animations: {
            self.expandedPanel!.frame = expandedPanelFrame
        })
    }
    
    private func createCAShapeLayer(imageView: UIImageView, frame: CGRect, containerFrame: CGRect) -> CAShapeLayer{
        let circle: CAShapeLayer = CAShapeLayer(layer: imageView.layer)
        // Make a circular shape
        let circularPath: UIBezierPath = UIBezierPath(roundedRect: CGRectMake(frame.origin.x - containerFrame.origin.x, frame.origin.y - containerFrame.origin.y, frame.size.width, frame.size.height), cornerRadius: min(frame.size.width, frame.size.height))
        circle.path = circularPath.CGPath
        // Configure the apperence of the circle
        circle.fillColor = UIColor.blackColor().CGColor
        circle.strokeColor = UIColor.blackColor().CGColor
        circle.lineWidth = 0
        return circle
    }
    
    private func frameForBubble(originalCenter: CGPoint, size originalSize: CGSize, start: CGPoint) -> CGRect {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;
        let size = CGSize(width: offset, height: offset)
        
        return CGRect(origin: CGPointZero, size: size)
    }
    
    @objc
    public func dismissHalfScreenView() {
        if let gesture = self.gesture,
            let dismissHitBox = self.dismissHitBox{
            dismissHitBox.removeGestureRecognizer(gesture)
            dismissHitBox.removeFromSuperview()
            self.gesture = nil
        }
        let center = transitionView.superview!.convertPoint(transitionView.center, toView: nil)
        
        self.createBubbleAnimation(self.bubble!.frame,toFrame: self.transitionView.frame, expandedPanelFrame: CGRectMake(center.x, center.y, 0, 0)){
            self.bubble?.removeFromSuperview()
            self.bubble = nil
            let screenHeight = UIScreen.mainScreen().bounds.height
            let transitionViewFrame = self.transitionView.frame
            let futureY = transitionViewFrame.origin.y - screenHeight * 0.02
            let futureX = transitionViewFrame.origin.x
            let futureHeight = transitionViewFrame.height * 1.30
            let futureWidth = transitionViewFrame.width * 1.30
            
            let anim1: CABasicAnimation = CABasicAnimation(keyPath: "cornerRadius")
            anim1.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            anim1.fromValue = Int(transitionViewFrame.height/2)
            anim1.toValue = Int(futureHeight/2)
            anim1.duration = 0.1/self.animationSpeed
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.transitionView.layer.addAnimation(anim1, forKey: "cornerRadius")
            CATransaction.commit()
            UIView.animateWithDuration(0.1/self.animationSpeed, animations: {
                for constraint in self.transitionView.constraints {
                    if constraint.firstAttribute == .Height {
                        constraint.constant = futureHeight
                    }
                    if constraint.firstAttribute == .Width {
                        constraint.constant = futureWidth
                    }
                    if constraint.firstAttribute == .Bottom {
                        constraint.constant = constraint.constant - 0.02*screenHeight - futureHeight + transitionViewFrame.height
                    }
                }
                for constraint in self.transitionView.superview!.constraints {
                    if let secondItem = constraint.secondItem as? UIView where secondItem == self.transitionView && constraint.firstAttribute == .Top {
                        constraint.constant = constraint.constant - 0.02*screenHeight - futureHeight + transitionViewFrame.height
                    }
                }
                self.transitionView.frame = CGRectMake(futureX, futureY, futureWidth, futureHeight)
                self.transitionView.layoutIfNeeded()
            }) { (_) in
            }
        }
    }
}