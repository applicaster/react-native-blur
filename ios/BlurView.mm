#import "BlurView.h"

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <react/renderer/components/rnblurview/ComponentDescriptors.h>
#import <react/renderer/components/rnblurview/Props.h>
#import <react/renderer/components/rnblurview/RCTComponentViewHelpers.h>
#endif // RCT_NEW_ARCH_ENABLED

#ifdef RCT_NEW_ARCH_ENABLED
using namespace facebook::react;

@interface BlurView () <RCTBlurViewViewProtocol>
#else
@interface BlurView ()
#endif // RCT_NEW_ARCH_ENABLED

@property (nonatomic, strong) UIViewPropertyAnimator *animator;

@end

@implementation BlurView


- (instancetype)init
{
  if (self = [super init]) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(reduceTransparencyStatusDidChange:)
                                          name:UIAccessibilityReduceTransparencyStatusDidChangeNotification
                                          object:nil];
  }

  return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
#ifdef RCT_NEW_ARCH_ENABLED
    static const auto defaultProps = std::make_shared<const BlurViewProps>();
    _props = defaultProps;
#endif // RCT_NEW_ARCH_ENABLED

    self.blurEffectView = [[UIVisualEffectView alloc] init];
    self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.blurEffectView.frame = frame;
    self.blurEffectView.translatesAutoresizingMaskIntoConstraints = YES;
    self.reducedTransparencyFallbackView = [[UIView alloc] init];
    self.reducedTransparencyFallbackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.reducedTransparencyFallbackView.frame = frame;

    self.blurAmount = @10;
    self.blurType = @"dark";
    [self updateFallbackView];
  
    self.clipsToBounds = true;
  
    [self addSubview:self.blurEffectView];
    

  }

  return self;
}

#ifdef RCT_NEW_ARCH_ENABLED
#pragma mark - RCTComponentViewProtocol

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<BlurViewComponentDescriptor>();
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<const BlurViewProps>(_props);
  const auto &newViewProps = *std::static_pointer_cast<const BlurViewProps>(props);
  
  if (oldViewProps.blurAmount != newViewProps.blurAmount) {
    NSNumber *blurAmount = [NSNumber numberWithInt:newViewProps.blurAmount];
    [self setBlurAmount:blurAmount];
  }

  if (oldViewProps.blurType != newViewProps.blurType) {
    NSString *blurType = [NSString stringWithUTF8String:toString(newViewProps.blurType).c_str()];
    [self setBlurType:blurType];
  }
  
  if (oldViewProps.reducedTransparencyFallbackColor != newViewProps.reducedTransparencyFallbackColor) {
    UIColor *color = RCTUIColorFromSharedColor(newViewProps.reducedTransparencyFallbackColor);
    [self setReducedTransparencyFallbackColor:color];
  }
  
  [super updateProps:props oldProps:oldProps];
}
#endif // RCT_NEW_ARCH_ENABLED


- (void)invalidateAnimator {
  if (self.animator.state == UIViewAnimatingStateActive ||
      self.animator.state == UIViewAnimatingStateInactive) {
      [self.animator stopAnimation:YES];
  }
  
  if (self.animator.state == UIViewAnimatingStateStopped) {
    [self.animator finishAnimationAtPosition:UIViewAnimatingPositionCurrent];
    self.animator = nil;
  }
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self invalidateAnimator];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  self.blurEffectView.frame = self.bounds;
  self.reducedTransparencyFallbackView.frame = self.bounds;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview) {
        [self updateFractionAnimation];
    }
}

- (void)updateFractionAnimation {
      dispatch_async(dispatch_get_main_queue(), ^{
        self.animator.fractionComplete = self.blurAmount.floatValue;
      });
}

- (void)setBlurType:(NSString *)blurType
{
  if (blurType && ![self.blurType isEqual:blurType]) {
    _blurType = blurType;
    [self updateBlurEffect];
  }
}

- (NSNumber *)valueToUpdate:(NSNumber *)blurAmount {
    if (blurAmount) {
        CGFloat newValue = blurAmount.floatValue / 100;
        CGFloat currentValue = self.blurAmount.floatValue;
    
        if (newValue < 0.01) {
            newValue = 0.01;
        } else if (newValue > 0.99) {
            newValue = 0.99;
        }

        CGFloat roundedValue = ceil(newValue / 0.05) * 0.05;

        // If the current value matches the rounded value, no update is needed
        if (fabs(currentValue - roundedValue) < 0.001) {
            return nil;
        }

    
        return @(roundedValue);
    }

    return nil;
}


- (void)setBlurAmount:(NSNumber *)blurAmount
{
  NSNumber *newBlurAmount = [self valueToUpdate:blurAmount];
  
  if (newBlurAmount != nil) {
    _blurAmount = newBlurAmount;
    [self updateFractionAnimation];
  }
}

- (void)setReducedTransparencyFallbackColor:(nullable UIColor *)reducedTransparencyFallbackColor
{
  if (reducedTransparencyFallbackColor && ![self.reducedTransparencyFallbackColor isEqual:reducedTransparencyFallbackColor]) {
    _reducedTransparencyFallbackColor = reducedTransparencyFallbackColor;
    [self updateFallbackView];
  }
}

