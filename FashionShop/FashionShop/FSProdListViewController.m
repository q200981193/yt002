//
//  FSProdListViewController.m
//  FashionShop
//
//  Created by gong yi on 12/10/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#import "FSProdListViewController.h"
#import "UIViewController+Loading.h"
#import "FSProdDetailCell.h"
#import "FSProdTagCell.h"
#import "FSProDetailViewController.h"

#import "FSTag.h"
#import "FSCoreTag.h"
#import "FSProListRequest.h"
#import "FSResource.h"
#import "FSLocationManager.h"
#import "FSBothItems.h"
#import "FSModelManager.h"
#import "FSConfigListRequest.h"

#define  PROD_LIST_TAG_CELL @"FSProdListTagCell"
#define PROD_LIST_DETAIL_CELL @"FSProdListDetailCell"
#define  PROD_LIST_DETAIL_CELL_WIDTH 100
#define LOADINGVIEW_HEIGHT 44
#define ITEM_CELL_WIDTH 100
#define DEFAULT_TAG_WIDTH 50

#define PROD_PAGE_SIZE 10

@interface FSProdListViewController ()
{
    NSMutableArray *_tags;
    NSMutableArray *_prods;
    
    UIActivityIndicatorView * moreIndicator;
    BOOL _isInLoading;
    BOOL _firstTimeLoadDone;
    int _selectedTagIndex;
    int _prodPageIndex;
    CGFloat _actualTagWidth;
    
    NSDate *_refreshLatestDate;
    NSDate * _firstLoadDate;
    FSCoreTag * _currentTag;
    
    bool _noMoreResult;
}

@end

@implementation FSProdListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self prepareLayout];
    [self prepareData];

}

