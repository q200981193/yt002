//
//  FSProDetailViewController.m
//  FashionShop
//
//  Created by gong yi on 11/20/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#import "FSProDetailViewController.h"
#import "UIImageView+WebCache.h"
#import "FSModelManager.h"
#import "FSMeViewController.h"
#import "MBProgressHUD.h"
#import "FSProDetailView.h"
#import "FSProdDetailView.h"
#import "FSProCommentCell.h"
#import "FSProCommentInputView.h"
#import "TPKeyboardAvoidingScrollView.h"
#import "FSDRViewController.h"
#import "FSProCommentHeader.h"
#import "FSBrandItemsViewController.h"
#import "FSStoreDetailViewController.h"
#import "FSSearchViewController.h"

#import "FSCouponRequest.h"
#import "FSFavorRequest.h"
#import "FSUser.h"
#import "FSCoupon.H"
#import "FSCommonProRequest.h"
#import "FSCommonCommentRequest.h"
#import "FSLocationManager.h"

#import "FSShareView.h"
#import "AWActionSheet.h"
#import "UIBarButtonItem+Title.h"
#import "UIViewController+Loading.h"
#import <PassKit/PassKit.h>
#import "NSData+Base64.h"

#define PRO_DETAIL_COMMENT_INPUT_TAG 200
#define TOOLBAR_HEIGHT 44
#define PRO_DETAIL_COMMENT_INPUT_HEIGHT 45
#define PRO_DETAIL_COMMENT_CELL_HEIGHT 73
#define PRO_DETAIL_COMMENT_HEADER_HEIGHT 30
@interface FSProDetailViewController ()
{
    MBProgressHUD *statusReport;
    id proItem;
    int currentPageIndex;
}

@end

@implementation FSProDetailViewController
@synthesize dataProviderInContext,navContext,indexInContext;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self beginPrepareData];
    
   
    
}
-(void) beginPrepareData
{
    [self doBinding:nil];

}


-(void) onButtonCancel
{
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
}

-(void) doBinding:(FSProItemEntity *)source
{
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackOpaque];

    UIBarButtonItem *baritemCancel = [self createPlainBarButtonItem:@"goback_icon.png" target:self action:@selector(onButtonCancel)];
    UIBarButtonItem *baritemShare = [self createPlainBarButtonItem:@"share_icon.png" target:self action:@selector(doShare:)];
    [self.navigationItem setLeftBarButtonItem:baritemCancel];
    [self.navigationItem setRightBarButtonItem:baritemShare];
    currentPageIndex = -1;
    [self.paginatorView reloadData];
    self.currentPageIndex = indexInContext;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    //[self resetScrollViewSize:self.paginatorView.currentPage];
}

-(id)itemSource
{
    return [(id)self.paginatorView.currentPage data];
}

#pragma mark - SYPaginatorViewDataSource

- (NSInteger)numberOfPagesForPaginatorView:(SYPaginatorView *)paginatorView {
	return navContext.count;
}

- (SYPageView *)paginatorView:(SYPaginatorView *)paginatorView viewForPageAtIndex:(NSInteger)pageIndex {
    NSString *identifier = NSStringFromClass([FSProDetailView class]);
    FSSourceType source = [dataProviderInContext proDetailViewSourceTypeFromContext:self forIndex:pageIndex];
	if (source == FSSourceProduct)
        identifier = NSStringFromClass([FSProdDetailView class]);
	FSDetailBaseView * view = [paginatorView dequeueReusablePageWithIdentifier:identifier];
	if (!view) {
        if (source == FSSourcePromotion)
            view = [[[NSBundle mainBundle] loadNibNamed:@"FSProDetailView" owner:self options:nil] lastObject];
        else
            view = [[[NSBundle mainBundle] loadNibNamed:@"FSProdDetailView" owner:self options:nil] lastObject];
    }
    [view setPType:source];

    if ([view respondsToSelector:@selector(imgThumb)])
    {
        [(FSThumView *)[(id)view imgThumb] setDelegate:self];
    }
    if ([view respondsToSelector:@selector(imgView)])
    {
        UIImageView *prodImage = (UIImageView *)[(id)view imgView];
        [prodImage setUserInteractionEnabled:TRUE];
        UITapGestureRecognizer *imgTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapProImage:)];
        [prodImage addGestureRecognizer:imgTap];
    }
    if ([view respondsToSelector:@selector(btnTag)])
    {
        UIButton *tagButton = (UIButton *)[(id)view btnTag];
        [tagButton addTarget:self action:@selector(goTag:) forControlEvents:UIControlEventTouchUpInside];
    }
    [[(id)view tbComment] registerNib:[UINib nibWithNibName:@"FSProCommentCell" bundle:nil] forCellReuseIdentifier:@"commentCell"];
    
    [(id)view svContent].delegate = self;
    [(id)view tbComment].delegate = self;
    [(id)view tbComment].dataSource = self;
    [(id)view tbComment].scrollEnabled = FALSE;
    [(id)view svContent].scrollEnabled = TRUE;
    view.showViewMask = TRUE;
	return view;
}

