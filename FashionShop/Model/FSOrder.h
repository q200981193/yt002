//
//  FSOrder.h
//  FashionShop
//
//  Created by HeQingshan on 13-6-22.
//  Copyright (c) 2013年 Fashion. All rights reserved.
//

#import "FSModelBase.h"
#import "FSResource.h"

@class FSOrderProduct;
@class FSOrderRMAItem;

@interface FSOrderInfo : FSModelBase

@property (nonatomic, strong) NSString *orderno;//预订单编号
@property (nonatomic) float totalamount;//预订单金额
@property (nonatomic) int totalpoints;//预订单金额
@property (nonatomic) float extendprice;//预订单金额

@property (nonatomic) BOOL needinvoice;//是否需要发票
@property (nonatomic,strong) NSString *invoicesubject;//发票抬头
@property (nonatomic,strong) NSString *invoicedetail;//发票明细

@property (nonatomic) BOOL canrma;//当前是否可以退货
@property (nonatomic,strong) NSMutableArray *rmas;//退货信息列表

@property (nonatomic,strong) NSString *shippingaddress;//地址全称
@property (nonatomic,strong) NSString *shippingno;//运单号
@property (nonatomic,strong) NSString *shippingvianame;//送货方式
@property (nonatomic) float shippingfee;//运费
@property (nonatomic,strong) NSString *shippingzipcode;//邮编
@property (nonatomic,strong) NSString *shippingcontactphone;//联系电话
@property (nonatomic,strong) NSString *shippingcontactperson;//联系人名称

@property (nonatomic,strong) NSString *status;//预订单状态
@property (nonatomic) int statust;//预订单状态标志
@property (nonatomic,strong) NSString *paymentname;//支付方式
@property (nonatomic,strong) NSDate *createdate;//预订单创建时间
@property (nonatomic,strong) FSResource *resource;//商品图片资源
@property (nonatomic,strong) FSOrderProduct *product;//商品信息
@property (nonatomic,strong) NSString *memo;//预订单备注

@property (nonatomic) BOOL canvoid;//是否可以取消预订单
@property (nonatomic) int totalquantity;//商品数量

@end

@interface FSOrderRMAItem : FSModelBase

@property (nonatomic,strong) NSString *rejectreason;
@property (nonatomic,strong) NSString *reason;
@property (nonatomic,strong) NSString *bankcard;
@property (nonatomic,strong) NSString *bankaccount;
@property (nonatomic,strong) NSString *rmatype;
@property (nonatomic,strong) NSString *bankname;
@property (nonatomic,strong) NSString *rmano;
@property (nonatomic,strong) NSDate *createdate;
@property (nonatomic,strong) NSString *status;

@property (nonatomic,strong) NSNumber* chargepostfee;
@property (nonatomic,strong) NSNumber* rmaamount;
@property (nonatomic,strong) NSNumber* rebatepostfee;
@property (nonatomic,strong) NSNumber* chargegiftfee;
@property (nonatomic,strong) NSNumber* actualamount;

/*
 "rejectreason": null,
 "bankcard": "6225123413455432",
 "chargepostfee": null,
 "bankaccount": "unknow",
 "rmatype": "线上申请",
 "bankname": "中国工商银行",
 "rmaamount": 888,
 "rebatepostfee": null,
 "chargegiftfee": null,
 "rmano": "R13070148600",
 "createdate": "2013-07-01T21:35:04.1656685+08:00",
 "status": "已创建",
 "actualamount": null
 */


@end

@interface FSOrderProduct : FSModelBase

@property (nonatomic,strong) NSString *itemno;
@property (nonatomic) int quantity;
@property (nonatomic) float price;
@property (nonatomic,strong) NSString *properties;
@property (nonatomic,strong) NSString *productname;
@property (nonatomic,strong) NSString *itemdesc;
@property (nonatomic,strong) NSString *productid;
@property (nonatomic,strong) FSResource *resource;

@end