-(void)viewDidAppear:(BOOL)animated
{
    if (!_firstTimeLoadDone)
    {
        if (_tags.count>0)
        {

            [_cvTags selectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:TRUE scrollPosition:PSTCollectionViewScrollPositionCenteredHorizontally];
            [self collectionView:_cvTags didSelectItemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            [self resetTagFrameIfNeed];
            _firstTimeLoadDone  = true;
        } else
        {
            //urge tag reload again
            [[FSModelManager sharedModelManager] forceReloadTags];
            [self prepareData];
        }
    }
}

-(void) prepareData
{
    _tags = [@[] mutableCopy];
    _prods = [@[] mutableCopy];
     _actualTagWidth = 0;
    [self zeroMemoryBlock];
    [_tags addObjectsFromArray:[FSTag localTags]];
    if (!_tags ||
        _tags.count<1)
    {
        [self beginLoading:_cvTags];
        __block FSProdListViewController *blockSelf = self;
        FSConfigListRequest *request = [[FSConfigListRequest alloc] init];
        request.routeResourcePath = RK_REQUEST_CONFIG_TAG_ALL;
        [request send:[FSCoreTag class] withRequest:request completeCallBack:^(FSEntityBase *resp) {
            [blockSelf endLoading:_cvTags];
            [_tags addObjectsFromArray:[FSTag localTags]];
            [blockSelf endPrepareData];
        }];
    } else
    {
        [self endPrepareData];
    }
   
}
-(void)endPrepareData
{
    if (!_tags ||
        _tags.count<1)
        return;

}
-(void) zeroMemoryBlock
{
    _prodPageIndex = 0;
    _noMoreResult= FALSE;
   
 
}

-(void)resetTagFrameIfNeed
{
    if (_actualTagWidth+5<self.view.frame.size.width)
    {
        CGFloat offset = self.view.frame.size.width - _actualTagWidth-5;
        CGRect origiFrame = _cvTags.frame;
        origiFrame.origin.x = offset/2;
        [_cvTags setFrame:origiFrame];
    }
}
-(void) prepareLayout
{

    self.navigationItem.title = NSLocalizedString(@"Products", nil);
    [self.navigationController.navigationBar setTitleTextAttributes:@{UITextAttributeFont:ME_FONT(16),UITextAttributeTextColor:[UIColor colorWithRed:239 green:239 blue:239]}];
    PSUICollectionViewFlowLayout *layout = [[PSUICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(DEFAULT_TAG_WIDTH, 34);
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
     _cvTags = [[PSUICollectionView alloc] initWithFrame:_tagContainer.bounds collectionViewLayout:layout];
    [_tagContainer addSubview:_cvTags];
    [_cvTags registerNib:[UINib nibWithNibName:@"FSProdTagCell" bundle:nil] forCellWithReuseIdentifier:PROD_LIST_TAG_CELL];
    _cvTags.backgroundColor = [UIColor clearColor];
    _tagContainer.backgroundColor = [UIColor colorWithRed:229 green:229 blue:229];
    _tagContainer.contentMode = UIViewContentModeCenter;
    _cvTags.delegate = self;
    _cvTags.dataSource = self;
    [self reCreateContentView];
}
-(void)reCreateContentView
{
    if (_cvContent)
    {
        [_cvContent removeFromSuperview];
        _cvContent = nil;
    }
    SpringboardLayout *clayout = [[SpringboardLayout alloc] init];
    clayout.itemWidth = ITEM_CELL_WIDTH;
    clayout.columnCount = 3;
    clayout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    clayout.delegate = self;
    _cvContent = [[PSUICollectionView alloc] initWithFrame:_contentContainer.bounds collectionViewLayout:clayout];
    [_contentContainer addSubview:_cvContent];
    [_cvContent setCollectionViewLayout:clayout];
    _cvContent.backgroundColor = [UIColor whiteColor];
    [_cvContent registerNib:[UINib nibWithNibName:@"FSProdDetailCell" bundle:nil] forCellWithReuseIdentifier:PROD_LIST_DETAIL_CELL];
    [self prepareRefreshLayout:_cvContent withRefreshAction:^(dispatch_block_t action) {
        [self refreshContent:TRUE withCallback:^(){
            action();
        }];
        
    }];
    

    _cvContent.delegate = self;
    _cvContent.dataSource = self;

}

-(void) fillProdInMemory:(NSArray *)prods isInsert:(BOOL)isinserted needReload:(BOOL)shouldReload
{
    if (!prods)
        return;
    NSMutableArray *indexPathArray = [@[] mutableCopy];
    [prods enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        int index = [_prods indexOfObjectPassingTest:^BOOL(id obj1, NSUInteger idx1, BOOL *stop1) {
            if ([[(FSProdItemEntity *)obj1 valueForKey:@"id"] intValue] ==[[(FSProdItemEntity *)obj valueForKey:@"id"] intValue])
            {
                return TRUE;
                *stop1 = TRUE;
            }
            return FALSE;
        }];
        if (index==NSNotFound)
        {
            if (!isinserted)
            {
                [_prods addObject:obj];
                if (!shouldReload)
                    [_cvContent insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:_prods.count-1 inSection:0]]];
            } else
            {
                [_prods insertObject:obj atIndex:0];
                if (!shouldReload)
                [_cvContent insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:0 inSection:0]]];
            }
            
            
        }
    }];
    if (shouldReload)
      [_cvContent reloadData];
 
}

-(void) fillProdInMemory:(NSArray *)prods isInsert:(BOOL)isinserted
{    
    [self fillProdInMemory:prods isInsert:isinserted needReload:FALSE];
}


