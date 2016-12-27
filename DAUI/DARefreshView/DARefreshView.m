//
//  DARefreshView.m
//  daui
//
//  Created by da on 26.03.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DARefreshView.h"



#pragma mark -
#pragma mark DARefreshLayer


enum { kDARefreshSpinnerLayer_NumberOfTicks = 12 };

@interface DARefreshSpinnerLayer : CALayer
{
	CAShapeLayer *_tickLayer[kDARefreshSpinnerLayer_NumberOfTicks];
	NSUInteger _numberOfHighlightedTicks;
	unsigned int _spin : 1;
	unsigned int _finishSpin : 1;
}

@property (nonatomic, assign) NSUInteger numberOfHighlightedTicks;
- (void)setNumberOfHighlightedTicks:(NSUInteger)numberOfHighlightedTicks animated:(BOOL)animated;
@property (nonatomic, assign, readonly, getter = isSpin) BOOL spin;
- (void)startSpin:(BOOL)animated completion:(void(^)(void))completion;
- (void)finishSpin:(BOOL)animated completion:(void(^)(void))completion;

@property (nonatomic, assign /*copy*/) CGColorRef tintColor;

+ (CGSize)preferredLayerSize;

@end


@interface DARefreshSpinnerLayer ()

- (void)updateTiksAlphas:(BOOL)animated;

@end


@implementation DARefreshSpinnerLayer


static CAShapeLayer* DARefreshSpinnerLayer_CreateTickLayer(CGSize size)
{
	CAShapeLayer *layer = [[CAShapeLayer alloc] init];
	layer.bounds = (CGRect){.origin = CGPointZero, .size = size};
	CGFloat lineWidth = size.width - 1.;
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, size.width / 2, (lineWidth + 1.) / 2);
	CGPathAddLineToPoint(path, NULL, size.width / 2, size.height - (lineWidth + 1.) / 2);
	layer.path = path;
	CGPathRelease(path);
	layer.lineCap = kCALineCapRound;
	layer.lineJoin = kCALineJoinRound;
	layer.lineWidth = lineWidth;
	layer.strokeColor = nil;
	return layer;
}


+ (CGSize)preferredLayerSize
{
	return CGSizeMake(28., 28.);
}


@synthesize numberOfHighlightedTicks = _numberOfHighlightedTicks;
@synthesize tintColor = _tintColor;


- (instancetype)init
{
	if ((self = [super init]))
	{
		self.bounds = (CGRect){.origin = CGPointZero, .size = [DARefreshSpinnerLayer preferredLayerSize]};
		_numberOfHighlightedTicks = 0;
		_spin = NO;
		_finishSpin = NO;
		static const CGSize TickSize = (CGSize){3., 9.};
		CGPoint tickPosition = CGRectGetCenter(self.bounds);
		CGFloat tickOffset = (self.bounds.size.height - TickSize.height) / 2;
		// delta = M_PI / 6
		const CGFloat sind = .5, cosd = .866025403784439;
		CGFloat sina = 0., cosa = 1.;
		for (NSUInteger i = 0; i < kDARefreshSpinnerLayer_NumberOfTicks; ++i)
		{
			_tickLayer[i] = DARefreshSpinnerLayer_CreateTickLayer(TickSize);
			_tickLayer[i].position = tickPosition;
			CATransform3D rotateTransform = { cosa, sina, 0., 0., -sina, cosa, 0., 0., 0., 0., 1., 0., 0., 0., 0., 1. };
			CATransform3D translateTransform = { 1., 0., 0., 0., 0., 1, 0., 0., 0., 0., 1., 0., 0., -tickOffset, 0., 1. };
			CATransform3D transform = CATransform3DConcat(translateTransform, rotateTransform);
			_tickLayer[i].transform = transform;
			CGFloat sinad = sina * cosd + sind * cosa, cosad = cosa * cosd - sina * sind;
			sina = sinad;
			cosa = cosad;
			_tickLayer[i].opacity = 0.;
			[self addSublayer:_tickLayer[i]];
		}
	}
	return self;
}


