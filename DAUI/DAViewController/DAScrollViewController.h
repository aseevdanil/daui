//
//  DAScrollViewController.h
//  daui
//
//  Created by da on 03.04.14.
//  Copyright (c) 2014 Aseev Danil. All rights reserved.
//

#import "DAViewController.h"



@interface DAScrollViewController : DAViewController
{
	UIScrollView *_scrollView;
	
	DARefreshController *_refreshController[DARefreshPlacementCount];

	UIEdgeInsets _manualScrollViewInset;
	
	unsigned int _updatingScrollViewInset : 1;
}

- (void)loadScrollView;
@property (nonatomic, strong) UIScrollView *scrollView;
- (void)didLayoutScrollView;
- (CGRect)scrollViewFrameForAnchorBounds:(CGRect)anchorBounds;
- (void)scrollViewInsetsChanged;

@property (nonatomic, strong) DARefreshItem *topRefreshItem;
@property (nonatomic, strong) DARefreshItem *leftRefreshItem;
@property (nonatomic, strong) DARefreshItem *bottomRefreshItem;
@property (nonatomic, strong) DARefreshItem *rightRefreshItem;

@end