-(void)beginSwitchTag:(FSCoreTag *)tag
{
    [self zeroMemoryBlock];
    [self beginLoading:_cvContent];
    _prodPageIndex = 0;
    _currentTag = tag;
    FSProListRequest *request =
    [self buildListRequest:RK_REQUEST_PROD_LIST nextPage:1 isRefresh:FALSE];
    __block FSProdListViewController *blockSelf = self;
    [request send:[FSBothItems class] withRequest:request completeCallBack:^(FSEntityBase *resp) {
        [self endLoading:_cvContent];
        if (resp.isSuccess)
        {
            FSBothItems *result = resp.responseData;
            if (result.totalPageCount <= blockSelf->_prodPageIndex+1)
                blockSelf->_noMoreResult = TRUE;
            [blockSelf->_prods removeAllObjects];
            
            [blockSelf fillProdInMemory:result.prodItems isInsert:FALSE needReload:TRUE];
            [blockSelf->_cvContent setContentOffset:CGPointZero];
        }
        else
        {
            [self reportError:resp.errorDescrip];
        }
    }];
    
}
-(FSProListRequest *)buildListRequest:(NSString *)route nextPage:(int)page isRefresh:(BOOL)isRefresh
{
    FSProListRequest *request = [[FSProListRequest alloc] init];
    request.routeResourcePath = route;
    request.longit = [NSNumber numberWithDouble:[FSLocationManager sharedLocationManager].currentCoord.longitude];
    request.lantit = [NSNumber numberWithDouble:[FSLocationManager sharedLocationManager].currentCoord.latitude];
    if(isRefresh)
    {
        request.requestType = 0;
        request.previousLatestDate = _refreshLatestDate;
    }
    else
    {
        request.requestType = 1;
        request.previousLatestDate = _firstLoadDate;
    }

    request.tagid =[_currentTag valueForKey:@"id"];
    request.nextPage = page;
    request.pageSize = PROD_PAGE_SIZE;
    return request;
}
-(void)refreshContent:(BOOL)isRefresh withCallback:(dispatch_block_t)callback
{
    int nextPage = 1;
    if (!isRefresh)
    {
        _prodPageIndex++;
        nextPage = _prodPageIndex +1;
    }
    FSProListRequest *request = [self buildListRequest:RK_REQUEST_PROD_LIST nextPage:nextPage isRefresh:isRefresh];
    __block FSProdListViewController *blockSelf = self;
    [request send:[FSBothItems class] withRequest:request completeCallBack:^(FSEntityBase *resp) {
        callback();
        if (resp.isSuccess)
        {
            FSBothItems *result = resp.responseData;
            if (isRefresh)
                blockSelf->_refreshLatestDate = [[NSDate alloc] init];
            else
            {
                if (result.totalPageCount <= blockSelf->_prodPageIndex+1)
                   blockSelf-> _noMoreResult = TRUE;
            }
            [blockSelf fillProdInMemory:result.prodItems isInsert:isRefresh];
        }
        else
        {
            [blockSelf reportError:resp.errorDescrip];
        }
    }];

}

-(void)loadMore
{

    [self beginLoadMoreLayout:_cvContent];
    __block FSProdListViewController *blockSelf = self;
    [self refreshContent:FALSE withCallback:^{
        [blockSelf endLoadMore:_cvContent];
    }];
    
}

