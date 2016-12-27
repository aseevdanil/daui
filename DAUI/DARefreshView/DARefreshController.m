//
//  DARefreshController.m
//  daui
//
//  Created by da on 26.03.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DARefreshController.h"

#import "DARefreshView.h"



@protocol DARefreshItemStateObserver

@optional
- (void)refreshItem:(DARefreshItem*)refreshItem didUpdateRefreshingState:(BOOL)animated;
- (void)refreshItem:(DARefreshItem*)refreshItem didUpdateDisabledState:(BOOL)animated;

@end


@interface DARefreshItem (Private)

@property (nonatomic, unsafe_unretained) id stateObserver;

- (BOOL)shouldRefreshing;

@end


@implementation DARefreshItem (Private)


@dynamic stateObserver;


- (BOOL)shouldRefreshing
{
	DASSERT(!_refreshing);
	if (_refreshing)
		return NO;
	BOOL refreshing = NO;
	id strongShouldRefreshingDelegate = _shouldRefreshingDelegate;
	if (strongShouldRefreshingDelegate && _shouldRefreshingSelector)
	{
		if ([strongShouldRefreshingDelegate respondsToSelector:_shouldRefreshingSelector])
		{
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[strongShouldRefreshingDelegate class] instanceMethodSignatureForSelector:_shouldRefreshingSelector]];
			[invocation setSelector:_shouldRefreshingSelector];
			[invocation setTarget:strongShouldRefreshingDelegate];
			[invocation invoke];
			[invocation getReturnValue:&refreshing];
		}
	}
	_refreshing = refreshing;
	return _refreshing;
}


@end



@implementation DARefreshController


static char DARefreshControllerContext;


@synthesize refreshItem = _refreshItem;
@synthesize attachedScrollView = _attachedScrollView;
@synthesize refreshControllerDelegate = _refreshControllerDelegate;


- (instancetype)initWithRefreshItem:(DARefreshItem*)refreshItem placement:(DARefreshPlacement)placement
{
	DASSERT(refreshItem);
	if ((self = [super init]))
	{
		_placement = placement;
		_compact = NO;
		_notRefrashable = _postRefreshing = NO;
		_refreshItem = refreshItem;
		_refreshItem.stateObserver = self;
		[_refreshItem addObserver:self forKeyPath:@"hidden" options:0 context:&DARefreshControllerContext];
		[_refreshItem addObserver:self forKeyPath:@"tintColor" options:0 context:&DARefreshControllerContext];
	}
	return self;
}


- (void)dealloc
{
	self.attachedScrollView = nil;
	_refreshItem.stateObserver = nil;
	[_refreshItem removeObserver:self forKeyPath:@"hidden" context:&DARefreshControllerContext];
	[_refreshItem removeObserver:self forKeyPath:@"tintColor" context:&DARefreshControllerContext];
}


- (DARefreshPlacement)placement
{
	return _placement;
}


- (void)refreshItem:(DARefreshItem*)refreshItem didUpdateRefreshingState:(BOOL)animated
{
	UIScrollView *strongAttachedScrollView = _attachedScrollView;
	if (strongAttachedScrollView)
	{
		DASSERT(_refreshView);
		BOOL refreshing = _refreshView.isRefreshing;
		[_refreshView setRefreshing:_refreshItem.isRefreshing animated:animated];
		_refreshView.level = 0.;
		if (refreshing && !_refreshView.isRefreshing)
			_postRefreshing = YES;
		id <DARefreshControllerDelegate> strongDelegate = _refreshControllerDelegate;
		if (strongDelegate)
			[strongDelegate refreshControllerDidModifyAdditionalInsets:self];
	}
}


