//
//  QFDownloadManager.h
//  NearMerchant
//
//  Created by Blues on 16/5/12.
//  Copyright © 2016年 qmm. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^QFDownloadProgressBlock)(float progress);
typedef void(^QFDownloadCompleteBlock)(NSError *error, NSString *strSavedPath);
typedef NS_ENUM(NSInteger, QFDownloadStatus) {
    kQFDownloading        = 1,
    kQFDownloadSuccess   = 2,
    kQFDownloadFailed    = 3
};

@interface QFDownloadManager : NSObject

@property (nonatomic, copy) NSString *strContentURL;
@property (nonatomic, assign) BOOL isShowHUD;
@property (nonatomic, assign, readonly) QFDownloadStatus status;
@property (nonatomic, strong, readonly, getter=strSavedDestPath) NSString *strSavedDestPath;
@property (nonatomic, copy) QFDownloadProgressBlock progressBlock;

+ (instancetype)shareInstance;
- (void)startDownloadWithCompleteBlock:(QFDownloadCompleteBlock)completeBlock;

@end