- (void)setContentsScale:(CGFloat)contentsScale
{
	[super setContentsScale:contentsScale];
	for (NSUInteger i = 0; i < kDARefreshSpinnerLayer_NumberOfTicks; ++i)
		_tickLayer[i].contentsScale = contentsScale;
}


- (void)updateTiksAlphas:(BOOL)animated
{
	DASSERT(!_spin);
	[CATransaction begin];
	[CATransaction setDisableActions:!animated];
	[CATransaction setAnimationDuration:.1];
	for (NSUInteger i = 0; i < kDARefreshSpinnerLayer_NumberOfTicks; ++i)
		_tickLayer[i].opacity = i < _numberOfHighlightedTicks ? 1. : 0.;
	[CATransaction commit];
}


- (CGColorRef)tintColor
{
	return _tickLayer[0].strokeColor;
}


- (void)setTintColor:(CGColorRef)tintColor
{
	for (NSUInteger i = 0; i < kDARefreshSpinnerLayer_NumberOfTicks; ++i)
		_tickLayer[i].strokeColor = tintColor;
}


- (void)setNumberOfHighlightedTicks:(NSUInteger)numberOfHighlightedTicks
{
	[self setNumberOfHighlightedTicks:numberOfHighlightedTicks animated:NO];
}


- (void)setNumberOfHighlightedTicks:(NSUInteger)numberOfHighlightedTicks animated:(BOOL)animated
{
	if (numberOfHighlightedTicks > kDARefreshSpinnerLayer_NumberOfTicks)
		numberOfHighlightedTicks = kDARefreshSpinnerLayer_NumberOfTicks;
	if (numberOfHighlightedTicks == _numberOfHighlightedTicks)
		return;
	_numberOfHighlightedTicks = numberOfHighlightedTicks;
	if (!_spin)
		[self updateTiksAlphas:animated];
}


- (BOOL)isSpin
{
	return _spin;
}


#define kDARefreshSpinnerLayer_BlinkPeriodDuration	1.


- (void)startSpin:(BOOL)animated completion:(void(^)(void))completion
{
	if (_spin && !_finishSpin)
		return;
	CAAnimation *spinAnimation = [self animationForKey:@"spin"];
	if (spinAnimation)
	{
		void (^completionSpin)(void) = (void(^)(void))[spinAnimation valueForKey:@"completion"];
		if (completionSpin)
			completionSpin();
		[spinAnimation setValue:nil forKey:@"completion"];
		[self removeAnimationForKey:@"spin"];
	}
	_spin = YES;
	for (NSUInteger i = 0; i < kDARefreshSpinnerLayer_NumberOfTicks; ++i)
	{
		CABasicAnimation *blinkAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
		blinkAnimation.fromValue = [NSNumber numberWithCGFloat:1.];
		blinkAnimation.toValue = [NSNumber numberWithCGFloat:0.];
		blinkAnimation.repeatCount = HUGE_VALF;
		blinkAnimation.removedOnCompletion = NO;
		blinkAnimation.duration = kDARefreshSpinnerLayer_BlinkPeriodDuration;
		blinkAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
		CFTimeInterval currentTime = CACurrentMediaTime();
		currentTime = [self convertTime:currentTime fromLayer:nil];
		blinkAnimation.beginTime = [self convertTime:currentTime toLayer:_tickLayer[i]] + kDARefreshSpinnerLayer_BlinkPeriodDuration * i / kDARefreshSpinnerLayer_NumberOfTicks;
		[_tickLayer[i] addAnimation:blinkAnimation forKey:@"blink"];
	}
	if (animated)
	{
		CABasicAnimation *spinAnimation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.rotation.z"];
		spinAnimation.fromValue = [NSNumber numberWithFloat:0];
		spinAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI];
		spinAnimation.duration = kDARefreshSpinnerLayer_BlinkPeriodDuration;
		spinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		[self addAnimation:spinAnimation forKey:@"spin"];
	}
	if (completion)
		completion();
}


