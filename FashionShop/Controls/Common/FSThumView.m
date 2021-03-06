//
//  FSThumView.m
//  FashionShop
//
//  Created by gong yi on 12/30/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#import "FSThumView.h"
#import "UIImageView+WebCache.h"
#import "UIButton+WebCache.h"

@interface FSThumView()
{

    UIButton *_imgButton;
    UIImageView *_drImage;
}

@end
@implementation FSThumView
@synthesize ownerUser = _owner;
@synthesize showCamera = _showCamera;
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame ownerUser:nil];
}
-(id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame ownerUser:(FSUser *)user
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setOwnerUser:user];
    }
    return self;
}
-(void) setOwnerUser:(FSUser *)ownerUser
{
    _owner = ownerUser;
    [self ensureImageButton];
    if (_owner &&
        _owner.thumnailUrl)
    {
        [_imgButton setImageWithURL:_owner.thumnailUrl];
        [_imgButton setTitle:@"" forState:UIControlStateNormal];
        
        if (_owner.userLevelId == FSDARENUser)
        {
            [self indicatorViewUpdate:@"daren_icon.png"];
            [self addSubview:_drImage];
        }
    }
    [self setNeedsLayout];
 
}
-(void)ensureImageButton
{
    if (_imgButton)
        return;
    _imgButton = [[UIButton alloc] initWithFrame:self.bounds];
    [_imgButton setBackgroundImage:[UIImage imageNamed:@"default_thum_icon.png"] forState:UIControlStateNormal];
    _imgButton.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:_imgButton];
}
-(void)setDelegate:(id<FSThumViewDelegate>)delegate
{
    if (delegate)
    {
        [self ensureImageButton];
        [_imgButton setUserInteractionEnabled:TRUE];
        [_imgButton addTarget:self action:@selector(doTapThumb:) forControlEvents:UIControlEventTouchUpInside];
        _delegate = delegate;
    } 

}
-(void)indicatorViewUpdate:(NSString *)imgName;
{
    if (!_drImage &&
        imgName)
    {
        CGSize drSize = CGSizeMake(15, 15);
        _drImage = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width-drSize.width, self.frame.size.height-drSize.height, drSize.width, drSize.height)];
        [self addSubview:_drImage];
    }
    if (imgName)
        [_drImage setImage:[UIImage imageNamed:imgName]];
   

}
-(void)setShowCamera:(BOOL)showCamera
{
    _showCamera = showCamera;
    if (showCamera)
    {
        [self indicatorViewUpdate:@"camera.png"];
    }
}
-(void) reloadThumb:(NSURL *)image
{
    [_imgButton setImageWithURL:image];

}
-(void)doTapThumb:(id)sender
{
    if ([_delegate respondsToSelector:@selector(didTapThumView:)])
    {
        [_delegate didTapThumView:self];
    }
}

@end
