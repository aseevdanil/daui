//
//  DARefreshItem.m
//  loveplanet
//
//  Created by da on 24.04.15.
//  Copyright (c) 2015 RBC. All rights reserved.
//

#import "DARefreshItem.h"

#import "DARefreshView.h"



@protocol DARefreshItemStateObserver

@optional
- (void)refreshItem:(DARefreshItem*)refreshItem didUpdateRefreshingState:(BOOL)animated;
- (void)refreshItem:(DARefreshItem*)refreshItem didUpdateDisabledState:(BOOL)animated;

@end


@interface DARefreshItem ()

@property (nonatomic, unsafe_unretained) id stateObserver;

@end


@implementation DARefreshItem


@synthesize tintColor = _tintColor;
@synthesize shouldRefreshingDelegate = _shouldRefreshingDelegate, shouldRefreshingSelector = _shouldRefreshingSelector;
@synthesize stateObserver = _stateObserver;


- (instancetype)init
{
	if ((self = [super init]))
	{
		_disabled = _refreshing = NO;
		_hidden = NO;
		_tintColor = [DARefreshView defaultTintColor];
	}
	return self;
}


- (BOOL)isHidden
{
	return _hidden;
}


- (void)setHidden:(BOOL)hidden
{
	_hidden = hidden;
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
	if (_stateObserver && [_stateObserver respondsToSelector:@selector(refreshItem:didUpdateDisabledState:)])
		[(id <DARefreshItemStateObserver>) _stateObserver refreshItem:self didUpdateDisabledState:animated];
}


- (BOOL)isRefreshing
{
	return _refreshing;
}


- (void)setRefreshing:(BOOL)refreshing
{
	[self setRefresing:refreshing animated:NO];
}


- (void)setRefresing:(BOOL)refreshing animated:(BOOL)animated
{
	if (refreshing == _refreshing)
		return;
	_refreshing = refreshing;
	if (_stateObserver && [_stateObserver respondsToSelector:@selector(refreshItem:didUpdateRefreshingState:)])
		[(id <DARefreshItemStateObserver>) _stateObserver refreshItem:self didUpdateRefreshingState:animated];
}


@end
