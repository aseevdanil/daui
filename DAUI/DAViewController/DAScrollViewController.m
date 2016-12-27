//
//  DAScrollViewController.m
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAScrollViewController.h"



@interface DAScrollViewController () <DARefreshControllerDelegate>

- (void)updateScrollViewInset;

@end


@implementation DAScrollViewController


#pragma mark -
#pragma mark Base


static char DAScrollViewControllerContext;


@synthesize scrollView = _scrollView;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_manualScrollViewInset = UIEdgeInsetsZero;
		_updatingScrollViewInset = NO;
		for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
			_refreshController[i] = nil;
	}
	return self;
}


- (void)dealloc
{
	if (_scrollView)
	{
		[_scrollView removeObserver:self forKeyPath:@"contentInset" context:&DAScrollViewControllerContext];
		[_scrollView removeObserver:self forKeyPath:@"contentSize" context:&DAScrollViewControllerContext];
	}
	for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
	{
		if (_refreshController[i])
		{
			_refreshController[i].refreshControllerDelegate = nil;
			_refreshController[i] = nil;
		}
	}
	_scrollView = nil;
}


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[self loadScrollView];
}


- (void)viewWillClear
{
	[super viewWillClear];
	
	for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
	{
		if (_refreshController[i])
			_refreshController[i].attachedScrollView = nil;
	}
	if (_scrollView)
	{
		[_scrollView removeObserver:self forKeyPath:@"contentInset" context:&DAScrollViewControllerContext];
		[_scrollView removeObserver:self forKeyPath:@"contentSize" context:&DAScrollViewControllerContext];
	}
}


- (void)viewDidClear
{
	[super viewDidClear];
	
	_scrollView = nil;
	_manualScrollViewInset = UIEdgeInsetsZero;
}


- (void)loadScrollView
{
	self.scrollView = [[UIScrollView alloc] init];
}


- (void)setScrollView:(UIScrollView *)scrollView
{
	DASSERT([self isViewLoaded]);
	if (_scrollView)
	{
		[_scrollView removeObserver:self forKeyPath:@"contentInset" context:&DAScrollViewControllerContext];
		[_scrollView removeObserver:self forKeyPath:@"contentSize" context:&DAScrollViewControllerContext];
		for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
		{
			if (_refreshController[i])
				_refreshController[i].attachedScrollView = nil;
		}
	}
	_scrollView = scrollView;
	if (_scrollView)
	{
		_scrollView.frame = [self scrollViewFrameForAnchorBounds:self.anchorView.bounds];
		[self.anchorView addSubview:_scrollView];
		[_scrollView addObserver:self forKeyPath:@"contentInset" options:0 context:&DAScrollViewControllerContext];
		[_scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:&DAScrollViewControllerContext];
		for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
		{
			if (_refreshController[i])
				_refreshController[i].attachedScrollView = _scrollView;
		}
		if ([self isViewVisible])
			[self updateScrollViewInset];
	}
}


- (void)anchorViewDidLayoutSubviews
{
	[super anchorViewDidLayoutSubviews];
	if (_scrollView)
	{
		_scrollView.frame = [self scrollViewFrameForAnchorBounds:self.anchorView.bounds];
		[self didLayoutScrollView];
	}
}


- (CGRect)scrollViewFrameForAnchorBounds:(CGRect)anchorBounds
{
	return anchorBounds;
}


- (void)didLayoutScrollView
{
}


#pragma mark -
#pragma mark Scroll View Inset


- (void)updateScrollViewInset
{
	if (![self isViewVisible])
		return;
	
	_updatingScrollViewInset = YES;
	UIEdgeInsets diffs = UIEdgeInsetsBetweenRects(self.anchorView.bounds, _scrollView.frame);
	UIEdgeInsets nativeInsets = UIEdgeInsetsMinus(self.anchorInsetsWithKeyboard, diffs);
	if (nativeInsets.top < 0.)
		nativeInsets.top = 0.;
	if (nativeInsets.left < 0.)
		nativeInsets.left = 0.;
	if (nativeInsets.bottom < 0.)
		nativeInsets.bottom = 0.;
	if (nativeInsets.right < 0.)
		nativeInsets.right = 0.;
	_scrollView.scrollIndicatorInsets = nativeInsets;
	UIEdgeInsets additionalInsets = UIEdgeInsetsZero;
	for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
	{
		if (_refreshController[i])
		{
			[_refreshController[i] layoutRefreshViewInAttachedScrollView:nativeInsets];
			UIEdgeInsets insets = [_refreshController[i] getAdditionalInsetsForAttachedScrollViewInsets:nativeInsets];
			additionalInsets = UIEdgeInsetsUnion(additionalInsets, insets);
		}
	}
	_scrollView.contentInset = UIEdgeInsetsUnion(UIEdgeInsetsUnion(nativeInsets, additionalInsets), _manualScrollViewInset);
	[self scrollViewInsetsChanged];
	_updatingScrollViewInset = NO;
}


