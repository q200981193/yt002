//
//  FSDetailBaseView.h
//  FashionShop
//
//  Created by gong yi on 12/14/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#import "SYPageView.h"
#import "FSModelBase.h"

@interface FSDetailBaseView : SYPageView

@property(nonatomic,strong) id data;
@property(nonatomic) FSSourceType pType;
@property(nonatomic) BOOL showViewMask;

-(void)resetScrollViewSize;
-(void) updateInteraction:(id)updatedEntity;

@end
