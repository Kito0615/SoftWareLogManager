//
//  LogManager.h
//  LogManager
//
//  Created by AnarL on 12/3/15.
//  Copyright © 2015 AnarL. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  设置日志文件存储路径
 */
void SetLogsDirectory(NSString *);
/**
 *  输出带时间戳的日志
 */
void CCLog(NSString *format, ...);
/**
 *  输出不带时间戳的日志
 */
void CCPrint(NSString* format, ...);
/**
 *  显示日志窗口
 */
void DisplayLogViewer();


#define FLog(format, ...) CCLog(format, ## __VA_ARGS__)
#define FPrint(format, ...) CCPrint(format, ## __VA_ARGS__)