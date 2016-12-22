//
//  QFDownloadManager.m
//  NearMerchant
//
//  Created by Blues on 16/5/12.
//  Copyright © 2016年 qmm. All rights reserved.
//

#import "QFDownloadManager.h"
#import "MBProgressHUD.h"

static NSString * const strSessionDescription = @"download session";

@interface QFDownloadManager () <NSURLSessionDownloadDelegate> {
    NSURLSession *_curSession;
    NSURLSessionDownloadTask *_downloadTask;
    NSString *_strResourcePath;
    NSString *_strResourceTmp;
    QFDownloadCompleteBlock _completeBlock;
    MBProgressHUD *_progressHUD;
    
    NSString *_strSavedDestPath;
}

@end

@implementation QFDownloadManager

#pragma mark - Life cycle

+ (instancetype)shareInstance {
    static QFDownloadManager *obj = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        obj = [[QFDownloadManager alloc] init];
    });
    return obj;
}

#pragma mark - Update task

- (NSString *)strSavedDestPath {
    
    NSString *strFileName = [_strContentURL stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    NSString *strResourceDir = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Resource"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *arrContents = [fileManager contentsOfDirectoryAtPath:strResourceDir error:nil];
    for (NSString *strPath in arrContents) {
        if ([strPath isEqualToString:strFileName]) {
            NSString *strFilePath = [strResourceDir stringByAppendingPathComponent:strPath];
            return strFilePath;
        }
    }
    return nil;
}

- (void)startDownloadWithCompleteBlock:(QFDownloadCompleteBlock)completeBlock {
    NSAssert(_strContentURL != nil, @" *** download address url can not be nil! *** ");
    
    _strSavedDestPath = [self strSavedDestPath];
    if (_strSavedDestPath != nil) {
        completeBlock(nil, _strSavedDestPath);
    }
    else {
        _status = kQFDownloading;
        [self createCurrentSession];
        _completeBlock = completeBlock;
        [self downloadPackage];
    }
}

- (void)createCurrentSession {
    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    _curSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:nil];
    _curSession.sessionDescription = strSessionDescription;
    
    _strResourcePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Resource"];
    _strResourceTmp = @"Resource.tmp";
}

- (void)downloadPackage {
    if (_isShowHUD == NO) {
        UIWindow *keyWindow = [[[UIApplication sharedApplication] delegate] window];
        _progressHUD = [MBProgressHUD showHUDAddedTo:keyWindow animated:YES];
        _progressHUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
        _progressHUD.labelText = @"正在下载...";
        _progressHUD.progress = 0.f;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:_strResourcePath isDirectory:nil] == NO) {
        [fileManager createDirectoryAtPath:_strResourcePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSArray *arrContents = [fileManager contentsOfDirectoryAtPath:_strResourcePath error:nil];
    NSMutableArray *arrTmpFile = [NSMutableArray array];
    for (NSString *strPath in arrContents) {
        if ([strPath isEqualToString:_strResourceTmp]) {
            NSString *strTmpFilePath = [_strResourcePath stringByAppendingPathComponent:strPath];
            [arrTmpFile addObject:strTmpFilePath];
        }
    }
    if (arrTmpFile.count == 1) {
        // **** 读取缓存数据，删除缓存文件
        NSData *resumeData = [NSData dataWithContentsOfFile:arrTmpFile.firstObject];
        _downloadTask = [_curSession downloadTaskWithResumeData:resumeData];
        [fileManager removeItemAtPath:arrTmpFile.firstObject error:nil];
    }
    else {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:_strContentURL]];
        _downloadTask = [_curSession downloadTaskWithRequest:request];
    }
    [_downloadTask resume];
}

#pragma mark - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *strFileName = [_strContentURL stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    NSString *strDocuments = [_strResourcePath stringByAppendingPathComponent:strFileName];
    NSError *error = nil;
    BOOL isSuc = [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:strDocuments] error:nil];
    
    NSString *strTmpDirPath = [NSHomeDirectory() stringByAppendingPathComponent:@"tmp"];
    NSArray *arrContents = [fileManager contentsOfDirectoryAtPath:strTmpDirPath error:&error];
    for (NSString *strPath in arrContents) {
        if ([strPath hasPrefix:@"CFNetworkDownload_"]) {
            NSString *strTmpFilePath = [strTmpDirPath stringByAppendingPathComponent:strPath];
            [fileManager removeItemAtPath:strTmpFilePath error:nil];
        }
    }
    
    // **** 保存出错
    if (isSuc == NO) {
        _progressHUD.labelText = @"保存失败！";
    }
    else {
        _progressHUD.labelText = @"下载完毕！";
        _strSavedDestPath = strDocuments;
    }
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes {
    float progress = (float)fileOffset / expectedTotalBytes;
    if (_progressBlock != nil) {
        _progressBlock(progress);
    }
    _progressHUD.progress = progress;
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    if (_progressBlock != nil) {
        _progressBlock(progress);
    }
    _progressHUD.progress = progress;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error != nil) {
        
        // **** 下载出错，缓存已经下载的数据到指定的缓存文件中
        NSData *resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData];
        if (resumeData.length > 0) {
            NSString *strTmpFilePath = [_strResourcePath stringByAppendingPathComponent:_strResourceTmp];
            [resumeData writeToFile:strTmpFilePath atomically:YES];
        }
        _status = kQFDownloadFailed;
        _completeBlock(error, nil);
    }
    else {
        _status = kQFDownloadSuccess;
        _completeBlock(nil, _strSavedDestPath);
    }
    [_progressHUD hide:YES afterDelay:1.f];
}

@end
