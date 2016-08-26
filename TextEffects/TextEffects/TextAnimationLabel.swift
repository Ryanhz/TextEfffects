//
//  TextAnimationLabel.swift
//  TextEffects
//
//  Created by hzf on 16/8/25.
//  Copyright © 2016年 hzf. All rights reserved.
//

import UIKit

typealias textAnimationClosure = ()->()

typealias effectAnimatatableLayerClosure = (layer: CALayer)->CALayer

typealias effectTextAnimationClosure = (layer: CALayer, duration:NSTimeInterval, delay: NSTimeInterval, isFinished:Bool)

class TextAnimationLabel: UILabel, NSLayoutManagerDelegate {

    var oldCharacterTextLayers: [CATextLayer] = [];
    var newCharacterTextLayers: [CATextLayer] = [];
    
    let textStorage: NSTextStorage = NSTextStorage(string: "")
    let textLayoutManager: NSLayoutManager  = NSLayoutManager()
    let textContainer: NSTextContainer = NSTextContainer()
    
    var animationOut: textAnimationClosure?
    var animationIn: textAnimationClosure?
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        textkitObjectSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        textkitObjectSetup()
        fatalError("init(coder:) has not been implemented")
    }
    
    func textkitObjectSetup() {
        textStorage.addLayoutManager(textLayoutManager)
        textLayoutManager.addTextContainer(textContainer)
        textLayoutManager.delegate = self;
        textContainer.size = bounds.size;
        textContainer.maximumNumberOfLines = numberOfLines;
        textContainer.lineBreakMode = lineBreakMode;
    }
    
    override var lineBreakMode: NSLineBreakMode {
        get {
            return super.lineBreakMode
        }
        
        set {
            textContainer.lineBreakMode = newValue
            super.lineBreakMode = newValue
        }
        
    }
    
    override var numberOfLines: Int {
        get {
            return super.numberOfLines
        }
        
        set {
            textContainer.maximumNumberOfLines = newValue
            super.numberOfLines = newValue
        }
    }
    
    override var bounds: CGRect {
        get {
            return super.bounds
        }
        
        set {
            textContainer.size = newValue.size
            super.bounds = newValue
        }
        
    }
    
    override var textColor: UIColor! {
        get {
            return super.textColor
        }
        
        set {
            super.textColor = newValue
            let text = self.textStorage.string
            self.text = text
        }
    }
    
    override var text: String! {
        get {
            return super.text
        }

        set {
            super.text = text
            
            let attributedText = NSMutableAttributedString(string: newValue)
            let textRange = NSMakeRange(0, newValue.characters.count)
            attributedText.setAttributes([NSForegroundColorAttributeName : self.textColor], range: textRange)
            attributedText.setAttributes([NSFontAttributeName : self.font], range: textRange)

            let paragraphyStyle = NSMutableParagraphStyle()
            paragraphyStyle.alignment = self.textAlignment
            attributedText.addAttributes([NSParagraphStyleAttributeName : paragraphyStyle], range: textRange)
        
            self.attributedText = attributedText
        }
    }
    
    override var attributedText: NSAttributedString! {
        get {
            return self.textStorage
        }
        
        set {
            clearOutOldCharacterTextLayers()
            oldCharacterTextLayers = Array(newCharacterTextLayers)
            textStorage.setAttributedString(newValue)
            
            self.startAnimation {()->() in
                
            }
            
            self.endAnimation(nil)
        }
    }
    
    //MARK:--NSLayoutManagerDelegate
    func layoutManager(layoutManager: NSLayoutManager, didCompleteLayoutForTextContainer textContainer: NSTextContainer?, atEnd layoutFinishedFlag: Bool) {
        
        calculateTextLayers()
//        print("\(textStorage.string)")
    }
    
    func calculateTextLayers() {
        
        newCharacterTextLayers.removeAll(keepCapacity: false)
        let attributedText = textStorage.string
        let wordRange = NSMakeRange(0, attributedText.characters.count)
        let attributedString = self.internalAttributedText()
        let layoutRect = textLayoutManager.usedRectForTextContainer(textContainer)
        var index = wordRange.location
        print("\(wordRange)")
        let totalLength = NSMaxRange(wordRange)
        print("\(totalLength)")
        while index < totalLength {
            
            let glyphRange = NSMakeRange(index, 1)
            let characterRange = textLayoutManager.characterRangeForGlyphRange(glyphRange, actualGlyphRange: nil)
            let textContainer = textLayoutManager.textContainerForGlyphAtIndex(index, effectiveRange: nil)
            var glyphRect = textLayoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer!)
            
            let kerningRange = textLayoutManager.rangeOfNominallySpacedGlyphsContainingIndex(index)
            if kerningRange.location == index && kerningRange.length > 1 {
                if newCharacterTextLayers.count > 0 {
                    // 如果前一个textlayer的frame.size.width不变大的话，当前的textLayer会遮挡住字体的一部分，比如“You”的Y右上角会被切掉一部分
                    let previousLayer = newCharacterTextLayers[newCharacterTextLayers.endIndex - 1]
                    var frame = previousLayer.frame
                    frame.size.width += CGRectGetMaxX(glyphRect) - CGRectGetMaxX(frame)
                    previousLayer.frame = frame
                    
                }
            }
            
            //中间垂直
            glyphRect.origin.y += (self.bounds.size.height/2)-(layoutRect.size.height/2)
            
            let textLayer = CATextLayer(frame: glyphRect, string: attributedString.attributedSubstringFromRange(characterRange))
            self.initialTextLayerAttributes(textLayer)
            
            layer.addSublayer(textLayer)
            newCharacterTextLayers.append(textLayer)
            index += characterRange.length
        }
    }
    
    
    func internalAttributedText() -> NSMutableAttributedString! {
       
        let wordRange = NSMakeRange(0, textStorage.string.characters.count)
        let attributedText = NSMutableAttributedString(string: textStorage.string)
        attributedText.addAttribute(NSForegroundColorAttributeName, value: self.textColor.CGColor, range: wordRange)
        attributedText.addAttribute(NSFontAttributeName, value: self.font, range: wordRange)
        
        let paragraphyStyle = NSMutableParagraphStyle()
        paragraphyStyle.alignment = self.textAlignment
        attributedText.addAttribute(NSParagraphStyleAttributeName, value: paragraphyStyle, range: wordRange)
        return attributedText
        
    }
    
    func clearOutOldCharacterTextLayers (){
        for textLayer in oldCharacterTextLayers {
            textLayer.removeFromSuperlayer()
        }
        oldCharacterTextLayers.removeAll(keepCapacity: false)
    }
    
    func initialTextLayerAttributes(textLayer: CATextLayer) {
        textLayer.opacity = 0.0
    }
    
    func startAnimation(animationClosure: textAnimationClosure?) {
        
        var longestAnimationDuration = 0.0
        var longestAnimationIndex = -1
        var index = 0
        
        for textLayer in oldCharacterTextLayers {
            
            let duration = (NSTimeInterval(arc4random()%100)/125.0) + 0.35
            
            let delay = NSTimeInterval(arc4random_uniform(100)/500)
            let distance = CGFloat(arc4random()%50) + 25
            let angle = CGFloat((Double(arc4random())/M_PI_2) - M_PI_4)
            
            var transform = CATransform3DMakeTranslation(0, distance, 0)
            transform = CATransform3DRotate(transform, angle, 0, 0, 1)
            
            if delay + duration > longestAnimationDuration {
                longestAnimationDuration = delay + duration
                longestAnimationIndex = index
            }
            
            TextLayerAnimation.textLayerAnimation(textLayer, durationTime: duration, delayTime: delay, aniamtionClosure: { (layer) -> CALayer in
                
                layer.transform = transform
                layer.opacity = 0.0
                return layer
                
                }, completion: { [weak self](finish) -> () in
                
                    textLayer.removeFromSuperlayer()
                    if let textLayers = self?.oldCharacterTextLayers {
                        
                        if textLayers.count > longestAnimationIndex && textLayer == textLayers[longestAnimationIndex] {
                            if let animationOut = animationClosure {
                                animationOut()
                            }
                        }
                    }
            })
            ++index
            
        }
        
    }
    
    func endAnimation(animationClosure: textAnimationClosure?) {
        
        for textLayer in newCharacterTextLayers {
            let duration = NSTimeInterval(arc4random()%200 / 100) + 0.25
            let delay = 0.06
            TextLayerAnimation.textLayerAnimation(textLayer, durationTime: duration, delayTime: delay, aniamtionClosure: { (layer) -> CALayer in
                
                layer.opacity = 1.0
                return layer
                
                }, completion: { (finish) -> () in
                
                    if let animationIn = animationClosure {
                        animationIn()
                    }
            })
        }
    }
    
}


extension CATextLayer {
    convenience init(frame: CGRect, string: NSAttributedString) {
        self.init()
        self.contentsScale = UIScreen.mainScreen().scale
        self.frame = frame
        self.string = string
    }
}