-(void) resetScrollViewSize:(FSDetailBaseView *)view
{
    
    [view resetScrollViewSize];
}

- (void)paginatorView:(SYPaginatorView *)paginatorView didScrollToPageAtIndex:(NSInteger)pageIndex
{
    if (currentPageIndex== pageIndex)
        return;
    currentPageIndex= pageIndex;
    __block FSDetailBaseView * blockViewForRefresh = paginatorView.currentPage;
    __block FSProDetailViewController *blockSelf = self;
    _sourceType = blockViewForRefresh.pType;
   
    if ([dataProviderInContext respondsToSelector:@selector(proDetailViewNeedRefreshFromContext:forIndex:)] &&
        [dataProviderInContext proDetailViewNeedRefreshFromContext:self forIndex:pageIndex]==TRUE)
    {
        NSNumber * itemId = [[navContext objectAtIndex:pageIndex] valueForKey:@"id"];
        FSCommonProRequest *drequest = [[FSCommonProRequest alloc] init];
        drequest.uToken = [FSModelManager sharedModelManager].loginToken;
        drequest.routeResourcePath = RK_REQUEST_PRO_DETAIL;
        drequest.id = itemId;
        drequest.longit =[NSNumber numberWithFloat:[FSLocationManager sharedLocationManager].currentCoord.longitude];
        drequest.lantit = [NSNumber numberWithFloat:[FSLocationManager sharedLocationManager].currentCoord.latitude];
        drequest.pType= blockViewForRefresh.pType;
        Class respClass;
        if (drequest.pType == FSSourceProduct)
        {
            drequest.routeResourcePath = RK_REQUEST_PROD_DETAIL;
            respClass = [FSProdItemEntity class];
        }
        else
        {
            drequest.routeResourcePath = RK_REQUEST_PRO_DETAIL;
            respClass = [FSProItemEntity class];
            
        }
        [drequest send:respClass withRequest:drequest completeCallBack:^(FSEntityBase *resp) {
            if (resp.isSuccess)
            {
                [blockViewForRefresh setData:resp.responseData];
                NSString *navTitle = [blockViewForRefresh.data valueForKey:@"title"];
                if (blockSelf->_sourceType==FSSourcePromotion)
                    navTitle = NSLocalizedString(@"promotion detail", nil);
                [blockSelf.navigationItem setTitle:navTitle] ;
                blockViewForRefresh.showViewMask= FALSE;
                [blockSelf delayLoadComments:[blockViewForRefresh.data valueForKey:@"id"]];
            } else
            {
                [self onButtonCancel];
            }
            
        }];

    } else
    {
        [dataProviderInContext proDetailViewDataFromContext:self forIndex:pageIndex completeCallback:^(id input){
            [blockViewForRefresh setData:input];
            blockViewForRefresh.showViewMask= FALSE;
            NSString *navTitle = [blockViewForRefresh.data valueForKey:@"title"];
            if (blockSelf->_sourceType==FSSourcePromotion)
                navTitle = NSLocalizedString(@"promotion detail", nil);
            [blockSelf.navigationItem setTitle:navTitle] ;
            [blockSelf delayLoadComments:[blockViewForRefresh.data valueForKey:@"id"]];
            
        } errorCallback:^{
            [self onButtonCancel];
        }];
 
    }
  [self hideCommentInputView:nil];
}