- (void)scrollViewInsetsChanged
{
	DASSERT([self isViewVisible]);
	if (!_scrollView.isTracking && !_scrollView.isDragging && !_scrollView.isDecelerating)
	{
		CGPoint contentOffset = _scrollView.contentOffset;
		if (contentOffset.y <= 0.)
		{
			UIEdgeInsets contentInset = _scrollView.contentInset;
			contentOffset.y = -contentInset.top;
			_scrollView.contentOffset = contentOffset;
		}
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == &DAScrollViewControllerContext)
	{
		if (object == _scrollView)
		{
			if ([keyPath isEqualToString:@"contentInset"])
			{
				if (!_updatingScrollViewInset)
				{
					_manualScrollViewInset = self.scrollView.contentInset;
					[self updateScrollViewInset];
				}
			}
			else if ([keyPath isEqualToString:@"contentSize"])
			{
				UIEdgeInsets diffs = UIEdgeInsetsBetweenRects(self.anchorView.bounds, _scrollView.frame);
				UIEdgeInsets nativeInsets = UIEdgeInsetsMinus(self.anchorInsetsWithKeyboard, diffs);
				if (nativeInsets.top < 0.)
					nativeInsets.top = 0.;
				if (nativeInsets.left < 0.)
					nativeInsets.left = 0.;
				if (nativeInsets.bottom < 0.)
					nativeInsets.bottom = 0.;
				if (nativeInsets.right < 0.)
					nativeInsets.right = 0.;
				for (NSUInteger i = 0; i < DARefreshPlacementCount; ++i)
				{
					if (_refreshController[i])
						[_refreshController[i] layoutRefreshViewInAttachedScrollView:nativeInsets];
				}
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


- (void)anchorInsetsChanged
{
	[super anchorInsetsChanged];
	
	[self updateScrollViewInset];
}


- (void)dockedKeyboardFrameWillChangeWithDuration:(NSTimeInterval)duration curve:(UIViewAnimationCurve)curve
{
	[super dockedKeyboardFrameWillChangeWithDuration:duration curve:curve];
	
	[self updateScrollViewInset];
}


#pragma mark -
#pragma mark DARefreshItem


- (DARefreshItem*)topRefreshItem
{
	return _refreshController[DARefreshPlacementTop].refreshItem;
}


- (void)setTopRefreshItem:(DARefreshItem *)topRefreshItem
{
	if (_refreshController[DARefreshPlacementTop])
	{
		_refreshController[DARefreshPlacementTop].refreshControllerDelegate = nil;
		_refreshController[DARefreshPlacementTop] = nil;
	}
	if (topRefreshItem)
	{
		_refreshController[DARefreshPlacementTop] = [[DARefreshController alloc] initWithRefreshItem:topRefreshItem placement:DARefreshPlacementTop];
		_refreshController[DARefreshPlacementTop].refreshControllerDelegate = self;
		if ([self isViewLoaded])
			_refreshController[DARefreshPlacementTop].attachedScrollView = _scrollView;
	}
	if ([self isViewVisible])
		[self updateScrollViewInset];
}


- (DARefreshItem*)leftRefreshItem
{
	return _refreshController[DARefreshPlacementLeft].refreshItem;
}


- (void)setLeftRefreshItem:(DARefreshItem *)leftRefreshItem
{
	if (_refreshController[DARefreshPlacementLeft])
	{
		_refreshController[DARefreshPlacementLeft].refreshControllerDelegate = nil;
		_refreshController[DARefreshPlacementLeft] = nil;
	}
	if (leftRefreshItem)
	{
		_refreshController[DARefreshPlacementLeft] = [[DARefreshController alloc] initWithRefreshItem:leftRefreshItem placement:DARefreshPlacementLeft];
		_refreshController[DARefreshPlacementLeft].refreshControllerDelegate = self;
		if ([self isViewLoaded])
			_refreshController[DARefreshPlacementLeft].attachedScrollView = _scrollView;
	}
	if ([self isViewVisible])
		[self updateScrollViewInset];
}


- (DARefreshItem*)bottomRefreshItem
{
	return _refreshController[DARefreshPlacementBottom].refreshItem;
}


- (void)setBottomRefreshItem:(DARefreshItem *)bottomRefreshItem
{
	if (_refreshController[DARefreshPlacementBottom])
	{
		_refreshController[DARefreshPlacementBottom].refreshControllerDelegate = nil;
		_refreshController[DARefreshPlacementBottom] = nil;
	}
	if (bottomRefreshItem)
	{
		_refreshController[DARefreshPlacementBottom] = [[DARefreshController alloc] initWithRefreshItem:bottomRefreshItem placement:DARefreshPlacementBottom];
		_refreshController[DARefreshPlacementBottom].refreshControllerDelegate = self;
		if ([self isViewLoaded])
			_refreshController[DARefreshPlacementBottom].attachedScrollView = _scrollView;
	}
	if ([self isViewVisible])
		[self updateScrollViewInset];
}


- (DARefreshItem*)rightRefreshItem
{
	return _refreshController[DARefreshPlacementRight].refreshItem;
}


- (void)setRightRefreshItem:(DARefreshItem *)rightRefreshItem
{
	if (_refreshController[DARefreshPlacementRight])
	{
		_refreshController[DARefreshPlacementRight].refreshControllerDelegate = nil;
		_refreshController[DARefreshPlacementRight] = nil;
	}
	if (rightRefreshItem)
	{
		_refreshController[DARefreshPlacementRight] = [[DARefreshController alloc] initWithRefreshItem:rightRefreshItem placement:DARefreshPlacementRight];
		_refreshController[DARefreshPlacementRight].refreshControllerDelegate = self;
		if ([self isViewLoaded])
			_refreshController[DARefreshPlacementRight].attachedScrollView = _scrollView;
	}
	if ([self isViewVisible])
		[self updateScrollViewInset];
}


- (void)refreshControllerDidModifyAdditionalInsets:(DARefreshController*)refreshController
{
	if ([self isViewVisible])
		[self updateScrollViewInset];
}


@end
