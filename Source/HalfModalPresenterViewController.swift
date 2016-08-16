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
    
    private var bubble:UIView?
    private var expandedPanel:UIView?
    private var gesture:UITapGestureRecognizer?
    private var dismissHitBox:UIView?
    
    public init(transitionView: UIView, containerViewController: UIViewController){
        self.transitionView = transitionView
        self.containerViewController = containerViewController
    }
    
    public func presentHalfScreenView(expandedPanel: UIView){
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
        expandedPanel.frame = CGRectMake(0, screenHeight/2, screenWidth, screenHeight/2)
        let originalCenter = expandedPanel.center
        
        
        
        bubble = UIView()
        if let bubble = bubble {
            bubble.frame = CGRectMake(expandedPanel.frame.origin.x, expandedPanel.frame.origin.y, expandedPanel.frame.size.width+expandedPanel.frame.size.height, expandedPanel.frame.size.height)
            bubble.layer.cornerRadius = bubble.frame.size.height / 2
            bubble.center = center
            bubble.transform = CGAffineTransformMakeScale(0.001, 0.001)
            bubble.backgroundColor = transitionView.backgroundColor
            bubble.clipsToBounds = true
            self.containerViewController.view.insertSubview(self.bubble!, belowSubview: expandedPanel)
        }
        
        expandedPanel.center = center
        expandedPanel.transform = CGAffineTransformMakeScale(0.001, 0.001)
        expandedPanel.alpha = 0
        containerViewController.view.addSubview(expandedPanel)
        
        UIView.animateWithDuration(0.5, animations: {
            self.bubble!.transform = CGAffineTransformIdentity
            self.bubble!.frame = CGRectMake(-screenHeight/4, screenHeight/2, screenWidth+screenHeight/2, screenHeight/2)
            if let expandedPanel = self.expandedPanel {
                expandedPanel.transform = CGAffineTransformIdentity
                expandedPanel.alpha = 1
                expandedPanel.center = originalCenter
            }
        }) { (_) in
        }
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
        if let expandedPanel = expandedPanel {
            let originalCenter = expandedPanel.center
            
            let center = transitionView.superview!.convertPoint(transitionView.center, toView: nil)
            
            UIView.animateWithDuration(0.5, animations: {
                self.bubble!.transform = CGAffineTransformMakeScale(0.001, 0.001)
                self.bubble!.center = center
                expandedPanel.transform = CGAffineTransformMakeScale(0.001, 0.001)
                expandedPanel.center = center
                expandedPanel.alpha = 0
                
                self.containerViewController.view.insertSubview(expandedPanel, belowSubview: expandedPanel)
                self.containerViewController.view.insertSubview(self.bubble!, belowSubview: expandedPanel)
            }) { (_) in
                expandedPanel.center = originalCenter;
                expandedPanel.removeFromSuperview()
                self.bubble!.removeFromSuperview()
                self.bubble = nil
            }
        }
    }
}