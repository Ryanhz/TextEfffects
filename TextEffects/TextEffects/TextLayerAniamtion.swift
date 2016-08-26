//
//  TextLayerAniamtion.swift
//  TextEffects
//
//  Created by hzf on 16/8/26.
//  Copyright © 2016年 hzf. All rights reserved.
//

import UIKit

typealias completionClosure = (finish: Bool) ->()

private let textAnimationGroupKey = "textAniamtionGroupKey"

class TextLayerAnimation: NSObject {
    
    var completionBlock: completionClosure?
    var textLayer: CALayer?
    
    class func textLayerAnimation(layer: CALayer, durationTime duration: NSTimeInterval, delayTime delay: NSTimeInterval, aniamtionClosure effectAnimation: effectAnimatatableLayerClosure?, completion finishedClosure: completionClosure?) ->Void{
        
        let animationObjc = TextLayerAnimation()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            
            let olderLayer = animationObjc.animatableLayerCopy(layer)
            var newLayer: CALayer?
            var animationGroup: CAAnimationGroup?
            animationObjc.completionBlock = finishedClosure
            if let effectAnimationClosure = effectAnimation {
                //改变Layer的properties，同时关闭implicit animation

                CATransaction.begin()
                CATransaction.setDisableActions(true)
                newLayer = effectAnimationClosure(layer: layer)
                CATransaction.commit()
            }
            
            animationGroup = animationObjc.groupAnimationWithLayerChanges(old: olderLayer, new: newLayer!)
            if let textAnimationGroup = animationGroup {
                
                animationObjc.textLayer = layer
                textAnimationGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                textAnimationGroup.beginTime = CACurrentMediaTime()
                textAnimationGroup.duration = duration
                textAnimationGroup.delegate = animationObjc
                layer.addAnimation(textAnimationGroup, forKey: textAnimationGroupKey)
            } else {
                if let completion = finishedClosure {
                    completion(finish: true)
                }
            }
            
        }
        
    }
    
    func groupAnimationWithLayerChanges(old olderLayer: CALayer, new newLayer: CALayer) -> CAAnimationGroup? {
        
        var animationGroup: CAAnimationGroup?
        var animations: [CABasicAnimation] = [CABasicAnimation]()
        
        if !CGPointEqualToPoint(olderLayer.position, newLayer.position) {
            let basicAnimation = CABasicAnimation()
            basicAnimation.fromValue = NSValue(CGPoint: olderLayer.position)
            basicAnimation.toValue = NSValue(CGPoint: newLayer.position)
            basicAnimation.keyPath = "position"
            animations.append(basicAnimation)
        }
        
        if !CATransform3DEqualToTransform(olderLayer.transform, newLayer.transform) {
            let basicAnimation = CABasicAnimation(keyPath: "transform")
            basicAnimation.fromValue = NSValue(CATransform3D: olderLayer.transform)
            basicAnimation.toValue = NSValue(CATransform3D: newLayer.transform)
            animations.append(basicAnimation)
        }
        
        if !CGRectEqualToRect(olderLayer.frame, newLayer.frame) {
            let basicAnimation = CABasicAnimation(keyPath: "frame")
            basicAnimation.fromValue = NSValue(CGRect: olderLayer.frame)
            basicAnimation.toValue = NSValue(CGRect: newLayer.frame)
            animations.append(basicAnimation)
        }
        
        if !CGRectEqualToRect(olderLayer.bounds, newLayer.bounds) {
            let basicAnimation = CABasicAnimation(keyPath: "bounds")
            basicAnimation.fromValue = NSValue(CGRect: olderLayer.bounds)
            basicAnimation.toValue = NSValue(CGRect: newLayer.bounds)
            animations.append(basicAnimation)
        }
        
        if olderLayer.opacity != newLayer.opacity {
            
            let basicAnimation = CABasicAnimation(keyPath: "opacity")
            basicAnimation.fromValue = olderLayer.opacity
            basicAnimation.toValue = newLayer.opacity
            animations.append(basicAnimation)
        }
        
        if animations.count > 0 {
            animationGroup = CAAnimationGroup()
            animationGroup!.animations = animations
        }
        
        return animationGroup
    }
    
    func animatableLayerCopy(layer: CALayer) ->CALayer {
        
        let layerCopy = CALayer()
        layerCopy.opacity = layer.opacity
        layerCopy.bounds = layer.bounds
        layerCopy.transform = layer.transform
        layerCopy.position = layer.position  
        return layerCopy
    }
    
    //MARK: animationDelegate 
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if let temCompletionBlock = self.completionBlock{
            self.textLayer?.removeAnimationForKey(textAnimationGroupKey)
            temCompletionBlock(finish: flag)
        }
        
    }
}