- (void)loadImagesForOnscreenRows
{
    if ([_prods count] > 0)
    {
        NSArray *visiblePaths = [_cvContent indexPathsForVisibleItems];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            id<ImageContainerDownloadDelegate> cell = (id<ImageContainerDownloadDelegate>)[_cvContent cellForItemAtIndexPath:indexPath];
            int width = ITEM_CELL_WIDTH;
            int height = [(PSUICollectionViewCell *)cell frame].size.height - 40;
            [cell imageContainerStartDownload:cell withObject:indexPath andCropSize:CGSizeMake(width, height) ];
            
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    
	[super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    [self loadImagesForOnscreenRows];

    if (!_noMoreResult &&
        (scrollView.contentOffset.y+scrollView.frame.size.height) > scrollView.contentSize.height
        && scrollView.contentSize.height>scrollView.frame.size.height
        &&scrollView.contentOffset.y>0)
    {
        [self loadMore];
    }

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}


#pragma mark - PSUICollectionView Datasource

- (NSInteger)collectionView:(PSUICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    if (view == _cvTags)
    {
        return _tags.count;
    } else if (view == _cvContent)
    {
        return _prods.count;
    }
    return 0;
    
}

- (NSInteger)numberOfSectionsInCollectionView: (PSUICollectionView *)collectionView {
    
    return 1;
}

- (PSUICollectionViewCell *)collectionView:(PSUICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PSUICollectionViewCell * cell = nil;
    if (cv == _cvTags)
    {
        cell = [cv dequeueReusableCellWithReuseIdentifier:PROD_LIST_TAG_CELL forIndexPath:indexPath];
        [(FSProdTagCell *)cell setData:[_tags objectAtIndex:indexPath.row]];
        cell.layer.borderColor = [UIColor colorWithRed:206 green:206 blue:206].CGColor;
        cell.layer.borderWidth = 1;
    } else if (cv == _cvContent)
    {
        cell = [cv dequeueReusableCellWithReuseIdentifier:PROD_LIST_DETAIL_CELL forIndexPath:indexPath];
        [(FSProdDetailCell *)cell setData:[_prods objectAtIndex:indexPath.row]];
        cell.layer.borderColor = [UIColor grayColor].CGColor;
        cell.layer.borderWidth = 1;
        if (_cvContent.dragging == NO &&
            _cvContent.decelerating == NO)
        {
            int width = PROD_LIST_DETAIL_CELL_WIDTH;
            int height = cell.frame.size.height;
            [(id<ImageContainerDownloadDelegate>)cell imageContainerStartDownload:cell withObject:indexPath andCropSize:CGSizeMake(width, height) ];
        }
    }
    return cell;
}




#pragma mark - PSUICollectionViewDelegate


- (void)collectionView:(PSUICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(collectionView == _cvTags)
    {
        [[collectionView cellForItemAtIndexPath:indexPath] setSelected:TRUE];
        [collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:TRUE];
        [self beginSwitchTag:[_tags objectAtIndex:indexPath.row]];
    }
    else if (collectionView == _cvContent)
    {
        FSProDetailViewController *detailViewController = [[FSProDetailViewController alloc] initWithNibName:@"FSProDetailViewController" bundle:nil];
        detailViewController.navContext = _prods;
        detailViewController.dataProviderInContext = self;
        detailViewController.indexInContext = indexPath.row;
        detailViewController.sourceType = FSSourceProduct;
        UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController:detailViewController];
        [self presentViewController:navControl animated:YES completion:nil];
    }

}

-(void)collectionView:(PSUICollectionView *)collectionView didEndDisplayingCell:(PSUICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (collectionView == _cvContent)
    {
        [(FSProdDetailCell *)cell willRemoveFromView];
    }
     
}
-(CGSize)collectionView:(PSTCollectionView *)collectionView layout:(PSTCollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (collectionView == _cvTags &&
        _tags)
    {
        CGSize actualSize = [[(FSTag *)[_tags objectAtIndex:indexPath.row] name] sizeWithFont:ME_FONT(12)];
        CGFloat width = MAX(actualSize.width, DEFAULT_TAG_WIDTH);
        _actualTagWidth+=width+5;
        return CGSizeMake(width, MAX(actualSize.height, 34));
    }
    return  CGSizeMake(ITEM_CELL_WIDTH, ITEM_CELL_WIDTH);
}

- (CGFloat)collectionView:(PSUICollectionView *)collectionView
                   layout:(SpringboardLayout *)collectionViewLayout
 heightForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FSProdItemEntity * data = [_prods objectAtIndex:indexPath.row];
    FSResource * resource = data.resource&&data.resource.count>0?[data.resource objectAtIndex:0]:nil;
    float totalHeight = 0.1f;
    if (resource)
    {
        int cellWidth = ITEM_CELL_WIDTH;
        float imgHeight = (cellWidth * resource.height)/(resource.width);
        totalHeight = totalHeight+imgHeight;
    } else
    {
        totalHeight = 20.0f;
    }
    return totalHeight;
}



#pragma FSProDetailItemSourceProvider
-(void)proDetailViewDataFromContext:(FSProDetailViewController *)view forIndex:(NSInteger)index  completeCallback:(UICallBackWith1Param)block errorCallback:(dispatch_block_t)errorBlock
{
    FSProdItemEntity *item =  [view.navContext objectAtIndex:index];
    if (item)
        block(item);
    else
        errorBlock();
    
}
-(FSSourceType)proDetailViewSourceTypeFromContext:(FSProDetailViewController *)view forIndex:(NSInteger)index
{
    return FSSourceProduct;
}
-(BOOL)proDetailViewNeedRefreshFromContext:(FSProDetailViewController *)view forIndex:(NSInteger)index
{
    return TRUE;
}

- (BOOL) isDeletionModeActiveForCollectionView:(PSUICollectionView *)collectionView layout:(PSUICollectionViewLayout*)collectionViewLayout
{
    return FALSE;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTagContainer:nil];
    [self setContentContainer:nil];
    [self setLblTitle:nil];
    [super viewDidUnload];
}
@end
