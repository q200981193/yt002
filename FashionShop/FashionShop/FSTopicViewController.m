//
//  FSTopicViewController.m
//  FashionShop
//
//  Created by HeQingshan on 13-1-25.
//  Copyright (c) 2013年 Fashion. All rights reserved.
//

#import "FSTopicViewController.h"
#import "FSTopicListCell.h"
#import "FSTopicRequest.h"
#import "FSModelManager.h"
#import "FSResource.h"
#import "FSPagedTopic.h"
#import "FSTopic.h"
#import "FSProductListViewController.h"
#import "FSContentViewController.h"
#import "EGOPhotoViewController.h"
#import "MyPhoto.h"
#import "MyPhotoSource.h"

#define TOPIC_LIST_CELL @"FSTopicListCell"

@interface FSTopicViewController ()
{
    NSMutableArray *_topicList;
    int _currentPage;
    bool _noMoreResult;
    
    UIActivityIndicatorView * moreIndicator;
    BOOL _isInLoading;
    BOOL _firstTimeLoadDone;
    
    NSDate *_refreshLatestDate;
    NSDate * _firstLoadDate;
    int selIndex;
}

@end

@implementation FSTopicViewController
@synthesize tbAction;

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
    
    [self prepareData];
    [self prepareLayout];
    
    tbAction.backgroundView = nil;
    tbAction.backgroundColor = APP_TABLE_BG_COLOR;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!_topicList || _topicList.count <= 0) {
        
    }
}

-(void) prepareData
{
    if (!_topicList)
    {
        _topicList = [@[] mutableCopy];
        [self zeroMemoryBlock];
        [self beginLoading:tbAction];
        _currentPage = 0;
        FSTopicRequest *request =
        [self buildListRequest:RK_REQUEST_TOPIC_LIST nextPage:1 isRefresh:FALSE];
        _isInLoading = YES;
        [request send:[FSPagedTopic class] withRequest:request completeCallBack:^(FSEntityBase *resp) {
            [self endLoading:tbAction];
            if (resp.isSuccess)
            {
                FSPagedTopic *result = resp.responseData;
                if (result.totalPageCount <= _currentPage+1)
                    _noMoreResult = TRUE;
                [_topicList removeAllObjects];
                [self fillProdInMemory:result.items isInsert:FALSE];
            }
            else
            {
                [self reportError:resp.errorDescrip];
            }
            _isInLoading = NO;
        }];
    }
}

-(void) zeroMemoryBlock
{
    _currentPage = 0;
    _noMoreResult= NO;
    _isInLoading = NO;
}

-(FSTopicRequest *)buildListRequest:(NSString *)route nextPage:(int)page isRefresh:(BOOL)isRefresh
{
    FSTopicRequest *request = [[FSTopicRequest alloc] init];
    request.nextPage = page;
    request.pageSize = COMMON_PAGE_SIZE;
    request.routeResourcePath = RK_REQUEST_TOPIC_LIST;
    return request;
}

-(void) fillProdInMemory:(NSArray *)prods isInsert:(BOOL)isinserted
{
    if (!prods)
        return;
    [prods enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        int index = [_topicList indexOfObjectPassingTest:^BOOL(id obj1, NSUInteger idx1, BOOL *stop1) {
            if ([(FSTopic *)obj1 topicId] == [(FSTopic *)obj topicId])
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
                [_topicList addObject:obj];
            } else
            {
                [_topicList insertObject:obj atIndex:0];
            }
        }
    }];
    if (_topicList.count<1)
    {
        //加载空视图
        [self showNoResultImage:tbAction withImage:@"blank_specialtopic.png" withText:NSLocalizedString(@"TipInfo_Topic_List", nil)  originOffset:30];
    }
    else
    {
        [self hideNoResultImage:tbAction];
    }
    [tbAction reloadData];
}