-(void)delayLoadComments:(NSNumber *)proId
{
    __block FSDetailBaseView * blockViewForRefresh = self.paginatorView.currentPage;
    if (!blockViewForRefresh)
        return;
    FSCommonCommentRequest * request=[[FSCommonCommentRequest alloc] init];
    request.routeResourcePath = RK_REQUEST_COMMENT_LIST;
    request.sourceid = proId;
    request.sourceType =[NSNumber numberWithInt:blockViewForRefresh.pType];//promotion
    request.nextPage = @1;
    request.pageSize = @100;
    request.refreshTime = [[NSDate alloc] init];
    request.rootKeyPath = @"data.comments";
    [request send:[FSComment class] withRequest:request completeCallBack:^(FSEntityBase *resp) {
        if (resp.isSuccess)
        {
            [[blockViewForRefresh data] setComments:resp.responseData];
            if (blockViewForRefresh)
                [[(id)blockViewForRefresh tbComment] reloadData];
            
        }
        else
        {
            NSLog(@"comment list failed");
        }
        
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
}

-(Class)convertSourceTypeToClass:(FSSourceType)pType
{
    switch (pType) {
        case FSSourceProduct:
            return [FSProdItemEntity class];
        case  FSSourcePromotion:
            return [FSProItemEntity class];
            
        default:
            break;
    }
    return nil;
}

-(void) internalGetCoupon:(dispatch_block_t) cleanup
{
    FSCouponRequest *request = [[FSCouponRequest alloc] init];
    request.userToken = [FSModelManager sharedModelManager].loginToken;
    request.productId = [[self.itemSource valueForKey:@"id"] intValue];
    request.productType = _sourceType ;
    request.includePass = [PKPass class]?TRUE:FALSE;
    request.rootKeyPath = @"data.coupon";
    
    __block FSProDetailViewController *blockSelf = self;
    [request send:[FSCoupon class] withRequest:request completeCallBack:^(FSEntityBase *respData){
        if(!respData.isSuccess)
        {
            [blockSelf updateProgress:respData.errorDescrip];
            if (cleanup)
                cleanup();
        }
        else
        {
            FSCoupon *coupon = respData.responseData;
            FSDetailBaseView *view = blockSelf.paginatorView.currentPage;
            if ([view.data isKindOfClass:[FSProdItemEntity class]])
            {
                ((FSProdItemEntity *)view.data).couponTotal ++;
            } else if ([view.data isKindOfClass:[FSProItemEntity class]])
            {
                 ((FSProItemEntity *)view.data).couponTotal ++;
            }
            FSUser *localUser = (FSUser *)[FSUser localProfile];
            localUser.couponsTotal ++;
            //add pass to passbook
            if (coupon.pass &&
                [PKPass class])
            {
                NSError *error = nil;
                NSString *passByte = coupon.pass;
                 PKPass *pass = [[PKPass alloc] initWithData:[NSData dataFromBase64String:passByte] error:&error];
                if (pass)
                {
                    PKAddPassesViewController *passController = [[PKAddPassesViewController alloc] initWithPass:pass];
                    [self presentViewController:passController animated:TRUE completion:nil];
                }
            }
            [blockSelf updateProgressThenEnd:NSLocalizedString(@"coupon use instruction",nil) withDuration:2];
        }

    }];
}

-(void) internalDoFavor:(UIBarButtonItem *)button
{
    
    FSFavorRequest *request = [[FSFavorRequest alloc] init];
    request.userToken = [FSModelManager sharedModelManager].loginToken;
    request.productId = [self.itemSource valueForKey:@"id"];
    request.productType = _sourceType ;
    __block BOOL favored = [[self.itemSource valueForKey:@"isFavored"] boolValue];
    if (favored)
    {
        request.routeResourcePath = _sourceType==FSSourceProduct?RK_REQUEST_FAVOR_PROD_REMOVE:RK_REQUEST_FAVOR_PRO_REMOVE;
    }
    FSDetailBaseView *view = self.paginatorView.currentPage;
    if ([view.data isKindOfClass:[FSProdItemEntity class]])
    {
        ((FSProdItemEntity *)view.data).isFavored = !favored;
    } else if ([view.data isKindOfClass:[FSProItemEntity class]])
    {
        ((FSProItemEntity *)view.data).isFavored = !favored;
    }

    button.enabled = false;
    __block FSProDetailViewController *blockSelf = self;
    
    [request send:[self convertSourceTypeToClass:_sourceType] withRequest:request completeCallBack:^(FSEntityBase *respData){
        if (respData.isSuccess)
        {
            
            FSDetailBaseView *view = blockSelf.paginatorView.currentPage;
            if ([view.data isKindOfClass:[FSProdItemEntity class]])
            {
                ((FSProdItemEntity *)view.data).isFavored = !favored;
                if (favored)
                    ((FSProdItemEntity *)view.data).favorTotal --;
                else
                    ((FSProdItemEntity *)view.data).favorTotal ++;
            } else if ([view.data isKindOfClass:[FSProItemEntity class]])
            {
                ((FSProItemEntity *)view.data).isFavored = !favored;
                if (favored)
                    ((FSProItemEntity *)view.data).favorTotal --;
                else
                    ((FSProItemEntity *)view.data).favorTotal ++;
            }

            if (favored &&
                [blockSelf.dataProviderInContext respondsToSelector:@selector(proDetailViewShouldPostNotification:)])
            {
                BOOL shouldPostMesg = [blockSelf.dataProviderInContext proDetailViewShouldPostNotification:blockSelf];
                if (shouldPostMesg)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:LN_FAVOR_UPDATED object:[blockSelf.navContext objectAtIndex:blockSelf.paginatorView.currentPageIndex] ];
                }
            }
        } 
        button.enabled = TRUE;
    }];
    
    
}
-(void) updateFavorButtonStatus:(UIBarButtonItem *)button canFavored:(BOOL)canfavored
{
    NSString *name = canfavored?@"bottom_nav_like_icon":@"bottom_nav_notlike_icon";
    UIImage *sheepImage = [UIImage imageNamed:name];
    if (!button.customView)
    {
        UIButton *sheepButton = [UIButton buttonWithType:UIButtonTypeCustom];
        //[sheepButton addTarget:targ action:action forControlEvents:UIControlEventTouchUpInside];
        [sheepButton setShowsTouchWhenHighlighted:YES];
        [sheepButton addTarget:self action:@selector(doFavor:) forControlEvents:UIControlEventTouchUpInside];
        button.customView = sheepButton;
    }
    UIButton *sheepButton = button.customView;
    [sheepButton setImage:sheepImage forState:UIControlStateNormal];
    [sheepButton sizeToFit];
    //button.customView = sheepButton;

}