- (void)refreshItem:(DARefreshItem*)refreshItem didUpdateDisabledState:(BOOL)animated
{
	UIScrollView *strongAttachedScrollView = _attachedScrollView;
	if (strongAttachedScrollView)
	{
		DASSERT(_refreshView);
		[_refreshView setDisabled:_refreshItem.isDisabled animated:animated];
		_refreshView.level = 0.;
		id <DARefreshControllerDelegate> strongDelegate = _refreshControllerDelegate;
		if (strongDelegate)
			[strongDelegate refreshControllerDidModifyAdditionalInsets:self];
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &DARefreshControllerContext)
	{
		UIScrollView *strongAttachedScrollView = _attachedScrollView;
		if (object == _refreshItem)
		{
			if ([keyPath isEqualToString:@"hidden"])
			{
				if (_refreshView)
					_refreshView.hidden = _refreshItem.isHidden;
			}
			else if ([keyPath isEqualToString:@"tintColor"])
			{
				if (_refreshView)
					_refreshView.tintColor = _refreshItem.tintColor;
			}
		}
		else if (object == strongAttachedScrollView)
		{
			if ([keyPath isEqualToString:@"contentOffset"])
			{
				CGRect frame = strongAttachedScrollView.frame;
				CGPoint contentOffset = strongAttachedScrollView.contentOffset;
				UIEdgeInsets contentInset = strongAttachedScrollView.contentInset;
				CGSize contentSize = strongAttachedScrollView.contentSize;
				CGFloat shift = 0.;
				switch (_placement)
				{
					case DARefreshPlacementLeft:
						shift = -(contentOffset.x + contentInset.left);
						break;
					case DARefreshPlacementBottom:
						shift = contentOffset.y + frame.size.height - contentInset.bottom - MAX(contentSize.height, frame.size.height - (contentInset.top + contentInset.bottom));
						break;
					case DARefreshPlacementRight:
						shift = contentOffset.x + frame.size.width - contentInset.left - MAX(contentSize.width, frame.size.width - (contentInset.left + contentInset.right));
						break;
					case DARefreshPlacementTop:
					default:
						shift = -(contentOffset.y + contentInset.top);
						break;
				}
				
				CGAffineTransform transform = CGAffineTransformIdentity;
				if (_refreshView.isRefreshing && !_refreshView.isDisabled)
				{
					CGSize refreshViewSize = [DARefreshView preferredViewSize:_compact];
					switch (_placement)
					{
						case DARefreshPlacementLeft:
							transform.tx -= refreshViewSize.width;
							break;
						case DARefreshPlacementBottom:
							transform.ty += refreshViewSize.height;
							break;
						case DARefreshPlacementRight:
							transform.tx += refreshViewSize.width;
							break;
						case DARefreshPlacementTop:
						default:
							transform.ty -= refreshViewSize.height;
							break;
					}
				}
				if (shift > 0.)
				{
					switch (_placement)
					{
						case DARefreshPlacementLeft:
							transform.tx -= shift;
							break;
						case DARefreshPlacementBottom:
							transform.ty += shift;
							break;
						case DARefreshPlacementRight:
							transform.tx += shift;
							break;
						case DARefreshPlacementTop:
						default:
							transform.ty -= shift;
							break;
					}
				}
				else
				{
					_postRefreshing = NO;
				}
				_refreshView.transform = transform;
				
				if (!_refreshView.isRefreshing && !_postRefreshing && !_refreshView.isDisabled)
				{
					if (strongAttachedScrollView.isTracking || strongAttachedScrollView.isDragging || strongAttachedScrollView.isDecelerating)
						[_refreshView setLevel:[DARefreshView preferredLevelForContentShift:shift compact:_compact] animated:YES];
					else
						_refreshView.level = 0.;
					if (strongAttachedScrollView.isDecelerating)
					{
						if (_refreshView.level >= 1.)
						{
							if (!_notRefrashable)
							{
								if (!_refreshItem.isHidden && [_refreshItem shouldRefreshing])
								{
									[_refreshView setRefreshing:YES animated:YES];
									_refreshView.level = 0.;
									id <DARefreshControllerDelegate> strongDelegate = _refreshControllerDelegate;
									if (strongDelegate)
										[strongDelegate refreshControllerDidModifyAdditionalInsets:self];
								}
								else
								{
									_notRefrashable = YES;
								}
							}
						}
						else
						{
							_notRefrashable = NO;
						}
					}
				}
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)setAttachedScrollView:(UIScrollView *)attachedScrollView
{
	static const UIRectEdge RefreshPlacementToAttachedEdge[] =
	{
		/*DARefreshPlacementTop*/		UIRectEdgeTop,
		/*DARefreshPlacementLeft*/		UIRectEdgeLeft,
		/*DARefreshPlacementBottom*/	UIRectEdgeBottom,
		/*DARefreshPlacementRight*/		UIRectEdgeRight,
	};
	
	UIScrollView *strongAttachedScrollView = _attachedScrollView;
	if (attachedScrollView == strongAttachedScrollView)
		return;
	if (strongAttachedScrollView)
	{
		[strongAttachedScrollView removeObserver:self forKeyPath:@"contentOffset" context:&DARefreshControllerContext];
		DASSERT(_refreshView);
		[_refreshView removeFromSuperview];
		_refreshView.refreshing = NO;
		_refreshView.level = 0.;
		_refreshView = nil;
		_notRefrashable = _postRefreshing = NO;
		_compact = NO;
	}
	_attachedScrollView = attachedScrollView;
	strongAttachedScrollView = _attachedScrollView;
	if (strongAttachedScrollView)
	{
		_refreshView = [[DARefreshView alloc] init];
		_refreshView.attachEdge = RefreshPlacementToAttachedEdge[_placement];
		_refreshView.hidden = _refreshItem.isHidden;
		_refreshView.tintColor = _refreshItem.tintColor;
		_refreshView.disabled = _refreshItem.isDisabled;
		_refreshView.refreshing = _refreshItem.isRefreshing;
		_refreshView.level = 0.;
		[strongAttachedScrollView addSubview:_refreshView];
		[strongAttachedScrollView addObserver:self forKeyPath:@"contentOffset" options:0 context:&DARefreshControllerContext];
	}
}


- (void)layoutRefreshViewInAttachedScrollView:(UIEdgeInsets)attachedScrollViewInsets
{
	UIScrollView *strongAttachedScrollView = _attachedScrollView;
	DASSERT(strongAttachedScrollView && _refreshView);
	if (!strongAttachedScrollView)
		return;
	
	CGRect scrollViewFrame = strongAttachedScrollView.frame;
	CGSize contentSize = scrollViewFrame.size;
	contentSize.width -= attachedScrollViewInsets.left + attachedScrollViewInsets.right;
	contentSize.height -= attachedScrollViewInsets.top + attachedScrollViewInsets.bottom;
	CGRect refreshViewFrame = CGRectZero;
	CGSize refreshViewSizeRegular = [DARefreshView preferredViewSize:NO], refreshViewSizeCompact = [DARefreshView preferredViewSize:YES];
	CGSize minimumNoncompactViewSize = [DARefreshView preferredMinimumContentSizeForNonCompactViewSize];
	switch (_placement)
	{
		case DARefreshPlacementLeft:
			_compact = contentSize.width < minimumNoncompactViewSize.width;
			refreshViewFrame.size.height = contentSize.height;
			refreshViewFrame.size.width = _compact ? refreshViewSizeCompact.width : refreshViewSizeRegular.width;
			break;
		case DARefreshPlacementBottom:
			_compact = contentSize.height < minimumNoncompactViewSize.height;
			refreshViewFrame.size.width = contentSize.width;
			refreshViewFrame.size.height = _compact ? refreshViewSizeCompact.height : refreshViewSizeRegular.height;
			refreshViewFrame.origin.y += MAX(strongAttachedScrollView.contentSize.height,contentSize.height) - refreshViewFrame.size.height;
			break;
		case DARefreshPlacementRight:
			_compact = contentSize.width < minimumNoncompactViewSize.width;
			refreshViewFrame.size.height = contentSize.height;
			refreshViewFrame.size.width = _compact ? refreshViewSizeCompact.width : refreshViewSizeRegular.width;
			refreshViewFrame.origin.x += MAX(strongAttachedScrollView.contentSize.width, contentSize.width) - refreshViewFrame.size.width;
			break;
		case DARefreshPlacementTop:
		default:
			_compact = contentSize.height < minimumNoncompactViewSize.height;
			refreshViewFrame.size.width = contentSize.width;
			refreshViewFrame.size.height = _compact ? refreshViewSizeCompact.height : refreshViewSizeRegular.height;
			break;
	}
	_refreshView.bounds = (CGRect){.origin = CGPointZero, .size = refreshViewFrame.size};
	_refreshView.center = CGRectGetCenter(refreshViewFrame);
}


- (UIEdgeInsets)getAdditionalInsetsForAttachedScrollViewInsets:(UIEdgeInsets)attachedScrollViewInsets
{
	UIScrollView *strongAttachedScrollView = _attachedScrollView;
	DASSERT(strongAttachedScrollView && _refreshView);
	if (!strongAttachedScrollView)
		return UIEdgeInsetsZero;
	
	UIEdgeInsets contentInset = UIEdgeInsetsZero;
	if (_refreshView.isRefreshing && !_refreshView.isDisabled)
	{
		CGSize refreshViewSize = [DARefreshView preferredViewSize:_compact];
		switch (_placement)
		{
			case DARefreshPlacementLeft:
				contentInset.left += refreshViewSize.width;
				break;
			case DARefreshPlacementBottom:
				contentInset.bottom += refreshViewSize.height + MAX(strongAttachedScrollView.frame.size.height - (attachedScrollViewInsets.top + attachedScrollViewInsets.bottom) - strongAttachedScrollView.contentSize.height, 0.);
				break;
			case DARefreshPlacementRight:
				contentInset.right += refreshViewSize.width + MAX(strongAttachedScrollView.frame.size.width - (attachedScrollViewInsets.left + attachedScrollViewInsets.right) - strongAttachedScrollView.contentSize.width, 0.);
				break;
			case DARefreshPlacementTop:
			default:
				contentInset.top += refreshViewSize.height;
				break;
		}
	}
	return contentInset;
}


@end
