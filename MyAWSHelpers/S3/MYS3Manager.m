//
//  MYS3Manager.m
//
//  Created by Vincil Bishop on 2/3/14.
//  Copyright (c) 2014 All rights reserved.
//

#import "MYS3Manager.h"

#define MYS3Manager_DidReceiveResponse_Notification @"MYS3Manager_DidReceiveResponse_Notification"
#define MYS3Manager_DidReceiveData_Notification @"MYS3Manager_DidReceiveData_Notification"
#define MYS3Manager_DidCompleteWithResponse_Notification @"MYS3Manager_DidCompleteWithResponse_Notification"
#define MYS3Manager_DidFailWithError_Notification @"MYS3Manager_DidFailWithError_Notification"
#define MYS3Manager_DidFailWithServiceException_Notification @"MYS3Manager_DidFailWithServiceException_Notification"

@interface MYS3Manager ()

@property (nonatomic,strong) AmazonS3Client *s3Client;
@property (nonatomic, strong) S3TransferManager *s3TransferManager;

@end

@implementation MYS3Manager

static MYS3Manager *_sharedManager;
static NSString *_accessKeyID;
static NSString *_secretKey;

+ (MYS3Manager*) sharedManager
{
    if (!_sharedManager) {
        _sharedManager = [[MYS3Manager alloc] init];
    }
    
    return _sharedManager;
}

+ (void) initSharedManagerWithAccessKeyID:(NSString*)accessKeyID secretKey:(NSString*)secretKey
{
    _accessKeyID = accessKeyID;
    _secretKey = secretKey;
    
    [self sharedManager];
}

- (id) init
{
    self = [super init];
    
    if (self) {
        _backgroundOperationQueue = [[NSOperationQueue alloc] init];
        [AmazonErrorHandler shouldNotThrowExceptions];
    }
    
    return self;
}

+ (void) setAccessKeyID:(NSString*)accessKeyID
{
    _accessKeyID = accessKeyID;
}

+ (void) setSecretKey:(NSString*)secretKey
{
    _secretKey = secretKey;
}

- (S3TransferManager*) s3TransferManager
{
    if (!_s3TransferManager) {
        // Initialize the S3 Client.
        AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:_accessKeyID
                                                         withSecretKey:_secretKey];
        
        s3.endpoint = [AmazonEndpoints s3Endpoint:US_EAST_1];
        
        // Initialize the TransferManager
        _s3TransferManager = [S3TransferManager new];
        _s3TransferManager.s3 = s3;
        _s3TransferManager.delegate = self;
    }
    
    return _s3TransferManager;
}

#pragma mark - Helper Methods -

- (void) uploadJPEGImage:(UIImage*)image bucket:(NSString*)bucket s3Filename:(NSString*)s3Filename completion:(MYCompletionBlock)completionBlock
{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
    
    if (!s3Filename) {
        s3Filename = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
    }
    
    [self.backgroundOperationQueue addOperationWithBlock:^{
        
        S3PutObjectRequest *putObjectRequest = [S3PutObjectRequest new];
        putObjectRequest.data = imageData;
        putObjectRequest.bucket = bucket;
        putObjectRequest.key = s3Filename;
        putObjectRequest.contentType = @"image/jpeg";
        
        AmazonServiceResponse *response = [[self s3TransferManager] synchronouslyUpload:putObjectRequest];
        
        //DDLogVerbose(@"Async Upload Finished: %@", response);
        
        NSDictionary *result = @{@"filename":s3Filename,@"AmazonServiceResponse":response};
        
        if (response.error) {
            
            //DDLogVerbose(@"error: %@", response.error);
            
            if (completionBlock) {
                completionBlock(self,NO,response.error,nil);
            }
            
        } else {
            
            if (completionBlock) {
                completionBlock(self,YES,nil,result);
            }
        }
 
    }];
}

#pragma mark - AmazonServiceRequestDelegate

-(void)request:(AmazonServiceRequest *)request didReceiveResponse:(NSURLResponse *)response
{
    //DDLogVerbose(@"didReceiveResponse called: %@", response);
    [[NSNotificationCenter defaultCenter] postNotificationName:MYS3Manager_DidReceiveResponse_Notification object:response];
}

- (void)request:(AmazonServiceRequest *)request didReceiveData:(NSData *)data
{
    //DDLogVerbose(@"%@",@"didReceiveData called");
    [[NSNotificationCenter defaultCenter] postNotificationName:MYS3Manager_DidReceiveData_Notification object:data];
}

-(void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response
{
    //DDLogVerbose(@"didCompleteWithResponse called: %@", response);
    [[NSNotificationCenter defaultCenter] postNotificationName:MYS3Manager_DidCompleteWithResponse_Notification object:response];
}

-(void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error
{
    //DDLogVerbose(@"didFailWithError called: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:MYS3Manager_DidFailWithError_Notification object:error userInfo:@{@"request":request}];
}

-(void)request:(AmazonServiceRequest *)request didFailWithServiceException:(NSException *)exception
{
    //DDLogVerbose(@"didFailWithServiceException called: %@", exception);
    [[NSNotificationCenter defaultCenter] postNotificationName:MYS3Manager_DidFailWithServiceException_Notification object:exception userInfo:@{@"request":request}];
}

@end
