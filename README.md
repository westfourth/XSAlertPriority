# XSAlertPriority

处理弹窗优先级：当有多个弹窗时，只显示优先级最高的弹窗（有多个同样的最高优先级时，显示最后面添加的）。

## 接口

``` objc
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
```

## 使用

让弹窗类采用这个协议即可

```objc
@interface MBProgressHUD (Priority) <XSAlertPriority>
@end

@implementation MBProgressHUD (Priority)
@end
```

为弹窗设置优先级即可

``` objc
MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
hud.alertPriority = 100;
```

## 原理

1. 程序启动的时候，扫描采用此协议的类，并为这些类添加协议对应的getter、setter方法；
2. 程序向`didMoveToSuperview`插入代码，较低优先级的view都会从视图层级中移除（`removedWhenLowerPriority = NO`时会被缓存），只显示最高优先级的

## 技术难点一

使用`method_setImplementation`直接改写`didMoveToSuperview`时，这时候所有的view都会触发`didMoveToSuperview`。因为`class_getInstanceMethod`会递归搜索父类，而`class_copyMethodList`不会。因此需要先添加`didMoveToSuperview`方法，如果添加失败，表明自身有`didMoveToSuperview`方法，这时候只需要插入代码即可。

## 技术难点二

``` objc
1. MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
2. hud.alertPriority = 100;
3. hud.removedWhenLowerPriority = NO;
```

当执行上面第1个语句时，就触发`didMoveToSuperview`，导致在`didMoveToSuperview`中取不到第2、3个语句设置的`alertPriority`和`removedWhenLowerPriority`值。这时候采用`dispatch_async`异步执行，当第2、3个语句执行完后才执行`didMoveToSuperview`里面的`dispatch_async`，这时候就能取到值了。


