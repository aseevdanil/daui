//
//  DARefreshItem.h
//  loveplanet
//
//  Created by da on 24.04.15.
//  Copyright (c) 2015 RBC. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DARefreshItem : NSObject
{
	UIColor *_tintColor;
	
	id __weak _shouldRefreshingDelegate;
	SEL _shouldRefreshingSelector;
	
	id __unsafe_unretained _stateObserver;
	unsigned int _disabled : 1;
	unsigned int _refreshing : 1;
	unsigned int _hidden : 1;
}

// KVO
@property (nonatomic, assign, getter = isHidden) BOOL hidden;
@property (nonatomic, strong) UIColor *tintColor;

@property (nonatomic, weak) id shouldRefreshingDelegate;
@property (nonatomic, assign) SEL shouldRefreshingSelector;	// - (BOOL)shouldRefreshItemRefreshing:(DARefreshItem*)item;

// State
@property (nonatomic, assign, getter = isDisabled) BOOL disabled;
- (void)setDisabled:(BOOL)disabled animated:(BOOL)animated;
@property (nonatomic, assign, getter = isRefreshing) BOOL refreshing;
- (void)setRefresing:(BOOL)refreshing animated:(BOOL)animated;

@end
