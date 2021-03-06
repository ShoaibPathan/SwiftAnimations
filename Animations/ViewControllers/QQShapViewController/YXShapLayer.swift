//
//  YXShapLayer.swift
//  Animations
//
//  用手中的流沙画一个你呀
//  曾经说过的永远我们一定不会擦
//  我的青春开始在喧哗
//  因为大声说爱你而沙哑

//  用手中流沙轻描着你的脸颊
//  也答应说好的未来决不会重画
//
//  Created by yuency on 07/12/2017.
//  Copyright © 2017 sunny. All rights reserved.
//

import UIKit
import QuartzCore

/*
 http://www.cnblogs.com/chengguanhui/p/4664144.html 缓动函数
 https://github.com/Xieyupeng520/AZEmitter //原作者 GitHub
 http://www.jianshu.com/p/2d6014b226d6     //原作者 简书教程
 */

/// 画沙
class YXShapLayer: CALayer {
    
    /// layer 自身的宽度
    lazy var selfW: CGFloat = {
        return frame.size.width
    }()
    
    /// layer 自身的高度
    lazy var selfH: CGFloat = {
        return frame.size.height
    }()
    
    /// 装有所有像素的数组模型
    var pixArray: Array<YXPixModel> = Array()
    
    /// 定时器
    private var displayLink: CADisplayLink?
    /// 动画时间
    private var animTime: CGFloat = 0
    
    /// 粒子出生位置，默认在左边顶上
    var beginPoint: CGPoint = CGPoint(x: 0, y: 0)
    
    //忽略黑色，白色当做透明处理，默认为NO，必须在设置image前面设置
    var ignoredBlack: Bool = false
    
    //忽略白色，白色当做透明处理，默认为NO，必须在设置image前面设置
    var ignoredWhite: Bool = false
    
    
    /// 把图片给我
    var image: UIImage? {
        
        didSet{
            guard let image = image, let W = image.cgImage?.width, let H = image.cgImage?.height else {
                assertionFailure("图片不对")
                return
            }
            
            print(" 图片大小 \(W) * \(H)")
            
            //把图片移动到 layer 中间需要的操作, 为了让每一个像素都固定在屏幕的像素点上, (防止因为 CGFloat 类型产生图片模糊) 做的宽高取整计算
            var XWidth = (selfW - CGFloat(W)) / 2
            XWidth = (XWidth / 2 == 0.0) ? XWidth : XWidth - 1
            let XW = Int(XWidth)
            
            var YHeight = (selfH - CGFloat(H)) / 2
            YHeight = (YHeight / 2 == 0.0) ? YHeight : YHeight - 1
            let YH = Int(YHeight)
            
            var array: Array<YXPixModel> = Array()  //存储粒子模型
            
            let pixelData = image.cgImage?.dataProvider?.data
            
            let data:UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            
            for gao in 0..<H {
                
                for kuan in 0..<W {
                    
                    let pixelInfo: Int = (W * kuan + gao) * 4
                    
                    let R = CGFloat(data[pixelInfo]) / CGFloat(255.0)
                    let G = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
                    let B = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
                    let A = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
                    
                    if A == 0 || (ignoredWhite && R + G + B == 3) || (ignoredBlack && R + G + B == 0) {
                        continue  //忽略不需要的粒子  黑 白 透明
                    }
                    
                    let model = YXPixModel()
                    model.pointX = CGFloat(XW + gao)
                    model.pointY = CGFloat(YH + kuan)
                    model.cgColor = UIColor(red: R, green: G, blue: B, alpha: A).cgColor;
                    array.append(model)
                }
            }
            pixArray = array
            array.removeAll()
        }
    }
    
    override init() {
        super.init()
        masksToBounds = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 定时器方法
    @objc func emitterAnim(displayLink: CADisplayLink) {
        setNeedsDisplay() //激活画图
        
        animTime += 0.1 //用于控制粒子的下放速度
    }
    
    
    /// 粒子计数
    private var count: Int = 0
    
    /// 执行次数计数
    private var runTimes: Int = 0
    
    /// 重写的 draw in context 方法
    override func draw(in ctx: CGContext) {
        
        
        //这段函数的执行时间不能大于 16.7毫秒, 否则会丢帧
        let startTime = CFAbsoluteTimeGetCurrent();
        
        for model in pixArray {
            
            if model.delayTime >= animTime { //每个像素都有它的延时时间,是随机出生的, 如果这个时间比动画到达的时间大, 就先不要让这个像素出来
                continue
            }
            
            if model.isEnd { //对于已经到达目的地的粒子, 就不需要计算了
                ctx.setFillColor(model.cgColor)
                ctx.fill(CGRect(x: model.pointX, y: model.pointY, width: 1, height: 1))
                continue;
            }
            
            if (animTime > model.allTime) {  //如果当前计时的时间已经超出动画粒子的 (延迟时间 + 持续时间)那么就标记这个粒子已经到达了目的地
                count += 1;
                model.isEnd = true
            }

            //代码到达这里,表示,animTime 已经大于 model.delayTime, 这个时候粒子应该入场, 算出这个粒子入场的时间
            let currentTime = animTime - model.delayTime
            
            // 计算粒子路径
            let curX = easeInOutQuad(time: currentTime, beginPosition: beginPoint.x, endPosition: model.pointX, duration: model.durationTime)
            let curY = easeInOutQuad(time: currentTime, beginPosition: beginPoint.y, endPosition: model.pointY, duration: model.durationTime)
            
            // 画粒子
            ctx.setFillColor(model.cgColor)
            ctx.fill(CGRect(x: curX, y: curY, width: 1, height: 1))
        }
        
        runTimes += 1
        print("执行次数: \(runTimes)")
        let linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
        print("一次执行时间: \(linkTime * 1000.0) 毫秒")  //这个时间稳定在 70 毫秒内动画还是流畅的
        
        if (count == pixArray.count) { // 画完了重置
            reset()
        }
    }
    
    
    /// 缓动函数计算公式
    func easeInOutQuad(time: CGFloat, beginPosition: CGFloat, endPosition: CGFloat, duration: CGFloat) -> CGFloat {
        let coverDistance = endPosition - beginPosition
        var time = time
        time /= duration / 2
        if (time < 1) {
            return coverDistance / 2 * pow(time, 2) + beginPosition;
        }
        time -= 1
        return -coverDistance / 2 * (time*(time-2)-1) + beginPosition
    }
    
    /// 创建定时器
    private func createDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(emitterAnim(displayLink:)))
        displayLink?.add(to: RunLoop.current, forMode: RunLoop.Mode.common)
    }
    
    /// 重置定时器
    private func reset() {
        
        for model in pixArray {
            model.isEnd = false
        }
        
        if displayLink != nil {
            displayLink?.invalidate()
            displayLink = nil
            animTime = 0
            count = 0
            runTimes = 0
        }
    }
    
    /// 开始动画
    func showAnimation() {
        reset()  //重置
        createDisplayLink() //绘画
    }
}