- (IBAction)doBack:(id)sender {
    [self dismissViewControllerAnimated:FALSE completion:nil];
}

- (IBAction)doComment:(id)sender {
    id currentView =  self.paginatorView.currentPage;
    
    [(UIScrollView *)[currentView tbComment].superview scrollRectToVisible:[currentView tbComment].frame animated:TRUE];
    [self displayCommentInputView:currentView];
}

- (IBAction)doGetCoupon:(id)sender {
    bool isLogined = [[FSModelManager sharedModelManager] isLogined];
    if (!isLogined)
    {
         UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        FSMeViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"userProfile"];
        __block FSMeViewController *blockMeController = loginController;
        loginController.completeCallBack=^(BOOL isSuccess){
            
            [blockMeController dismissViewControllerAnimated:true completion:^{
                if (!isSuccess)
                {
                    [self reportError:NSLocalizedString(@"COMM_OPERATE_FAILED", nil)];
                }
                else
                {
                    [self startProgress:NSLocalizedString(@"coupon use instruction", nil) withExeBlock:^(dispatch_block_t callback){
                        [self internalGetCoupon:callback];
                    } completeCallbck:^{
                        [self endProgress];
                    }];
                }
            }];
        };
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginController];
        [self presentViewController:navController animated:true completion:nil] ;
    }
    else
    {
        [self startProgress:NSLocalizedString(@"coupon use instruction", nil) withExeBlock:^(dispatch_block_t callback){
            [self internalGetCoupon:callback];
        } completeCallbck:^{
            [self endProgress];
        }];

        
    }
    
}

- (IBAction)doShare:(id)sender {
    NSMutableArray *shareItems = [@[] mutableCopy];
    id view = self.paginatorView.currentPage;
    NSString *title = [self.itemSource valueForKey:@"title"];
    title = [NSString stringWithFormat:@"%@%@",NSLocalizedString(@"share prefix", nil),title];
    [shareItems addObject:title?title:@""];
    if ([view imgView].image != nil)
    {
        [shareItems addObject:[view imgView].image];
    }
    
    [[FSShareView instance] shareBegin:self withShareItems:shareItems  completeHander:^(NSString *activityType, BOOL completed){
        if (completed)
        {
            [self reportError:NSLocalizedString(@"COMM_OPERATE_COMPL", nil)];
        }
    }];


     
    
}