- (void)finishSpin:(BOOL)animated completion:(void(^)(void))completion
{
	if (!_spin || _finishSpin)
		return;
	CAAnimation *spinAnimation = [self animationForKey:@"spin"];
	if (spinAnimation)
	{
		void (^completionSpin)(void) = (void(^)(void))[spinAnimation valueForKey:@"completion"];
		if (completionSpin)
			completionSpin();
		[spinAnimation setValue:nil forKey:@"completion"];
		[self removeAnimationForKey:@"spin"];
	}
	void (^completionSpin)(void) = ^
	{
		for (NSUInteger i = 0; i < kDARefreshSpinnerLayer_NumberOfTicks; ++i)
			[_tickLayer[i] removeAnimationForKey:@"blink"];
		DASSERT(_finishSpin);
		_finishSpin = NO;
		_spin = NO;
		[self updateTiksAlphas:NO];
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		self.sublayerTransform = CATransform3DIdentity;
		[CATransaction commit];
		if (completion)
			completion();
	};
	_finishSpin = YES;
	if (animated)
	{
		[self setValue:[NSNumber numberWithFloat:0.] forKeyPath:@"sublayerTransform.scale.x"];
		[self setValue:[NSNumber numberWithFloat:0.] forKeyPath:@"sublayerTransform.scale.y"];
		NSTimeInterval duration = kDARefreshSpinnerLayer_BlinkPeriodDuration * .4;
		CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.rotation.z"];
		rotationAnimation.fromValue = [NSNumber numberWithFloat:0.];
		rotationAnimation.toValue = [NSNumber numberWithFloat:M_PI];
		rotationAnimation.duration = duration;
		rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		CABasicAnimation *scaleXAnimation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.scale.x"];
		scaleXAnimation.fromValue = [NSNumber numberWithFloat:1.];
		scaleXAnimation.toValue = [NSNumber numberWithFloat:0.];
		scaleXAnimation.duration = duration;
		scaleXAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		CABasicAnimation *scaleYAnimation = [CABasicAnimation animationWithKeyPath:@"sublayerTransform.scale.y"];
		scaleYAnimation.fromValue = [NSNumber numberWithFloat:1.];
		scaleYAnimation.toValue = [NSNumber numberWithFloat:0.];
		scaleYAnimation.duration = duration;
		scaleYAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
		CAAnimationGroup *spinAnimation = [CAAnimationGroup animation];
		spinAnimation.animations = [NSArray arrayWithObjects:rotationAnimation, scaleXAnimation, scaleYAnimation, nil];
		spinAnimation.duration = duration;
		spinAnimation.delegate = (id<CAAnimationDelegate>) self;
		[spinAnimation setValue:[completionSpin copy] forKey:@"completion"];
		[self addAnimation:spinAnimation forKey:@"spin"];
	}
	else
	{
		completionSpin();
	}
}


- (void)animationDidStop:(CABasicAnimation *)theAnimation finished:(BOOL)flag
{
	void (^completion)(void) = (void (^)(void))[theAnimation valueForKey:@"completion"];
	if (completion)
		completion();
}


@end



@interface DARefreshLayer : CALayer
{
	DARefreshSpinnerLayer *_spinnerLayer;
	UIRectEdge _attachEdge;
	CGFloat _level;
	unsigned int _disabled : 1;
	unsigned int _refreshing : 1;
}

@property (nonatomic, assign) UIRectEdge attachEdge;
@property (nonatomic, assign /*copy*/) CGColorRef tintColor;

@property (nonatomic, assign, getter = isDisabled) BOOL disabled;
- (void)setDisabled:(BOOL)disabled animated:(BOOL)animated;
@property (nonatomic, assign) CGFloat level;
- (void)setLevel:(CGFloat)level animated:(BOOL)animated;
@property (nonatomic, assign, getter = isRefreshing) BOOL refreshing;
- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated;

+ (CGSize)preferredLayerSizeWithBoundsInsets:(UIEdgeInsets)boundsInsets;
+ (CGFloat)preferredLevelForContentShift:(CGFloat)shift boundsInsets:(UIEdgeInsets)boundsInsets;

