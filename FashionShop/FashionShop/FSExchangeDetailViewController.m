//
//  FSExchangeDetailViewController.m
//  FashionShop
//
//  Created by HeQingshan on 13-4-28.
//  Copyright (c) 2013年 Fashion. All rights reserved.
//

#import "FSExchangeDetailViewController.h"
#import "FSExchangeSuccessViewController.h"
#import "FSUseScopeViewController.h"
#import "FSPointExDescCell.h"
#import "FSUseScopeViewController.h"
#import "FSExchangeSuccessViewController.h"
#import "FSExchangeRequest.h"
#import "FSExchange.h"
#import "FSStore.h"
#import "FSUser.h"
#import "NSString+Extention.h"
#import "FSCommon.h"

@interface FSExchangeDetailViewController ()
{
    FSExchange *_data;
    UILabel *exMoneyLb;
    UIButton *storeSelBtn;
    UITextField *pointExField;
    UITextField *idCardField;
    
    UIView *pickerView;
    UIPickerView *_picker;
    BOOL pickerIsShow;  //当前picker是否显示
    int tableYOffset;
    BOOL _inLoading;
    
    NSMutableArray *stores;
    NSInteger selIndex;
}

@end

@implementation FSExchangeDetailViewController

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
    UIBarButtonItem *baritemCancel = [self createPlainBarButtonItem:@"goback_icon.png" target:self action:@selector(onButtonBack:)];
    [self.navigationItem setLeftBarButtonItem:baritemCancel];
    
    _tbAction.backgroundView = nil;
    _tbAction.backgroundColor = APP_TABLE_BG_COLOR;
    
    //加载数据
    FSExchangeRequest *request = [[FSExchangeRequest alloc] init];
    request.routeResourcePath = RK_REQUEST_STOREPROMOTION_DETAIL;
    request.id = _requestID;
    [self beginLoading:_tbAction];
    _tbAction.hidden = YES;
    [request send:[FSExchange class] withRequest:request completeCallBack:^(FSEntityBase *respData) {
        [self endLoading:_tbAction];
        _tbAction.hidden = NO;
        if (respData.isSuccess)
        {
            _data = respData.responseData;
            stores = _data.inscopenotices;
            [_tbAction reloadData];
        }
        else
        {
            [self reportError:respData.errorDescrip];
        }
    }];
    
    [self initPickerView];
}

-(void)dealWithStoreAttributes
{
    if (!stores) {
        stores = [NSMutableArray array];
    }
    else{
        [stores removeAllObjects];
    }
    NSArray *_a = [_data.inScopeNotice componentsSeparatedByString:@"|"];
    for (NSString *item in _a) {
        if (item && ![item isEqualToString:@""]) {
            NSArray * _b = [item componentsSeparatedByString:@"--"];
            if (_b.count >= 2) {
                FSStore *s = [[FSStore alloc] init];
                s.name = _b[0];
                s.descrip = _b[1];
                [stores addObject:s];
            }
        }
    }
}

- (IBAction)onButtonBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTbAction:nil];
    [super viewDidUnload];
}