- (IBAction)showBrand:(id)sender {
    FSDetailBaseView * view = self.paginatorView.currentPage;
    FSBrand *tbrand = [view.data brand];
    FSBrandItemsViewController *dr = [[FSBrandItemsViewController alloc] initWithNibName:@"FSBrandItemsViewController" bundle:nil];
    dr.brand = tbrand;
    [self.navigationController pushViewController:dr animated:TRUE];
}

- (IBAction)goStore:(id)sender {
    FSDetailBaseView * view = self.paginatorView.currentPage;
    FSStore *store = [view.data store];
    FSStoreDetailViewController *sv = [[FSStoreDetailViewController alloc] initWithNibName:@"FSStoreDetailViewController" bundle:nil];
    sv.store =store;
    [self.navigationController pushViewController:sv animated:TRUE];
}

- (IBAction)goDR:(NSNumber *)userid {

    FSDRViewController *dr = [[FSDRViewController alloc] initWithNibName:@"FSDRViewController" bundle:nil];
    dr.userId = [userid intValue];
    [self.navigationController pushViewController:dr animated:TRUE];
}

-(void) goTag:(id)sender
{
    
    if (![[self itemSource] respondsToSelector:@selector(tagId)])
    {
        return;
    }
    int input = [[[self itemSource] valueForKey:@"tagId"] intValue];
    FSSearchViewController *tag = [[FSSearchViewController alloc] initWithNibName:@"FSSearchViewController" bundle:nil];
    tag.searchTag = input;
    tag.navigationItem.title = [[self itemSource] valueForKey:@"title"];
    [self.navigationController pushViewController:tag animated:TRUE];
}
- (IBAction)doFavor:(id)sender {
    
    bool isLogined = [[FSModelManager sharedModelManager] isLogined];
     __block id view = self.paginatorView.currentPage;
    if (!isLogined)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        FSMeViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"userProfile"];
        __block FSMeViewController *blockMeController = loginController;
       
        loginController.completeCallBack=^(BOOL isSuccess){
            
            [blockMeController dismissViewControllerAnimated:true completion:^{
                if (!isSuccess)
                {
                    [self reportError:NSLocalizedString(@"COMM_OPERATE_FAILED", nil)];
                }
                else
                {
                    if ([view respondsToSelector:@selector(btnFavor)])
                    {
                        UIBarButtonItem *favorButton = [view btnFavor];
                        [self internalDoFavor:favorButton];
                    }
              /*
                    [self startProgress:NSLocalizedString(@"FS_PRODETAIL_FAVORING",nil)withExeBlock:^(dispatch_block_t callback){
                        [self internalDoFavor:callback];
                    } completeCallbck:^{
                        [self endProgress];
                    }];
                     */
                }
            }];
        };
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginController];
        [self presentViewController:navController animated:false completion:nil];
        
    }
    else
    {
        if ([view respondsToSelector:@selector(btnFavor)])
        {
            UIBarButtonItem *favorButton = [view btnFavor];
            [self internalDoFavor:favorButton];
        }
    }
    
}
-(void)didTapProImage:(id) sender
{
    if ([self numberOfImagesInSlides:nil]<=0)
        return;
    FSImageSlideViewController *slide = [[FSImageSlideViewController alloc] initWithNibName:@"FSImageSlideViewController" bundle:nil];
    slide.source = self;
    slide.wantsFullScreenLayout = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:slide];
    [self presentViewController:nav animated:TRUE completion:nil];
}

- (IBAction)doGoStoreDetail:(id)sender {
}