@end


@implementation DARefreshLayer


@synthesize attachEdge = _attachEdge;
@synthesize level = _level;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_attachEdge = UIRectEdgeNone;
		_level = 0.;
		_disabled = _refreshing = NO;
		
		_spinnerLayer = [[DARefreshSpinnerLayer alloc] init];
		_spinnerLayer.opacity = 0.;
		_spinnerLayer.position = CGRectGetCenter(self.bounds);
		[self addSublayer:_spinnerLayer];
	}
	return self;
}


- (void)setContentsScale:(CGFloat)contentsScale
{
	[super setContentsScale:contentsScale];
	_spinnerLayer.contentsScale = self.contentsScale;
}


- (void)layoutSublayers
{
	[super layoutSublayers];
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	_spinnerLayer.position = CGRectGetCenter(self.bounds);
	[CATransaction commit];
}


- (void)updateSpinnerOpacity:(BOOL)animated
{
	[CATransaction begin];
	[CATransaction setDisableActions:!animated];
	[CATransaction setAnimationDuration:.1];
	_spinnerLayer.opacity = _spinnerLayer.isSpin ? 1. : (_disabled ? 0. : (_level < .25 ? _level / .25 : 1.));
	[CATransaction commit];
}


- (void)setAttachEdge:(UIRectEdge)attachEdge
{
	if (attachEdge == _attachEdge)
		return;
	_attachEdge = attachEdge;
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	switch (_attachEdge)
	{
		case UIRectEdgeLeft:
			_spinnerLayer.transform = CATransform3DMakeRotation(M_PI_2, 0., 0., 1.);
			break;
		case UIRectEdgeBottom:
			_spinnerLayer.transform = CATransform3DMakeRotation(M_PI, 0., 0., 1.);
			break;
		case UIRectEdgeRight:
			_spinnerLayer.transform = CATransform3DMakeRotation(-M_PI_2, 0., 0., 1.);
			break;
		case UIRectEdgeNone:
		case UIRectEdgeTop:
		default:
			_spinnerLayer.transform = CATransform3DIdentity;
			break;
	}
	[CATransaction commit];
}


- (CGColorRef)tintColor
{
	return _spinnerLayer.tintColor;
}


- (void)setTintColor:(CGColorRef)tintColor
{
	_spinnerLayer.tintColor = tintColor;
}


- (BOOL)isDisabled
{
	return _disabled;
}


- (void)setDisabled:(BOOL)disabled
{
	[self setDisabled:disabled animated:NO];
}


- (void)setDisabled:(BOOL)disabled animated:(BOOL)animated
{
	if (disabled == _disabled)
		return;
	_disabled = disabled;
	[self updateSpinnerOpacity:animated];
}


- (void)setLevel:(CGFloat)level
{
	[self setLevel:level animated:NO];
}


- (void)setLevel:(CGFloat)level animated:(BOOL)animated
{
	if (level < 0.)
		level = 0.;
	else if (level > 1.)
		level = 1.;
	if (level == _level)
		return;
	_level = level;
	[_spinnerLayer setNumberOfHighlightedTicks:_level * kDARefreshSpinnerLayer_NumberOfTicks animated:animated];
	[self updateSpinnerOpacity:animated];
}


- (BOOL)isRefreshing
{
	return _refreshing;
}


- (void)setRefreshing:(BOOL)refreshing
{
	[self setRefreshing:refreshing animated:NO];
}


- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated
{
	if (refreshing == _refreshing)
		return;
	_refreshing = refreshing;
	if (_refreshing)
		[_spinnerLayer startSpin:animated completion:^{ [self updateSpinnerOpacity:YES]; }];
	else
		[_spinnerLayer finishSpin:animated completion:^{ [self updateSpinnerOpacity:YES]; }];
}


