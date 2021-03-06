//
//  FSProCommentCell.h
//  FashionShop
//
//  Created by gong yi on 12/9/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FSComment.h"
#import "FSThumView.h"

@interface FSProCommentCell : UITableViewCell

@property (strong, nonatomic) IBOutlet FSThumView *imgThumb;

@property (strong, nonatomic) IBOutlet UILabel *lblComment;
@property (strong, nonatomic) IBOutlet UILabel *lblInDate;

@property (strong, nonatomic) IBOutlet UILabel *lblNickie;

@property (strong, nonatomic) FSComment *data;
@end
