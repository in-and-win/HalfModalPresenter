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
    func isClosing()
}

open class HalfModalPresenter {
    fileprivate let transitionView:UIView
    
    fileprivate let containerViewController:UIViewController
    
    fileprivate var bubble:UIImageView?
    fileprivate var expandedPanel:UIView?
    fileprivate var gesture:UITapGestureRecognizer?
    fileprivate var dismissHitBox:UIView?
    fileprivate var baseTransitionViewFrame:CGRect?
    fileprivate let animationSpeed:Double = 1
    
    public init(transitionView: UIView, containerViewController: UIViewController){
        self.transitionView = transitionView
        self.containerViewController = containerViewController
        self.baseTransitionViewFrame = transitionView.frame
    }
    
    open func presentHalfScreenView(_ expandedPanel: UIView, background: UIImage?){
        self.expandedPanel = expandedPanel
        self.gesture = UITapGestureRecognizer(target: self, action: #selector(HalfModalPresenter.dismissHalfScreenView))
        dismissHitBox = UIView(frame: containerViewController.view.frame)
        containerViewController.view.addSubview(dismissHitBox!)
        self.dismissHitBox!.addGestureRecognizer(gesture!)
        
        if var expandedPanel = expandedPanel as? OpenedView,
            let delegate = containerViewController as? ContainerView {
            expandedPanel.closer = delegate
        }
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        
        bubble = UIImageView()
        if let bubble = bubble {
            bubble.backgroundColor = transitionView.backgroundColor
            if let background = background {
                bubble.image = background
            }
            bubble.frame = CGRect(x: -screenHeight/4, y: screenHeight/2, width: screenWidth+screenHeight/2, height: screenHeight/2)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.isHidden = true
            self.containerViewController.view.insertSubview(bubble, belowSubview: expandedPanel)
        }
        let maskContent = self.createCAShapeLayer(self.expandedPanel!, frame: CGRect.zero, containerFrame: CGRect.zero)
        self.expandedPanel!.layer.mask = maskContent
        
        expandedPanel.clipsToBounds = true
        expandedPanel.frame = bubble!.frame
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
        self.transitionView.layer.add(anim1, forKey: "cornerRadius")
        CATransaction.commit()
        UIView.animate(withDuration: 0.1/animationSpeed, animations: {
            for constraint in self.transitionView.constraints {
                if constraint.firstAttribute == .height {
                    constraint.constant = futureHeight
                }
                if constraint.firstAttribute == .width {
                    constraint.constant = futureWidth
                }
                if constraint.firstAttribute == .bottom {
                    constraint.constant = constraint.constant + 0.02*screenHeight - futureHeight + transitionViewFrame.height
                }
            }
            for constraint in self.transitionView.superview!.constraints {
                if let secondItem = constraint.secondItem as? UIView, secondItem == self.transitionView && constraint.firstAttribute == .top {
                    constraint.constant = constraint.constant + 0.02*screenHeight - futureHeight + transitionViewFrame.height
                }
            }
            self.transitionView.frame = CGRect(x: futureX, y: futureY, width: futureWidth, height: futureHeight)
            self.transitionView.layoutIfNeeded()
        }, completion: { (_) in
            self.createBubbleAnimation(self.transitionView.frame,toFrame: self.bubble!.frame, contentMask: maskContent,completionBlock: nil)
        }) 
    }
    
    fileprivate func createBubbleAnimation(_ fromFrame: CGRect, toFrame: CGRect, contentMask: CAShapeLayer, completionBlock: (() -> Void)?){
        self.bubble!.isHidden = false
        let mask = self.createCAShapeLayer(self.bubble!, frame: fromFrame, containerFrame: self.bubble!.frame)
        self.bubble!.layer.mask = mask
        
        // define your new path to animate the mask layer to
        let path: UIBezierPath = UIBezierPath(roundedRect: CGRect(x: toFrame.origin.x - self.bubble!.frame.origin.x, y: toFrame.origin.y - self.bubble!.frame.origin.y, width: toFrame.size.width, height: toFrame.size.height), cornerRadius: min(toFrame.size.width, toFrame.size.height))
        let contentPath: UIBezierPath = UIBezierPath(roundedRect: CGRect(x: toFrame.origin.x - self.bubble!.frame.origin.x, y: toFrame.origin.y - self.bubble!.frame.origin.y, width: toFrame.size.width, height: toFrame.size.height), cornerRadius: min(toFrame.size.width, toFrame.size.height))
        
        // create new animation
        let animContent = CABasicAnimation(keyPath: "path")
        let anim = CABasicAnimation(keyPath: "path")
        
        // from value is the current mask path
        animContent.fromValue = contentMask.path
        anim.fromValue = mask.path
        
        // to value is the new path
        animContent.toValue = contentPath.cgPath
        anim.toValue = path.cgPath
        
        // duration of your animation
        animContent.duration = 0.4/self.animationSpeed
        anim.duration = 0.4/self.animationSpeed
        
        // custom timing function to make it look smooth
        animContent.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        
        // update the path property on the mask layer, using a CATransaction to prevent an implicit animation
        CATransaction.begin()
        CATransaction.setCompletionBlock(completionBlock)
        CATransaction.setDisableActions(true)
        // add animation
        mask.add(anim, forKey: nil)
        mask.path = path.cgPath
        contentMask.add(anim, forKey: nil)
        contentMask.path = contentPath.cgPath
        CATransaction.commit()
    }
    
    fileprivate func createCAShapeLayer(_ imageView: UIView, frame: CGRect, containerFrame: CGRect) -> CAShapeLayer{
        let circle: CAShapeLayer = CAShapeLayer(layer: imageView.layer)
        // Make a circular shape
        let circularPath: UIBezierPath = UIBezierPath(roundedRect: CGRect(x: frame.origin.x - containerFrame.origin.x, y: frame.origin.y - containerFrame.origin.y, width: frame.size.width, height: frame.size.height), cornerRadius: min(frame.size.width, frame.size.height))
        circle.path = circularPath.cgPath
        // Configure the apperence of the circle
        circle.fillColor = UIColor.black.cgColor
        circle.strokeColor = UIColor.black.cgColor
        circle.lineWidth = 0
        return circle
    }
    
    fileprivate func frameForBubble(_ originalCenter: CGPoint, size originalSize: CGSize, start: CGPoint) -> CGRect {
        let lengthX = fmax(start.x, originalSize.width - start.x);
        let lengthY = fmax(start.y, originalSize.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2;
        let size = CGSize(width: offset, height: offset)
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
    
    @objc
    open func dismissHalfScreenView() {
        if let gesture = self.gesture,
            let dismissHitBox = self.dismissHitBox{
            dismissHitBox.removeGestureRecognizer(gesture)
            dismissHitBox.removeFromSuperview()
            self.gesture = nil
        }
        if let containerView = containerViewController as? ContainerView {
            containerView.isClosing()
        }
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let center = transitionView.superview!.convert(transitionView.center, to: nil)
        
        let maskContent = self.createCAShapeLayer(self.expandedPanel!, frame: CGRect(x: 0, y: screenHeight/2, width: screenWidth, height: screenHeight/2), containerFrame: CGRect(x: center.x, y: center.y, width: 0, height: 0))
        self.expandedPanel!.layer.mask = maskContent
        self.createBubbleAnimation(self.bubble!.frame,toFrame: self.transitionView.frame, contentMask: maskContent){
            self.bubble?.removeFromSuperview()
            self.bubble = nil
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
            self.transitionView.layer.add(anim1, forKey: "cornerRadius")
            CATransaction.commit()
            UIView.animate(withDuration: 0.1/self.animationSpeed, animations: {
                for constraint in self.transitionView.constraints {
                    if constraint.firstAttribute == .height {
                        constraint.constant = futureHeight
                    }
                    if constraint.firstAttribute == .width {
                        constraint.constant = futureWidth
                    }
                    if constraint.firstAttribute == .bottom {
                        constraint.constant = constraint.constant - 0.02*screenHeight - futureHeight + transitionViewFrame.height
                    }
                }
                for constraint in self.transitionView.superview!.constraints {
                    if let secondItem = constraint.secondItem as? UIView, secondItem == self.transitionView && constraint.firstAttribute == .top {
                        constraint.constant = constraint.constant - 0.02*screenHeight - futureHeight + transitionViewFrame.height
                    }
                }
                self.transitionView.frame = CGRect(x: futureX, y: futureY, width: futureWidth, height: futureHeight)
                self.transitionView.layoutIfNeeded()
            }, completion: { (_) in
            }) 
            if let expandedPanel = self.expandedPanel {
                expandedPanel.removeFromSuperview()
            }
        }
    }
}
