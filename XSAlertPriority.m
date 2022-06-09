//
//  XSAlertPriority.m
//  TextKit
//
//  Created by hanxin on 2022/5/31.
//

#import "XSAlertPriority.h"
#import <sys/time.h>
#import <objc/runtime.h>


//MARK: -   UIView+XSAlertPriority

@interface UIView (XSAlertPriority)
@property (weak, nonatomic) UIView *alertSuperView;
@end

@implementation UIView (XSAlertPriority)

- (UIView *)alertSuperView {
    UIView* (^block)(void) = objc_getAssociatedObject(self, @selector(alertSuperView));
    return block();
}

//  注意：不可用 OBJC_ASSOCIATION_ASSIGN 方式，易造成野指针崩溃
- (void)setAlertSuperView:(UIView *)alertSuperView {
    __weak typeof(alertSuperView) weakAlertSuperView = alertSuperView;
    UIView* (^block)(void) = ^UIView* (void) {
        return weakAlertSuperView;
    };
    objc_setAssociatedObject(self, @selector(alertSuperView), block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


//MARK: -   property

/**
    为采用了XSAlertPriority协议的类添加 alertPriority 的getter、setter
 */
void XSAlertPriority_add_alertPriority(Class cls) {
    //  alertPriority
    SEL getter = sel_registerName("alertPriority");
    SEL key = getter;
    IMP imp = imp_implementationWithBlock(^NSInteger(__kindof UIView<XSAlertPriority> *self) {
        return [objc_getAssociatedObject(self, key) integerValue];
    });
    BOOL success = class_addMethod(cls, getter, imp, "q16@0:8");
    
    //  setAlertPriority:
    SEL setter = sel_registerName("setAlertPriority:");
    imp = imp_implementationWithBlock(^void(__kindof UIView<XSAlertPriority> *self, NSInteger priority) {
        objc_setAssociatedObject(self, key, @(priority), OBJC_ASSOCIATION_ASSIGN);
    });
    success = class_addMethod(cls, setter, imp, "v24@0:8q16");
}

/**
    为采用了XSAlertPriority协议的类添加 removedWhenLowerPriority 的getter、setter
 */
void XSAlertPriority_add_removedWhenLowerPriority(Class cls) {
    //  removedWhenLowerPriority
    SEL getter = sel_registerName("removedWhenLowerPriority");
    SEL key = getter;
    IMP imp = imp_implementationWithBlock(^NSInteger(__kindof UIView<XSAlertPriority> *self) {
        return [objc_getAssociatedObject(self, key) boolValue];
    });
    BOOL success = class_addMethod(cls, getter, imp, "B16@0:8");
    
    //  setRemovedWhenLowerPriority:
    SEL setter = sel_registerName("setRemovedWhenLowerPriority:");
    imp = imp_implementationWithBlock(^void(__kindof UIView<XSAlertPriority> *self, NSInteger priority) {
        objc_setAssociatedObject(self, key, @(priority), OBJC_ASSOCIATION_ASSIGN);
    });
    success = class_addMethod(cls, setter, imp, "v20@0:8B16");
}


//MARK: -   didMoveToSuperview

/**
    缓存弹窗
 */
NSMutableArray<__kindof UIView<XSAlertPriority> *>* XSAlertPriority_array(void) {
    static NSMutableArray *array = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        array = [NSMutableArray new];
    });
    return array;
}

/**
    找到最高优先级的view。如果优先级相同时，则为最后添加的view。
 */
__kindof UIView<XSAlertPriority>* XSAlertPriority_find_highest_priority_view(void) {
    NSArray<__kindof UIView<XSAlertPriority> *>*array = XSAlertPriority_array();
    __kindof UIView<XSAlertPriority> *highestPriorityView = array.lastObject;
    //  倒序遍历
    for (NSInteger i = array.count - 1; i >= 0; i--) {
        __kindof UIView<XSAlertPriority> *view = array[i];
        if (highestPriorityView == view) {
            continue;
        }
        if (highestPriorityView.alertPriority < view.alertPriority) {
            highestPriorityView = view;
        }
    }
    return highestPriorityView;
}

/**
    当自身优先级较低时，根据标记决定是否移除自身
 */