-(void)clickToExchagePoint:(UIButton*)sender
{
    if (_inLoading) {
        return;
    }
    NSString *error = nil;
    if (![self checkPoint:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:error delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tag = 102;
        [alert show];
        return;
    }
    if (![self checkIDCard:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:error delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        alert.tag = 103;
        [alert show];
        return;
    }
    [pointExField resignFirstResponder];
    [idCardField resignFirstResponder];
    
    FSExchangeRequest *request = [[FSExchangeRequest alloc] init];
    request.routeResourcePath = RK_REQUEST_STOREPROMOTION_EXCHANGE;
    request.storePromotionId = _requestID;
    request.points = [pointExField.text intValue];
    request.identityNo = idCardField.text;
    request.storeID = [_data.inscopenotices[selIndex] storeid];
    request.userToken = [FSUser localProfile].uToken;
    [self beginLoading:_tbAction];
    _inLoading = YES;
    self.view.userInteractionEnabled = NO;
    [request send:[FSExchangeSuccess class] withRequest:request completeCallBack:^(FSEntityBase *respData) {
        [self endLoading:_tbAction];
        _inLoading = NO;
        self.view.userInteractionEnabled = YES;
        if (respData.isSuccess)
        {
            FSExchangeSuccess *sucData = (FSExchangeSuccess*)respData.responseData;
            FSExchangeSuccessViewController *controller = [[FSExchangeSuccessViewController alloc] initWithNibName:@"FSExchangeSuccessViewController" bundle:nil];
            controller.data = sucData;
            [self.navigationController pushViewController:controller animated:YES];
        }
        else
        {
            [self reportError:respData.errorDescrip];
        }
    }];
}

-(void)clickToSelStore:(UIButton*)sender
{
    if (pickerIsShow) {
        [self hidenPickerView:YES];
    }
    else {
        [self showPickerView];
    }
}

#pragma mark - PickerView About

-(void)initPickerView
{
    if (pickerView) {
        [pickerView removeFromSuperview];
    }
    pickerView = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HIGH, APP_WIDTH, 262)];
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, APP_WIDTH, 46)];
    imgView.image = [UIImage imageNamed:@"picker_head_bg.png"];
    imgView.backgroundColor = [UIColor grayColor];
    [pickerView addSubview:imgView];
    
    UIButton * cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(8, 8, 50, 30);
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [cancelButton setBackgroundImage:[UIImage imageNamed:@"btn_short_left.png"] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [cancelButton addTarget:self action:@selector(cancelPickerView:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [pickerView addSubview:cancelButton];
    
    UIButton * okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [okButton setFrame:CGRectMake(APP_WIDTH - 58, 8, 50, 30)];
    [okButton setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [okButton setBackgroundImage:[UIImage imageNamed:@"btn_short_right.png"] forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okPickerView:) forControlEvents:UIControlEventTouchUpInside];
    okButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [pickerView addSubview:okButton];
    
    _picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 46, APP_WIDTH, 216)];
    _picker.delegate = self;
    _picker.dataSource = self;
    _picker.showsSelectionIndicator = YES;
    [pickerView addSubview:_picker];
    
    [theApp.window insertSubview:pickerView atIndex:1000];
}

-(void)showPickerView
{
    if (pickerView.frame.origin.y <= SCREEN_HIGH && !pickerIsShow)
    {
        pickerIsShow = YES;
        [_picker selectRow:selIndex inComponent:0 animated:NO];
        
        tableYOffset = self.tbAction.contentOffset.y;
        [UIView animateWithDuration:0.3f animations:^{
            CGRect rect = pickerView.frame;
            rect.origin.y -= pickerView.frame.size.height;
            pickerView.frame = rect;
        } completion:nil];
        [_picker reloadAllComponents];
    }
}

-(void)hidenPickerView:(BOOL)animated
{
    if (pickerView.frame.origin.y <= SCREEN_HIGH-pickerView.frame.size.height && pickerIsShow)
    {
        if (animated) {
            pickerIsShow = NO;
            [UIView animateWithDuration:0.3f animations:^{
                CGRect rect = pickerView.frame;
                rect.origin.y += pickerView.frame.size.height;
                pickerView.frame = rect;
            } completion:nil];
        }
        else {
            pickerIsShow = NO;
            CGRect rect = pickerView.frame;
            rect.origin.y += pickerView.frame.size.height;
            pickerView.frame = rect;
        }
        
    }
}

-(void)cancelPickerView:(UIButton*)sender
{
    [self hidenPickerView:YES];
}

