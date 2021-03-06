//
//  PhysicalView.swift
//  核心动画练习
//
//  Created by yuency on 14/12/2017.
//  Copyright © 2017 sunny. All rights reserved.
//

import UIKit
import CoreMotion

/// 物理效果 View
class PhysicalView: UIView {
    
    /// 外部使用的属性
    var imageNameArray: Array<String> = Array() {
        didSet{
            creatImageViewArrayWithDataArray(dataArray: imageNameArray)
        }
    }
    
    /// 物理仿真器
    private lazy var dynamicAnimator: UIDynamicAnimator = {
        return UIDynamicAnimator(referenceView: self)
    }()
    
    /// 重力行为
    private lazy var gravity: UIGravityBehavior = {
        return UIGravityBehavior()
    }()
    
    /// 碰撞行为
    private lazy var collision: UICollisionBehavior = {
        
        let coll = UICollisionBehavior()
        // 以参照视图作为碰撞行为的边界
        coll.translatesReferenceBoundsIntoBoundary = true
        
        return coll
    }()
    
    
    /// 元素自身参数行为
    private lazy var dynamicItem: UIDynamicItemBehavior = {
        
        let dyitem = UIDynamicItemBehavior()
        //设置视图的辅助行为(本身参数 弹性系数 阻力等)
        // Usually between 0 (inelastic) and 1 (collide elastically)  弹性系数
        dyitem.elasticity = 0.6;
        // 0 being no friction between objects slide along each other  摩擦力
        dyitem.friction = 0.1;
        // 1 by default                                                密度
        dyitem.density = 1;
        // 0: no velocity damping                                      阻力
        dyitem.resistance = 0;
        // : no angular velocity damping                               速度阻尼
        dyitem.angularResistance = 0.2;
        // force an item to never rotate                               是否允许旋转
        dyitem.allowsRotation = true;
        
        return dyitem
    }()
    
    
    
    /// 陀螺仪等 使用陀螺仪获得设备的 XYZ 加速度
    private lazy var motionManager: CMMotionManager = {
        let moti = CMMotionManager()
        moti.deviceMotionUpdateInterval = 1 / 60
        return moti
    }()
    
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        
        motionManager.stopDeviceMotionUpdates()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func creatImageViewArrayWithDataArray(dataArray: Array<String>) {
        
        // 也可以自定义碰撞行为的边界
        /*
         CGPoint point1 = CGPointMake(0, 0);
         CGPoint point2 = CGPointMake(self.bounds.size.width, 0);
         CGPoint point3 = CGPointMake(self.bounds.size.width,self.bounds.size.height);
         CGPoint point4 = CGPointMake(0,self.bounds.size.height);
         [self.collision addBoundaryWithIdentifier:@"line1" fromPoint:point1 toPoint:point2];
         [self.collision addBoundaryWithIdentifier:@"line2" fromPoint:point2 toPoint:point3];
         [self.collision addBoundaryWithIdentifier:@"line3" fromPoint:point3 toPoint:point4];
         [self.collision addBoundaryWithIdentifier:@"line4" fromPoint:point4 toPoint:point1];
         */
        
        
        for (i, string) in dataArray.enumerated() {
            
            let imageView: UIImageView
            
            
            if i % 2 == 0 {
                imageView = RoundImageView(image: UIImage(named: string))
                
                imageView.layer.masksToBounds = true
                imageView.layer.cornerRadius = 30
                
            } else {
                imageView = RectangleImageView(image: UIImage(named: string))
            }
            
            imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            imageView.backgroundColor = UIColor.black
            imageView.center = center
            addSubview(imageView)
            
            ///把图片添加到 重力行为 碰撞行为
            gravity.addItem(imageView)
            collision.addItem(imageView)
            dynamicItem.addItem(imageView)
        }
        
        
        // 在设定完重力方向之后，需要将重力行为、碰撞行为添加到物理仿真器中
        self.dynamicAnimator.addBehavior(self.gravity)
        self.dynamicAnimator.addBehavior(self.collision)
        self.dynamicAnimator.addBehavior(self.dynamicItem)
        
        getDataDeviceMotion()
    }
    
    
    
    private func getDataDeviceMotion() {
        
        if motionManager.isDeviceMotionAvailable {
            
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (motion, error) in
                
                if error == nil  {
                    
                    // Z 轴的及速度就是重力加速度
                    guard  let X = motion?.gravity.x, let Y = motion?.gravity.y, let Z = motion?.gravity.z else {
                        return
                    }
                    
                    print("陀螺仪: X:\(X)  Y:\(Y)  Z:\(Z)")
                    
                    // 从陀螺仪获得 XYZ 三个方向的加速度, 然后不断去改变这个重力行为的加速度 这样就可以是 Item 随着手机的晃动而不断移动
                    // CGVector(dx: 0, dy: 1) 表示加速度竖直向下, CGVector(dx: 1, dy: 1) 表示加速度从左上角到右下角 45°
                    self.gravity.gravityDirection = CGVector(dx: 2 * X, dy: -2 * Y)
                    
                }else{
                    self.motionManager.stopDeviceMotionUpdates()
                }
            })
        }
    }
}





/// 圆形的的图片
fileprivate class RoundImageView: UIImageView {
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .ellipse
    }
}

/// 矩形图片
fileprivate class RectangleImageView: UIImageView {
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .rectangle
    }
}



/// 对于不规则的图形, 不知道怎么写
fileprivate class PathImageView: UIImageView {
    
    override var collisionBoundsType: UIDynamicItemCollisionBoundsType {
        return .path
    }
    
    override var collisionBoundingPath: UIBezierPath {
        
        let X = bounds.size.width
        let Y = bounds.size.height
        
        let linePath = UIBezierPath()
        
        linePath.move(to: CGPoint(x: X / 2, y: 0))
        linePath.addLine(to: CGPoint(x: X , y: Y / 2))
        linePath.addLine(to: CGPoint(x: X / 2, y: Y))
        linePath.addLine(to: CGPoint(x: 0, y: Y / 2))
        
        linePath.close();
        
        let lineLayer = CAShapeLayer()
        
        lineLayer.lineWidth = 2.0;
        lineLayer.strokeColor = UIColor.red.cgColor
        lineLayer.path = linePath.cgPath;
        lineLayer.fillColor  = UIColor.yellow.cgColor;
        
        self.layer.addSublayer(lineLayer)
        
        
        return linePath
    }
    
}