-(void) prepareLayout
{
    [self.tbAction registerNib:[UINib nibWithNibName:@"FSTopicListCell" bundle:nil] forCellReuseIdentifier:TOPIC_LIST_CELL];
    self.tbAction.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tbAction.backgroundColor = APP_BACKGROUND_COLOR;
    
    self.navigationItem.title = NSLocalizedString(@"Topics", nil);
    [self prepareRefreshLayout:tbAction withRefreshAction:^(dispatch_block_t action) {
        [self refreshContent:TRUE withCallback:^(){
            action();
        }];
        
    }];
    
    tbAction.delegate = self;
    tbAction.dataSource = self;
}

-(void)refreshContent:(BOOL)isRefresh withCallback:(dispatch_block_t)callback
{
    int nextPage = 1;
    if (!isRefresh)
    {
        _currentPage++;
        nextPage = _currentPage + 1;
    }
    else {
        [self zeroMemoryBlock];
    }
    FSTopicRequest *request = [self buildListRequest:RK_REQUEST_TOPIC_LIST nextPage:nextPage isRefresh:isRefresh];
    _isInLoading = YES;
    [request send:[FSPagedTopic class] withRequest:request completeCallBack:^(FSEntityBase *response) {
        callback();
        if (response.isSuccess)
        {
            FSPagedTopic *result = response.responseData;
            if (isRefresh) {
                _refreshLatestDate = [[NSDate alloc] init];
                [_topicList removeAllObjects];
            }
            else
            {
                if (result.totalPageCount <= _currentPage+1)
                    _noMoreResult = TRUE;
            }
            [self fillProdInMemory:result.items isInsert:NO];
        }
        else
        {
            [self reportError:response.errorDescrip];
        }
        _isInLoading = NO;
    }];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    if(!_noMoreResult
       && !_isInLoading
       && (scrollView.contentOffset.y+scrollView.frame.size.height) + 100 > scrollView.contentSize.height
       &&scrollView.contentOffset.y>0)
    {
        [self loadMore];
    }
}

-(void)loadMore{
    if (_isInLoading)
        return;
    __block FSTopicViewController *blockSelf = self;
    [self beginLoadMoreLayout:tbAction];
    _isInLoading = YES;
    [self refreshContent:NO withCallback:^{
        [blockSelf endLoadMore:blockSelf.tbAction];
        _isInLoading = NO;
    }];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > _topicList.count) {
        return 0;
    }
    FSTopic *topic = [_topicList objectAtIndex:indexPath.row];
    if (topic.resources.count <= 0) {
        return 0;
    }
    FSResource * source = [topic.resources objectAtIndex:0];
    if (source.width <= 0.0000001) {
        return 0;
    }
    return source.height*314/source.width + 6;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSTopic *topic = [_topicList objectAtIndex:indexPath.row];
    switch ([topic.targetType intValue]) {
        case SkipTypeDefault:
        case SkipTypeProductList:
        {
            FSProductListViewController *dr = [[FSProductListViewController alloc] initWithNibName:@"FSProductListViewController" bundle:nil];
            dr.topic = topic;
            dr.pageType = FSPageTypeTopic;
            [self.navigationController pushViewController:dr animated:TRUE];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
            break;
        case SkipTypePromotionDetail:
        {
            FSProDetailViewController *detailView = [[FSProDetailViewController alloc] initWithNibName:@"FSProDetailViewController" bundle:nil];
            FSProdItemEntity *item = [[FSProdItemEntity alloc] init];
            item.id = [topic.targetId intValue];
            detailView.navContext = [[NSMutableArray alloc] initWithObjects:item, nil];
            detailView.sourceType = FSSourcePromotion;
            detailView.indexInContext = 0;
            detailView.dataProviderInContext = self;
            UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController:detailView];
            [self presentViewController:navControl animated:true completion:nil];
        }
            break;
        case SkipTypeProductDetail:
        {
            FSProDetailViewController *detailView = [[FSProDetailViewController alloc] initWithNibName:@"FSProDetailViewController" bundle:nil];
            FSProItemEntity *item = [[FSProItemEntity alloc] init];
            item.id = [topic.targetId intValue];
            detailView.navContext = [[NSMutableArray alloc] initWithObjects:item, nil];
            detailView.sourceType = FSSourceProduct;
            detailView.indexInContext = 0;
            detailView.dataProviderInContext = self;
            UINavigationController *navControl = [[UINavigationController alloc] initWithRootViewController:detailView];
            [self presentViewController:navControl animated:true completion:nil];
        }
            break;
        case SkipTypeURL:
        {
            FSContentViewController *controller = [[FSContentViewController alloc] init];
            controller.fileName = topic.targetId;
            controller.title = topic.name;
            [self.navigationController pushViewController:controller animated:YES];
        }
            break;
        case SkipTypeNone:
        {
            //弹出大图进行展现
            selIndex = indexPath.row;
            NSMutableArray *photoArray=[NSMutableArray arrayWithCapacity:1];
            for(FSResource *res in topic.resources)
            {
                if (res.type == 2) {
                    continue;
                }
                MyPhoto *photo = [[MyPhoto alloc] initWithImageURL:[res absoluteUr:315] name:nil];
                [photoArray addObject:photo];
            }
            MyPhotoSource *source = [[MyPhotoSource alloc] initWithPhotos:photoArray];
            EGOPhotoViewController *photoController = [[EGOPhotoViewController alloc] initWithPhotoSource:source];
            int width = 100;
            photoController.beginRect = CGRectMake((APP_WIDTH-width)/2, (APP_HIGH-width)/2, width, width);
            photoController.source = self;
            [self presentModalViewController:photoController animated:YES];
        }
            break;
        default:
            break;
    }
}

