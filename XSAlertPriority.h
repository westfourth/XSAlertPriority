//
//  XSAlertPriority.h
//  TextKit
//
//  Created by hanxin on 2022/5/31.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
    优先级弹窗；仅用于UIView及其子类。
 
    @note   可以不用实现此协议，采用此协议，即会自动添加getter、setter方法。
 
    原理：
    1. 程序启动的时候，扫描采用此协议的类，并为这些类添加协议对应的getter、setter方法；
    2. 程序向didMoveToSuperview插入代码，较低优先级的view都会被隐藏，只显示最高优先级的
    
    @warning    addSubview:与下面的两个属性得在同一个runloop中（只有一个线程的情况下，同一个方法中必定为同一个runloop）。
 */
@protocol XSAlertPriority <NSObject>

/**
    数值越大，优先级越高；同样的优先级，最后面添加的优先显示
 */
@property (nonatomic) NSInteger alertPriority;

/**
    当自身优先级较低时，是否移除。
 
    @note   优先级相同时是不会移除的
 */
@property (nonatomic) BOOL removedWhenLowerPriority;

@end


NS_ASSUME_NONNULL_END
