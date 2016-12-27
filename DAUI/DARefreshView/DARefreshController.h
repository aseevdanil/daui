//
//  DARefreshController.h
//  daui
//
//  Created by da on 26.03.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DARefreshItem.h"

@class DARefreshView;

@protocol DARefreshControllerDelegate;


typedef NS_ENUM(NSUInteger, DARefreshPlacement)
{
	DARefreshPlacementTop,
	DARefreshPlacementLeft,
	DARefreshPlacementBottom,
	DARefreshPlacementRight,
	
	DARefreshPlacementCount,
};



@interface DARefreshController : NSObject
{
	DARefreshItem *_refreshItem;
	DARefreshView *_refreshView;
	UIScrollView * __weak _attachedScrollView;
	
	id <DARefreshControllerDelegate> __weak _refreshControllerDelegate;
	
	unsigned int _placement : 2;
	unsigned int _compact : 1;
	unsigned int _notRefrashable : 1;
	unsigned int _postRefreshing : 1;
}

- (instancetype)initWithRefreshItem:(DARefreshItem*)refreshItem placement:(DARefreshPlacement)placement;
@property (nonatomic, strong, readonly) DARefreshItem *refreshItem;
@property (nonatomic, assign, readonly) DARefreshPlacement placement;

@property (nonatomic, weak) UIScrollView *attachedScrollView;
@property (nonatomic, strong, readonly) DARefreshView *refreshView;	// available after set attachedScrollView
- (void)layoutRefreshViewInAttachedScrollView:(UIEdgeInsets)attachedScrollViewInsets;
- (UIEdgeInsets)getAdditionalInsetsForAttachedScrollViewInsets:(UIEdgeInsets)attachedScrollViewInsets;

@property (nonatomic, weak) id <DARefreshControllerDelegate> refreshControllerDelegate;

@end


@protocol DARefreshControllerDelegate

- (void)refreshControllerDidModifyAdditionalInsets:(DARefreshController*)refreshController;

@end