#pragma UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_topicList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= _topicList.count) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    if (indexPath.row > _topicList.count) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    FSTopic *topic = [_topicList objectAtIndex:indexPath.row];
    if (topic.resources.count <= 0) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    FSResource * source = [topic.resources objectAtIndex:0];
    if (source.width <= 0.0000001) {
        return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    }
    FSTopicListCell *cell = [self.tbAction dequeueReusableCellWithIdentifier:TOPIC_LIST_CELL];
    [cell setData:_topicList[indexPath.row]];
    cell.content.frame = CGRectMake(3, 3, 314, source.height*315/source.width - 6);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.content.layer.cornerRadius = 10;
    cell.content.layer.borderWidth = 1;
    cell.content.layer.borderColor = RGBACOLOR(0xee, 0xee, 0xee, 1).CGColor;
    return cell;
}

#pragma mark - FSProDetailItemSourceProvider
/*
-(void)proDetailViewDataFromContext:(FSProDetailViewController *)view forIndex:(NSInteger)index  completeCallback:(UICallBackWith1Param)block errorCallback:(dispatch_block_t)errorBlock
{
    if (view.sourceType == FSSourcePromotion) {
        FSProItemEntity *item =  [view.navContext objectAtIndex:index];
        if (item)
            block(item);
        else
            errorBlock();
    }
    else if (view.sourceType == FSSourceProduct) {
        FSProdItemEntity *item =  [view.navContext objectAtIndex:index];
        if (item)
            block(item);
        else
            errorBlock();
    }
}
 */
-(FSSourceType)proDetailViewSourceTypeFromContext:(FSProDetailViewController *)view forIndex:(NSInteger)index
{
    return view.sourceType;
}

-(BOOL)proDetailViewNeedRefreshFromContext:(FSProDetailViewController *)view forIndex:(NSInteger)index
{
    return TRUE;
}

- (void)viewDidUnload {
    [self setTbAction:nil];
    [super viewDidUnload];
}

#pragma mark - FSImageSlide datasource

-(int)numberOfImagesInSlides:(EGOPhotoViewController *)view
{
    return 1;
}

-(NSURL *)imageSlide:(EGOPhotoViewController *)view imageNameForIndex:(int)index
{
    FSTopic *item = _topicList[selIndex];
    return [[item.resources objectAtIndex:index] absoluteUrl320];
}

@end