-(void)okPickerView:(UIButton*)sender
{
    [self hidenPickerView:YES];
    selIndex = [_picker selectedRowInComponent:0];
    if (selIndex < stores.count) {
        [storeSelBtn setTitle:[stores[selIndex] storename] forState:UIControlStateNormal];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_data == nil) {
        return 0;
    }
    return 4;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

#define Point_Ex_Detail_Desc_Cell_Indentifier @"FSPointExDescCell"
#define Point_Ex_Detail_Do_Cell_Indentifier @"FSPointExDoCell"
#define Point_Ex_Detail_Common_Cell_Indentifier @"FSPointExCommonCell"

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            FSPointExDescCell *cell = (FSPointExDescCell*)[tableView dequeueReusableCellWithIdentifier:Point_Ex_Detail_Desc_Cell_Indentifier];
            if (cell == nil) {
                NSArray *_array = [[NSBundle mainBundle] loadNibNamed:@"FSPointExDescCell" owner:self options:nil];
                if (_array.count > 0) {
                    cell = (FSPointExDescCell*)_array[0];
                    cell.useScope.delegate = self;
                }
                else{
                    cell = [[FSPointExDescCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Point_Ex_Detail_Desc_Cell_Indentifier];
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            [cell setData:_data];
            
            return cell;
        }
            break;
        case 1:
        {
            FSPointExDoCell *cell = (FSPointExDoCell*)[tableView dequeueReusableCellWithIdentifier:Point_Ex_Detail_Do_Cell_Indentifier];
            if (cell == nil) {
                NSArray *_array = [[NSBundle mainBundle] loadNibNamed:@"FSPointExDescCell" owner:self options:nil];
                if (_array.count > 0) {
                    cell = (FSPointExDoCell*)_array[1];
                    [cell.exBtn addTarget:self action:@selector(clickToExchagePoint:) forControlEvents:UIControlEventTouchUpInside];
                    [cell.selStoreBtn addTarget:self action:@selector(clickToSelStore:) forControlEvents:UIControlEventTouchUpInside];
                    cell.pointExField.delegate = self;
                    pointExField = cell.pointExField;
                    exMoneyLb = cell.exMoney;
                    cell.idCardField.delegate = self;
                    idCardField = cell.idCardField;
                    storeSelBtn = cell.selStoreBtn;
                }
                else{
                    cell = [[FSPointExDoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Point_Ex_Detail_Do_Cell_Indentifier];
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            [cell setData:_data];
            if (stores.count == 1) {
                [storeSelBtn setTitle:[stores[0] storename] forState:UIControlStateNormal];
            }
            cell.remainPoint.text = [NSString stringWithFormat:@"%@", [FSUser localProfile].cardInfo.amount];
            
            return cell;
        }
            break;
        case 2:
        {
            FSPointExCommonCell *cell = (FSPointExCommonCell*)[tableView dequeueReusableCellWithIdentifier:Point_Ex_Detail_Common_Cell_Indentifier];
            if (cell == nil) {
                NSArray *_array = [[NSBundle mainBundle] loadNibNamed:@"FSPointExDescCell" owner:self options:nil];
                if (_array.count > 0) {
                    cell = (FSPointExCommonCell*)_array[2];
                }
                else{
                    cell = [[FSPointExCommonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Point_Ex_Detail_Common_Cell_Indentifier];
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.title = @"兑换标准";
            cell.desc = _data.inScopeNotice;
            [cell setData];
            
            return cell;
        }
            break;
        case 3:
        {
            FSPointExCommonCell *cell = (FSPointExCommonCell*)[tableView dequeueReusableCellWithIdentifier:Point_Ex_Detail_Common_Cell_Indentifier];
            if (cell == nil) {
                NSArray *_array = [[NSBundle mainBundle] loadNibNamed:@"FSPointExDescCell" owner:self options:nil];
                if (_array.count > 0) {
                    cell = (FSPointExCommonCell*)_array[2];
                }
                else{
                    cell = [[FSPointExCommonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Point_Ex_Detail_Common_Cell_Indentifier];
                }
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.title = @"注意事项";
            cell.desc = _data.notice;
            [cell setData];
            
            return cell;
        }
            break;
        default:
            break;
    }
    
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
        {
            FSPointExDescCell *cell = (FSPointExDescCell*)[tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
            return cell.cellHeight;
        }
            break;
        case 1:
        {
         //   FSPointExDescCell *cell = (FSPointExDescCell*)[tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
            return 322;
        }
            break;
        case 2:
        {
            FSPointExDescCell *cell = (FSPointExDescCell*)[tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
            return cell.cellHeight;
        }
            break;
        case 3:
        {
            FSPointExDescCell *cell = (FSPointExDescCell*)[tableView.dataSource tableView:tableView cellForRowAtIndexPath:indexPath];
            return cell.cellHeight;
        }
            break;
        default:
            break;
    }
    return 100;
}

#pragma mark - RTLabelDelegate

- (void)rtLabel:(id)rtLabel didSelectLinkWithURL:(NSURL*)url
{
    FSUseScopeViewController *controller = [[FSUseScopeViewController alloc] initWithNibName:@"FSUseScopeViewController" bundle:nil];
    controller.stores = stores;
    [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField == idCardField || textField == pointExField) {
        //NSIndexPath *path = [_tbAction indexPathForCell:(FSPointExDoCell*)idCardField.superview.superview];
        [_tbAction scrollToRowAtIndexPath:[_tbAction indexPathForSelectedRow] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == idCardField) {
        //进行身份证号码核对
        NSString *error = nil;
        BOOL flag = [self checkIDCard:&error];
        if (!flag) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"温馨提示" message:error delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            alert.tag = 101;
            [alert show];
        }
    }
    else if(textField == pointExField) {
        if ([self checkPoint:nil]) {
            FSExchangeRequest *request = [[FSExchangeRequest alloc] init];
            request.routeResourcePath = RK_REQUEST_STOREPROMOTION_AMOUNT;
            request.storePromotionId = _requestID;
            request.userToken = [FSUser localProfile].uToken;
            request.points = [pointExField.text intValue];
            [request send:[FSExchange class] withRequest:request completeCallBack:^(FSEntityBase *respData) {
                if (respData.isSuccess)
                {
                    FSExchange *data = respData.responseData;
                    exMoneyLb.text = [NSString stringWithFormat:@"%.2f元",data.amount];
                    [exMoneyLb sizeToFit];
                }
                else
                {
                    exMoneyLb.text = respData.errorDescrip;
                    [exMoneyLb sizeToFit];
                }
            }];
        }
    }
    [textField resignFirstResponder];
    
    return YES;
}

-(BOOL)checkPoint:(NSString **)error
{
    BOOL flag = YES;
    int value = [pointExField.text intValue];
    if(_data.unitPerPoints > 0 && value % _data.unitPerPoints != 0) {
        exMoneyLb.text = [NSString stringWithFormat:@"兑换积点必须是%d的整数倍", _data.unitPerPoints];
        flag = NO;
    }
    else if (value < _data.minPoints) {
        exMoneyLb.text = @"输入积点数不能小于起兑积点数";
        flag = NO;
    }
    else if (value > [[FSUser localProfile].cardInfo.amount intValue]) {
        exMoneyLb.text = @"输入积点数不能大于剩余积点数";
        flag = NO;
    }
    [exMoneyLb sizeToFit];
    if (!flag && error) {
        *error = exMoneyLb.text;
    }
    
    return flag;
}

-(BOOL)checkIDCard:(NSString **)error
{
    return YES;//不验证身份证信息
    
    BOOL flag = [NSString isIDCardNum:idCardField.text];
    if (!flag && error) {
        *error = @"身份证号码输入不正确，请重新输入";
    }
    return flag;
}

#pragma UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return stores.count;
}

#pragma UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    FSCommon *com = stores[row];
    return [com storename];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 102) {
        [pointExField becomeFirstResponder];
    }
    else if(alertView.tag == 103) {
        [idCardField becomeFirstResponder];
    }
}

@end
