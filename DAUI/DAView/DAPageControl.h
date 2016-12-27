//
//  DAPageControl.h
//  daui
//
//  Created by da on 29.05.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface DAPageControl : UIControl
{
	NSUInteger _numberOfPages;
	NSUInteger _currentPage;

	UIImage *_pageImage;
	UIImage *_currentPageImage;
	
	unsigned int _hidesForSinglePage : 1;
	unsigned int _customPageImage : 1;
	unsigned int _customCurrentPageImage : 1;
}

@property (nonatomic, assign) NSUInteger numberOfPages;
@property (nonatomic, assign) NSUInteger currentPage;
- (void)setCurrentPage:(NSUInteger)currentPage animated:(BOOL)animated;
@property (nonatomic, assign, getter = isHideForSinglePage) BOOL hidesForSinglePage;

@property (nonatomic, strong) UIImage *pageImage;
@property (nonatomic, strong) UIImage *currentPageImage;
@property (nonatomic, assign) CGSize pageSize;

@end