- (void) displayCommentInputView:(id)parent
{
    FSProCommentInputView *commentInput = (FSProCommentInputView*)[self.view viewWithTag:PRO_DETAIL_COMMENT_INPUT_TAG];
    if (!commentInput)
    {
         commentInput = [[[NSBundle mainBundle] loadNibNamed:@"FSProCommentInputView" owner:self options:nil] lastObject];
        CGFloat height = PRO_DETAIL_COMMENT_INPUT_HEIGHT;
        commentInput.frame = CGRectMake(0, self.view.frame.size.height-TOOLBAR_HEIGHT-height, self.view.frame.size.width, height);
        commentInput.txtComment.delegate = self;
        [commentInput.btnComment addTarget:self action:@selector(saveComment:) forControlEvents:UIControlEventTouchUpInside];
        [commentInput.btnCancel addTarget:self action:@selector(clearComment:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:commentInput];
        commentInput.tag = PRO_DETAIL_COMMENT_INPUT_TAG;
        if  (commentInput.opaque!=1)
        {
            commentInput.layer.opacity = 0;
            [UIView beginAnimations:@"fadein" context:(__bridge void *)([NSNumber numberWithFloat:commentInput.layer.opacity])];
            [UIView setAnimationDuration:0.5];
            commentInput.layer.opacity = 1;
            [UIView commitAnimations];
            commentInput.opaque = 1;
            [self.view bringSubviewToFront:commentInput];
        }

    } else
    {
        [self hideCommentInputView:parent];
    }
    
   
}

-(void) hideCommentInputView:(id)parent
{
    FSProCommentInputView *commentInput = (FSProCommentInputView*)[self.view viewWithTag:PRO_DETAIL_COMMENT_INPUT_TAG];
    if (commentInput)
    {
        commentInput.txtComment.text = @"";
        [commentInput.txtComment resignFirstResponder];
        if (commentInput.opaque!=0)
        {
            commentInput.layer.opacity = 1;
            [UIView beginAnimations:@"fadeout" context:(__bridge void *)([NSNumber numberWithFloat:commentInput.layer.opacity])];
            [UIView setAnimationDuration:0.3];
            commentInput.layer.opacity = 0;
            [UIView commitAnimations];
            [commentInput removeFromSuperview];
        }
    }
    
}
-(void)clearComment:(UIButton *)sender
{
    [self hideCommentInputView:self.view];
}
-(NSString *)transformCommentText
{
    FSProCommentInputView *commentView = [self.view viewWithTag:PRO_DETAIL_COMMENT_INPUT_TAG];
    NSString *trimedText = [[commentView.txtComment.text stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    return trimedText;
}
-(void)saveComment:(UIButton *)sender
{
    FSProCommentInputView *commentView = [self.view viewWithTag:PRO_DETAIL_COMMENT_INPUT_TAG];
    [commentView.txtComment resignFirstResponder];
    NSString *trimedText = [self transformCommentText];
    if (trimedText.length>40 ||trimedText.length<1)
    {
        [self reportError:NSLocalizedString(@"PRO_COMMENT_LENGTH_NOTCORRECT", Nil)];
        return;
    }
    bool isLogined = [[FSModelManager sharedModelManager] isLogined];
    if (!isLogined)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
        FSMeViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"userProfile"];
        __block FSMeViewController *blockMeController = loginController;
        loginController.completeCallBack=^(BOOL isSuccess){
            
            [blockMeController dismissViewControllerAnimated:true completion:^{
                if (!isSuccess)
                {
                    [self reportError:NSLocalizedString(@"COMM_OPERATE_FAILED", nil)];
                }
                else
                {
                    
                    
                    [self startProgress:NSLocalizedString(@"FS_PRODETAIL_COMMING",nil)withExeBlock:^(dispatch_block_t callback){
                        [self internalDoComent:callback];
                    } completeCallbck:^{
                        [self endProgress];
                        
                    }];
                }
            }];
        };
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:loginController];
        [self presentViewController:navController animated:false completion:nil];
        
    }
    else
    {
        [self startProgress:NSLocalizedString(@"FS_PRODETAIL_COMMING",nil)withExeBlock:^(dispatch_block_t callback){
            [self internalDoComent:callback];
        } completeCallbck:^{
            [self endProgress];
        }];
        
        
    }

    
}