- (UIBlurEffectStyle)blurEffectStyle
{
  if ([self.blurType isEqual: @"xlight"]) return UIBlurEffectStyleExtraLight;
  if ([self.blurType isEqual: @"light"]) return UIBlurEffectStyleLight;
  if ([self.blurType isEqual: @"dark"]) return UIBlurEffectStyleDark;

  #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000 /* __IPHONE_10_0 */
    if ([self.blurType isEqual: @"regular"]) return UIBlurEffectStyleRegular;
    if ([self.blurType isEqual: @"prominent"]) return UIBlurEffectStyleProminent;
  #endif

  #if !TARGET_OS_TV && defined(__IPHONE_OS_VERSION_MAX_ALLOWED) && __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000 /* __IPHONE_13_0 */
    // Adaptable blur styles
    if ([self.blurType isEqual: @"chromeMaterial"]) return UIBlurEffectStyleSystemChromeMaterial;
    if ([self.blurType isEqual: @"material"]) return UIBlurEffectStyleSystemMaterial;
    if ([self.blurType isEqual: @"thickMaterial"]) return UIBlurEffectStyleSystemThickMaterial;
    if ([self.blurType isEqual: @"thinMaterial"]) return UIBlurEffectStyleSystemThinMaterial;
    if ([self.blurType isEqual: @"ultraThinMaterial"]) return UIBlurEffectStyleSystemUltraThinMaterial;
    // dark blur styles
    if ([self.blurType isEqual: @"chromeMaterialDark"]) return UIBlurEffectStyleSystemChromeMaterialDark;
    if ([self.blurType isEqual: @"materialDark"]) return UIBlurEffectStyleSystemMaterialDark;
    if ([self.blurType isEqual: @"thickMaterialDark"]) return UIBlurEffectStyleSystemThickMaterialDark;
    if ([self.blurType isEqual: @"thinMaterialDark"]) return UIBlurEffectStyleSystemThinMaterialDark;
    if ([self.blurType isEqual: @"ultraThinMaterialDark"]) return UIBlurEffectStyleSystemUltraThinMaterialDark;
    // light blur styles
    if ([self.blurType isEqual: @"chromeMaterialLight"]) return UIBlurEffectStyleSystemChromeMaterialLight;
    if ([self.blurType isEqual: @"materialLight"]) return UIBlurEffectStyleSystemMaterialLight;
    if ([self.blurType isEqual: @"thickMaterialLight"]) return UIBlurEffectStyleSystemThickMaterialLight;
    if ([self.blurType isEqual: @"thinMaterialLight"]) return UIBlurEffectStyleSystemThinMaterialLight;
    if ([self.blurType isEqual: @"ultraThinMaterialLight"]) return UIBlurEffectStyleSystemUltraThinMaterialLight;
  #endif
    
  #if TARGET_OS_TV
    if ([self.blurType isEqual: @"regular"]) return UIBlurEffectStyleRegular;
    if ([self.blurType isEqual: @"prominent"]) return UIBlurEffectStyleProminent;
    if ([self.blurType isEqual: @"extraDark"]) return UIBlurEffectStyleExtraDark;
  #endif

  return UIBlurEffectStyleDark;
}

- (BOOL)useReduceTransparencyFallback
{
  return UIAccessibilityIsReduceTransparencyEnabled() == YES && self.reducedTransparencyFallbackColor != NULL;
}

- (void)updateBlurEffect
{
  // Without resetting the effect, changing blurAmount doesn't seem to work in Fabric...
  // Setting it to nil should also enable blur animations (see PR #392)
  self.blurEffectView.effect = nil;
  
  UIBlurEffectStyle style = [self blurEffectStyle];
  self.blurEffect = [UIBlurEffect effectWithStyle:style];
  [self invalidateAnimator];
  
  __weak typeof(self) weakSelf = self;
  self.animator = [[UIViewPropertyAnimator alloc]
                   initWithDuration:1.0
                   curve:UIViewAnimationCurveLinear animations:^{
    weakSelf.blurEffectView.effect = weakSelf.blurEffect;
           }];
  
  // https://stackoverflow.com/a/42608071
  // Looks like apple bug where fraction does not work if not set pause
  [self.animator startAnimation];
  [self.animator pauseAnimation];
  
  [self updateFractionAnimation];
}

- (void)updateFallbackView
{
  if ([self useReduceTransparencyFallback]) {
    if (![self.subviews containsObject:self.reducedTransparencyFallbackView]) {
      [self insertSubview:self.reducedTransparencyFallbackView atIndex:0];
    }

    if ([self.subviews containsObject:self.blurEffectView]) {
      [self.blurEffectView removeFromSuperview];
    }
  } else {
    if ([self.subviews containsObject:self.reducedTransparencyFallbackView]) {
      [self.reducedTransparencyFallbackView removeFromSuperview];
    }

    if (![self.subviews containsObject:self.blurEffectView]) {
      [self insertSubview:self.blurEffectView atIndex:0];
    }
  }

  self.reducedTransparencyFallbackView.backgroundColor = self.reducedTransparencyFallbackColor;
}

- (void)reduceTransparencyStatusDidChange:(__unused NSNotification *)notification
{
  [self updateFallbackView];
}

@end

#ifdef RCT_NEW_ARCH_ENABLED
Class<RCTComponentViewProtocol> BlurViewCls(void)
{
  return BlurView.class;
}
#endif // RCT_NEW_ARCH_ENABLED