void XSAlertPriority_removed_when_lower_priority(void) {
    NSArray<__kindof UIView<XSAlertPriority> *>*array = XSAlertPriority_array();
    __kindof UIView<XSAlertPriority> *highestPriorityView = XSAlertPriority_find_highest_priority_view();
    //  倒序遍历
    for (NSInteger i = array.count - 1; i >= 0; i--) {
        __kindof UIView<XSAlertPriority> *view = array[i];
        if (highestPriorityView == view) {
            continue;
        }
        
        if (view.alertPriority < highestPriorityView.alertPriority) {
            if (view.removedWhenLowerPriority) {
                [XSAlertPriority_array() removeObject:view];
                [view removeFromSuperview];
            }
        }
    }
}

/**
    显示最高优先级的view
 */
void XSAlertPriority_show_highest_priority_view(void) {
    NSArray<__kindof UIView<XSAlertPriority> *>*array = XSAlertPriority_array();
    __kindof UIView<XSAlertPriority> *highestPriorityView = XSAlertPriority_find_highest_priority_view();
    //  倒序遍历
    for (NSInteger i = array.count - 1; i >= 0; i--) {
        __kindof UIView<XSAlertPriority> *view = array[i];
        if (highestPriorityView == view) {
            continue;
        }
        
        if (view.superview) {
            [view removeFromSuperview];
        }
    }
    [highestPriorityView.alertSuperView addSubview:highestPriorityView];
}

/**
    为采用了XSAlertPriority协议的类重写 didMoveToSuperview
 
 @code
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.alertPriority = self.slider1.value;
    hud.removedWhenLowerPriority = self.switch1.on;
 @endcode
 
 执行 [MBProgressHUD showHUDAddedTo:self.view animated:YES] 就立即触发 didMoveToSuperview，然后才执行 hud.alertPriority = self.slider1.value;
 因此在 didMoveToSuperview 需要异步执行，等待上面的属性都设置完成才执行异步操作
 */
void XSAlertPriority_override_didMoveToSuperview(UIView<XSAlertPriority> *self) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.superview) {   //  addSubview
            self.alertSuperView = self.superview;
            [XSAlertPriority_array() addObject:self];
            XSAlertPriority_removed_when_lower_priority();
        } else {                //  removeFromSuperview
            //  当前正在显示的一定是最高优先级的（优先级相同时，则为后面添加的）
            __kindof UIView<XSAlertPriority> *highestPriorityView = XSAlertPriority_find_highest_priority_view();
            if (highestPriorityView == self) {
                [XSAlertPriority_array() removeObject:self];
            }
        }
        XSAlertPriority_show_highest_priority_view();
    });
}

/**
    为采用了XSAlertPriority协议的类重写 didMoveToSuperview
 
    @note  如果这个类没有实现didMoveToSuperview，那么会找到UIView.didMoveToSuperview，如果改写UIView.didMoveToSuperview，则会影响所有的View。因此需先增加，如果增加失败，说明已经实现了didMoveToSuperview，这时候只需要插入代码即可
 */
void XSAlertPriority_add_didMoveToSuperview(Class cls) {
    SEL sel = @selector(didMoveToSuperview);
    Method m = class_getInstanceMethod(cls, sel);
    IMP imp1 = imp_implementationWithBlock(^void(__kindof UIView<XSAlertPriority> *self) {
        XSAlertPriority_override_didMoveToSuperview(self);
    });
    BOOL success = class_addMethod(cls, sel, imp1, "v16@0:8");
    
    if (!success) {
        IMP imp0 = method_getImplementation(m);
        imp1 = imp_implementationWithBlock(^void(__kindof UIView<XSAlertPriority> *self) {
            ((void (*)(UIView<XSAlertPriority> *, SEL))imp0)(self, sel);
            XSAlertPriority_override_didMoveToSuperview(self);
        });
        method_setImplementation(m, imp1);
    }
}


//MARK: -   main

/**
    扫描采用了XSAlertPriority协议的类
 */
__attribute__((constructor))
void XSAlertPriority_main(void) {
    struct timeval t1;
    gettimeofday(&t1, NULL);
    
    Protocol *proto = objc_getProtocol("XSAlertPriority");
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (int i = 0; i < count; i++) {
        Class cls = classes[i];
        if (class_conformsToProtocol(cls, proto)) {
            XSAlertPriority_add_alertPriority(cls);
            XSAlertPriority_add_removedWhenLowerPriority(cls);
            XSAlertPriority_add_didMoveToSuperview(cls);
        }
    }
    free(classes);
    
    struct timeval t2;
    gettimeofday(&t2, NULL);
    long sec = t2.tv_sec - t1.tv_sec;
    long usec = t2.tv_usec - t1.tv_usec;
    double cost =  sec + usec * 1e-6;
    printf(">>> XSAlertPriority time cost: %f\n",  cost);
}