-(void) internalDoComent:(dispatch_block_t)callback
{
    FSProCommentInputView *commentView = [self.view viewWithTag:PRO_DETAIL_COMMENT_INPUT_TAG];
    NSString *commentText = [self transformCommentText];
    FSCommonCommentRequest *request = [[FSCommonCommentRequest alloc] init];
    request.userToken = [FSModelManager sharedModelManager].loginToken;
    request.comment = commentText;
    request.sourceid = [[(FSDetailBaseView *)self.paginatorView.currentPage data] valueForKey:@"id"];
    request.sourceType = [NSNumber numberWithInt:_sourceType];
    request.routeResourcePath = RK_REQUEST_COMMENT_SAVE;
    
    __block FSProDetailViewController *blockSelf = self;
    [request send:[FSComment class] withRequest:request completeCallBack:^(FSEntityBase *respData){
        if(!respData.isSuccess)
        {
            [blockSelf updateProgress:respData.errorDescrip];
        }
        else
        {
            NSMutableArray *oldComments = [[(FSDetailBaseView *)blockSelf.paginatorView.currentPage data] comments];
            if (!oldComments)
                oldComments = [@[] mutableCopy];
            [oldComments insertObject:respData.responseData atIndex:0];
            [[(id)blockSelf.paginatorView.currentPage tbComment] reloadData];
            [blockSelf hideCommentInputView:self];
            [blockSelf updateProgress:NSLocalizedString(@"COMM_OPERATE_COMPL",nil)];
            
        }
        if (callback)
            callback();
    }];
    

}
#pragma FSImageSlide datasource
-(int)numberOfImagesInSlides:(FSImageSlideViewController *)view
{
    return [[self itemSource] resource].count;
}
-(NSURL *)imageSlide:(FSImageSlideViewController *)view imageNameForIndex:(int)index
{
    return [(FSResource *)[[[self itemSource] resource] objectAtIndex:index] absoluteUrl320];
}
-(void)imageSlide:(FSImageSlideViewController *)view didShareTap:(BOOL)shared
{
    NSMutableArray *shareItems = [@[] mutableCopy];
    id curView = self.paginatorView.currentPage;
    NSString *title = [self.itemSource valueForKey:@"title"];
    [shareItems addObject:title?title:@""];
    if ([curView imgView].image != nil)
    {
        [shareItems addObject:[curView imgView].image];
    }
    
    [[FSShareView instance] shareBegin:view withShareItems:shareItems  completeHander:^(NSString *activityType, BOOL completed){
        if (completed)
        {
            [view reportError:NSLocalizedString(@"COMM_OPERATE_COMPL", nil)];
        }
    }];

}
#pragma FSThumbView delegate
-(void)didTapThumView:(id)sender
{
   if ([sender isKindOfClass:[FSThumView class]])
   {
    [self goDR:[(FSThumView *)sender ownerUser].uid];
   }
}

#pragma UITableViewSource delegate

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    FSDetailBaseView *parentView = (FSDetailBaseView *)tableView.superview.superview.superview;
    NSMutableArray *comments = [parentView.data comments];
    FSProCommentHeader * view = [[[NSBundle mainBundle] loadNibNamed:@"FSProCommentHeader" owner:self options:nil] lastObject];
    view.count = [[parentView.data comments] count];
    return view;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    [self resetScrollViewSize:tableView.superview.superview.superview];
    return 1;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    FSDetailBaseView *parentView = (FSDetailBaseView *)tableView.superview.superview.superview;
    NSMutableArray *comments = [parentView.data comments];
    if (!comments ||
        comments.count<=0)
        [self showNoResult:tableView withText:NSLocalizedString(@"no comments", Nil) originOffset:PRO_DETAIL_COMMENT_HEADER_HEIGHT];
    else
        [self hideNoResult:tableView];
    return comments?comments.count:0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSProCommentCell *detailCell =  [tableView dequeueReusableCellWithIdentifier:@"commentCell"];
    FSDetailBaseView *parentView = (FSDetailBaseView *)tableView.superview.superview.superview;
    [detailCell setData:[[parentView.data comments] objectAtIndex:indexPath.row]];
    detailCell.imgThumb.delegate = self;
   
    return detailCell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FSProCommentCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    CGFloat totalHeight = 31; //yoffset
    totalHeight += [cell.lblComment sizeThatFits:cell.lblComment.frame.size].height;
    
    return MAX(PRO_DETAIL_COMMENT_CELL_HEIGHT,totalHeight+10);
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return PRO_DETAIL_COMMENT_HEADER_HEIGHT;
}

#pragma UITEXTFIELD DELEGATE
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return [textField resignFirstResponder];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([textView.superview.superview isKindOfClass:[FSProCommentInputView class]]) {
        if ([text isEqualToString:@""]) {
            return YES;
        }
        if (textView.text.length > 39) {
            return NO;
        }
    }
    return YES;
}

- (void)viewDidUnload {
    [self set_thumView:nil];
    [super viewDidUnload];
}
@end
