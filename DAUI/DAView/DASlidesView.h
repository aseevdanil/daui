//
//  DASlidesView.h
//  daui
//
//  Created by da on 22.05.12.
//  Copyright (c) 2012 Aseev Danil. All rights reserved.
//

#import <UIKit/UIKit.h>



@protocol DASlidesViewDataSource, DASlidesViewDelegate;

@interface DASlidesView : UIView
{
	UIView *_backgroundView;
	UIScrollView *_scrollView;
	
	NSMutableArray *_slides;
	NSUInteger _currentSlideIndex;
	
	NSMutableIndexSet *_updatesReloadSlidesIndexes;
	NSMutableIndexSet *_updatesDeleteSlidesIndexes;
	NSMutableIndexSet *_updatesInsertSlidesIndexes;
	
	NSMutableSet *_reusableSlides;
	NSUInteger _reusableSlidesCount;
	NSUInteger _numberOfPreloadedNeighborsSlides;
	
	id <DASlidesViewDelegate> __weak _slidesViewDelegate;
	id <DASlidesViewDataSource> __weak _slidesViewDataSource;
	
	struct
	{
		unsigned int batchUpdates : 1;
		unsigned int updatesReloadData : 1;
		unsigned int selfScrolling : 1;
	}
	_slidesViewFlags;
}

@property (nonatomic, assign, readonly) NSUInteger numberOfSlides;
- (UIView*)slideAtIndex:(NSUInteger)index;

@property (nonatomic, assign) NSUInteger currentSlideIndex;
- (void)setCurrentSlideIndex:(NSUInteger)index animated:(BOOL)animated;

- (void)reloadData;
- (void)reloadSlidesAtIndexes:(NSIndexSet*)indexes;
- (void)deleteSlidesAtIndexes:(NSIndexSet*)indexes;
- (void)insertSlidesAtIndexes:(NSIndexSet*)indexes;
- (void)beginUpdates;	// Пакетное обновление. Каждому вызову beginUpdates должен соответствовать вызов endUpdates в том же цикле очереди операций.
- (void)endUpdates;		// Внутри вызовов beginUpdates/endUpdates можно вызывать insertSlidesAtIndexes:, deleteSlidesAtIndexes:, reloadSlidesAtIndexes: и reloadData.
						// Вложенные вызовы beginUpdates/endUpdates не допускаются.
						// Порядок обработки вызовов фунций при пакетном обновлении соответствует таковому для UITableView,
						// т.е. сначала обрабатываются reloadSlidesAtIndexes:, затем deleteSlidesAtIndexes: затем insertSlidesAtIndexes:,

- (UIView*)dequeueReusableSlideWithIdentifier:(NSString*)identifier;
@property (nonatomic, assign) NSUInteger reusableSlidesCount;	// may be 0, if reusableSlidesCount == NSNotFound - unlimited
@property (nonatomic, assign) NSUInteger numberOfPreloadedNeighborsSlides; // if numberOfPreloadedNeighborsSlides == NSNotFound - preload all slides

@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *backgroundView;

@property (nonatomic, weak) id <DASlidesViewDelegate> slidesViewDelegate;
@property (nonatomic, weak) id <DASlidesViewDataSource> slidesViewDataSource;

@end


@protocol DASlidesViewDataSource <NSObject>

@required

// Configuring a Slides View
- (NSUInteger)slidesViewNumberOfSlides:(DASlidesView*)slidesView;
- (UIView*)slidesView:(DASlidesView*)slidesView slideAtIndex:(NSUInteger)index;

@end


@protocol DASlidesViewDelegate <NSObject>

@optional

// Configuring Slides for the Slides View
- (UIEdgeInsets)slidesView:(DASlidesView*)slidesView insetsForSlideAtIndex:(NSUInteger)index;

// Sliding process
- (void)slidesViewWillBeginSliding:(DASlidesView*)slidesView;
- (void)slidesViewDidEndSliding:(DASlidesView*)slidesView;
- (void)slidesView:(DASlidesView*)slidesView didChangeCurrentSlideFromIndex:(NSUInteger)fromCurrentSlideIndex toIndex:(NSUInteger)toCurrentSlideIndex;

@end


@interface UIView (DASlidesView)

@property (nonatomic, copy) NSString *slideReuseIdentifier;

@end