+ (CGSize)preferredLayerSizeWithBoundsInsets:(UIEdgeInsets)boundsInsets
{
	CGSize size = [DARefreshSpinnerLayer preferredLayerSize];
	size.width += boundsInsets.left + boundsInsets.right;
	size.height += boundsInsets.top + boundsInsets.bottom;
	return size;
}


+ (CGFloat)preferredLevelForContentShift:(CGFloat)shift boundsInsets:(UIEdgeInsets)boundsInsets
{
	return shift / (2 * [self preferredLayerSizeWithBoundsInsets:boundsInsets].height);
}


@end



#pragma mark -


@implementation DARefreshView


#define _refreshLayer ((DARefreshLayer*) self.layer)


+ (UIColor*)defaultTintColor
{
	static const CGFloat DARefreshView_DefaultTintColorComponents[] = { 77. / 255., 84. / 255., 97. / 255., 1. };
	return [UIColor colorWithRGBAComponents:DARefreshView_DefaultTintColorComponents];
}


+ (UIEdgeInsets)defaultBoundsInsets
{
	return UIEdgeInsetsMake(16., 16., 16., 16.);
}


+ (Class)layerClass
{
	return [DARefreshLayer class];
}


- (instancetype)initWithFrame:(CGRect)frame
{
	if (CGRectIsEmpty(frame))
		frame.size = [DARefreshView preferredViewSize:NO];
	if ((self = [super initWithFrame:frame]))
	{
		self.layer.contentsScale = UIScreenScale();
		self.tintColor = [DARefreshView defaultTintColor];
		self.userInteractionEnabled = NO;
	}
	return self;
}


- (void)tintColorDidChange
{
	[super tintColorDidChange];
	_refreshLayer.tintColor = self.tintColor.CGColor;
}


- (UIRectEdge)attachEdge
{
	return _refreshLayer.attachEdge;
}


- (void)setAttachEdge:(UIRectEdge)attachEdge
{
	_refreshLayer.attachEdge = attachEdge;
}


- (BOOL)isDisabled
{
	return _refreshLayer.isDisabled;
}


- (void)setDisabled:(BOOL)disabled
{
	[self setDisabled:disabled animated:NO];
}


- (void)setDisabled:(BOOL)disabled animated:(BOOL)animated
{
	[_refreshLayer setDisabled:disabled animated:animated];
}


- (CGFloat)level
{
	return _refreshLayer.level;
}


- (void)setLevel:(CGFloat)level
{
	[self setLevel:level animated:NO];
}


- (void)setLevel:(CGFloat)level animated:(BOOL)animated
{
	[_refreshLayer setLevel:level animated:animated];
}


- (BOOL)isRefreshing
{
	return _refreshLayer.refreshing;
}


- (void)setRefreshing:(BOOL)refreshing
{
	[self setRefreshing:refreshing animated:NO];
}


- (void)setRefreshing:(BOOL)refreshing animated:(BOOL)animated
{
	[_refreshLayer setRefreshing:refreshing animated:animated];
}


+ (CGSize)preferredViewSize:(BOOL)compact
{
	UIEdgeInsets boundsInsets = [self defaultBoundsInsets];
	if (compact)
	{
		boundsInsets.top /= 4.;
		boundsInsets.left /= 4.;
		boundsInsets.bottom /= 4.;
		boundsInsets.right /= 4.;
	}
	return [DARefreshLayer preferredLayerSizeWithBoundsInsets:boundsInsets];
}


+ (CGSize)preferredMinimumContentSizeForNonCompactViewSize
{
	CGSize size = [self preferredViewSize:NO];
	size.width *= 9;
	size.height *= 9;
	return size;
}


+ (CGFloat)preferredLevelForContentShift:(CGFloat)shift compact:(BOOL)compact
{
	UIEdgeInsets boundsInsets = [self defaultBoundsInsets];
	if (compact)
	{
		boundsInsets.top /= 4.;
		boundsInsets.left /= 4.;
		boundsInsets.bottom /= 4.;
		boundsInsets.right /= 4.;
	}
	return [DARefreshLayer preferredLevelForContentShift:shift boundsInsets:boundsInsets];
}


@end
