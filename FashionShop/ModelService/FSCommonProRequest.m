//
//  FSProUploadRequest.m
//  FashionShop
//
//  Created by gong yi on 11/30/12.
//  Copyright (c) 2012 Fashion. All rights reserved.
//

#import "FSCommonProRequest.h"
#import "FSModelManager.h"
#import "CommonHeader.h"
#import "RKJSONParserJSONKit.h"

@interface FSCommonProRequest()
{
    dispatch_block_t completeBlock;
    dispatch_block_t errorBlock;
    BOOL isClientRequest;
}

@end
@implementation FSCommonProRequest
@synthesize uToken;
@synthesize imgs;
@synthesize descrip;
@synthesize tagId;
@synthesize tagName;
@synthesize storeId;
@synthesize brandId;
@synthesize title;
@synthesize brandName;
@synthesize storeName;
@synthesize id;
@synthesize longit,lantit;
@synthesize startdate;
@synthesize enddate;
@synthesize comment;
@synthesize pType;
@synthesize price;

@synthesize routeResourcePath;

-(void) setMappingRequestAttribute:(RKObjectMapping *)map
{
    [map mapKeyPath:@"lng" toAttribute:@"request.longit"];
    [map mapKeyPath:@"lat" toAttribute:@"request.lantit"];

    [map mapKeyPath:@"token" toAttribute:@"request.uToken"];
    [map mapKeyPath:@"name" toAttribute:@"request.title"];
    [map mapKeyPath:@"description" toAttribute:@"request.descrip"];
    [map mapKeyPath:@"startdate" toAttribute:@"request.startdate"];
    [map mapKeyPath:@"enddate" toAttribute:@"request.enddate"];
    [map mapKeyPath:@"storeid" toAttribute:@"request.brandId"];
    if (pType==FSSourceProduct)
    {
       [map mapKeyPath:@"productid" toAttribute:@"request.id"];
    } else if(pType ==FSSourcePromotion)
    {
        [map mapKeyPath:@"promotionid" toAttribute:@"request.id"];
    }
}



-(void) send:(FSEntityRequestBase *)request completeCallBack:(dispatch_block_t)blockcomplete errorCallback:(dispatch_block_t)blockerror
{
    RKObjectManager *innerManager = [FSModelManager sharedManager];
    FSEntityBase * entityObject = [[FSEntityBase alloc] init];
    entityObject.request = request;
   // entityObject.dataClass = responseClass;
    RKObjectMapping *responseMap = [RKObjectMapping mappingForClass:[entityObject class]];
    [entityObject mapRequestReponse:responseMap toManager:innerManager];
    NSString *url = [request appendCommonRequestQueryPara:innerManager];
   // requestCompleteCallback = completeCallback;
    [innerManager sendObject:entityObject toResourcePath:url usingBlock:^(RKObjectLoader *loader) {
        loader.method = RKRequestMethodPOST;
        loader.delegate = self;
        loader.objectMapping = responseMap;
        
    }];
    
    
}


- (void)upload:(dispatch_block_t)blockcomplete error:(dispatch_block_t)blockerror
{
    RKParams *params = [RKParams params];
    [params setValue:uToken forParam:@"token"];
    [params setValue:title forParam:@"name"];
    [params setValue:descrip forParam:@"description"];
    [params setValue:startdate forParam:@"startdate"];
    [params setValue:enddate forParam:@"enddate"];
    [params setValue:storeId forParam:@"storeid"];
    if (brandId)
        [params setValue:brandId forParam:@"brandid"];
    if (tagId)
        [params setValue:tagId forParam:@"tagid"];
    if (price)
        [params setValue:price forParam:@"price"];
    int i =0;
    for (UIImage* img in imgs) {
        [params setData:UIImageJPEGRepresentation(img, 0.6) MIMEType:@"image/jpeg" forParam:[NSString stringWithFormat:@"resource%d.jpeg",i++]];
    }
    
    NSString *baseUrl =[self appendCommonRequestQueryPara:[FSModelManager sharedManager]];
    completeBlock = blockcomplete;
    errorBlock = blockerror;
    isClientRequest = true;
    [[RKClient sharedClient] post:baseUrl params:params delegate:self];
}

- (void)requestDidStartLoad:(RKRequest *)request
{
    
}

- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    if ([response isOK] && completeBlock && isClientRequest) {
        RKJSONParserJSONKit* parser = [[RKJSONParserJSONKit alloc] init];
        NSError *error = NULL;
        NSDictionary *result = [parser objectFromString:response.bodyAsString error:&error];
        if (!error && [[result objectForKey:@"statusCode"] intValue]==200)
            completeBlock();
        else
            errorBlock();
    } else if (errorBlock && isClientRequest){
        errorBlock();
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    if (errorBlock)
    errorBlock();
}

@end

