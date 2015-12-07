//
//  LogManager.m
//  LogManager
//
//  Created by AnarL on 12/3/15.
//  Copyright © 2015 AnarL. All rights reserved.
//

#define LOGS_DIRECTORY [NSHomeDirectory() stringByAppendingPathComponent:@"Applications/MacVideoConverter/Logs"]

#define TEMPLOG_DIRECTORY [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempLog.log"]

#define WRITELOGSUCCESSNOTIFICATION @"writeLogSuccess"

#define FILE_ATTRIBUTES @{ NSFilePosixPermissions : @(0777)}

#define LOG_STYLE [NSFont fontWithName:@"Times New Roman" size:18]

#import "LogManager.h"
#import <Cocoa/Cocoa.h>

@interface LogManager : NSObject <NSTextViewDelegate>
@property (nonatomic, copy) NSString * logPath;
/**
 *  单例创建一个管理对象
 *  create a singleton object
 */
+ (instancetype)defaultManager;

/**
 *  向当前日志文件里写入内容
 *  write content into the default log file
 */
- (void)writeToLogFileWithContent:(NSString *)content;

/**
 *  显示日志窗口
 *  show log window
 */
- (void)showLogPanel;

- (void)showAllLogs;

@end


/**
 *  只显示一个panel
 */
static NSPanel * _logPanel = nil;

@implementation LogManager
{
    NSFileManager * _fileManager;
    NSFileHandle * _fileHandle;
    
    NSScrollView * _logScrollView;
    NSTextView * _logView;
    
    NSButton * _showAllLogBtn;
}

/**
 *  自定义日志文件存储目录
 */
-(void)setLogPath:(NSString *)logPath
{
    if (_logPath != logPath) {
        _logPath = logPath;
    }
    
    [[NSUserDefaults standardUserDefaults] setValue:_logPath forKey:@"logPath"];
}

- (void)moveLogsToNewDirectory
{
    NSArray * logsPath = [self fetchAllLogFiles];
    
    for (NSString * logFilePath in logsPath) {
        NSString * fileName = [logFilePath lastPathComponent];
        NSString * newFilePath = [_logPath stringByAppendingPathComponent:fileName];
        
        BOOL moveSuccess = [_fileManager moveItemAtPath:logFilePath toPath:newFilePath error:nil];
        if (moveSuccess) {
            NSLog(@"move file success");
        } else {
            NSLog(@"move file fail");
        }
    }
}

/**
 *  初始化
 *  initial
 */
- (instancetype)init
{
    if (self = [super init]) {
        _fileManager = [NSFileManager defaultManager];
        self.logPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"logPath"];
        [self createLogFile];
    }
    return self;
}

/**
 *  单例创建管理对象
 *  create a singleton object
 */
+ (instancetype)defaultManager
{
    static dispatch_once_t predictor;
    static LogManager * manager = nil;
    dispatch_once(&predictor, ^{
        manager = [[LogManager alloc] init];
    });
    return manager;
}

#pragma mark -judge a directory is exists

/**
 *  判断目录是否存在
 *  is the directory exists
 */
- (BOOL)directoryIsExists:(NSString *)dir
{
    return [_fileManager fileExistsAtPath:dir];
}

#pragma mark -create
/**
 *  创建日志目录
 *  create a log directory
 */
- (void)createLogDirectory
{
    if (_logPath != nil) {
        if (![self directoryIsExists:_logPath]) {
            NSLog(@"%@", _logPath);
            BOOL createDirSuccess = [_fileManager createDirectoryAtPath:_logPath withIntermediateDirectories:YES attributes:FILE_ATTRIBUTES error:nil];
            if (createDirSuccess) {
                NSLog(@"创建目录成功");
            } else {
                NSLog(@"创建目录失败");
            }
        }
    } else {
        if (![self directoryIsExists:LOGS_DIRECTORY]) {
            NSLog(@"%@", LOGS_DIRECTORY);
            BOOL createDirSuccess = [_fileManager createDirectoryAtPath:LOGS_DIRECTORY withIntermediateDirectories:YES attributes:FILE_ATTRIBUTES error:nil];
            if (createDirSuccess) {
                NSLog(@"创建目录成功");
            } else {
                NSLog(@"创建目录失败");
            }
        }
    }
}

/**
 *  创建日志文件
 *  create a default log file
 */
- (void)createLogFile
{
    if (_logPath != nil) {
        if(![self directoryIsExists:_logPath]){
            [self createLogDirectory];
        }
        
        if ([[self fetchAllLogFiles] count] > 4) {
            [self deleteOldestLogFile];
        }
        [self createLogFileAt:_logPath contents:nil attributes:FILE_ATTRIBUTES];
    } else {
        if(![self directoryIsExists:LOGS_DIRECTORY]){
            [self createLogDirectory];
        }
        
        if ([[self fetchAllLogFiles] count] > 4) {
            [self deleteOldestLogFile];
        }
        [self createLogFileAt:LOGS_DIRECTORY contents:nil attributes:FILE_ATTRIBUTES];
    }
}

/**
 *  创建日志文件
 *  create a log file
 *
 *  @param path    日志文件路径/file path
 *  @param content 日志文件内容/file content
 *  @param attr    日志文件属性/file attributes
 */
- (void)createLogFileAt:(NSString *)path contents:(NSData *)content attributes:(NSDictionary *)attr
{
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    
    NSDate * currentDate = [NSDate dateWithTimeIntervalSince1970:time];
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSString * dateString = [formatter stringFromDate:currentDate];
    
    NSString * fileName = [NSString stringWithFormat:@"MacXVideoConverterPro-%@.log", dateString];
    
    BOOL createFileSuccess = [_fileManager createFileAtPath:[path stringByAppendingPathComponent:fileName] contents:content attributes:attr];
    
    if (createFileSuccess) {
        NSLog(@"创建文件成功");
    } else {
        NSLog(@"创建文件失败");
    }
}

/**
 *  创建一个临时日志文件，用来输出到日志显示窗口
 *  create a temp log file to init the log window data
 */
- (void)createATempLogFile
{
    if(![self directoryIsExists:TEMPLOG_DIRECTORY]){
        [self createLogDirectory];
    }
    
    NSArray * logFiles = [self fetchAllLogFiles];
    NSMutableString * allLogs = [[NSMutableString alloc] init];
    NSInteger i;
    for ( i = logFiles.count >1? (logFiles.count - 2) : (logFiles.count - 1); i < logFiles.count; i++) {
        
        _fileHandle = [NSFileHandle fileHandleForReadingAtPath:logFiles[i]];
        
        NSData * logData = [_fileHandle readDataToEndOfFile];
        
        [allLogs appendFormat:@"%@\n", [logFiles[i] lastPathComponent]];
        
        [allLogs appendFormat:@"%@",[[NSString alloc] initWithData:logData encoding:NSUTF8StringEncoding]];
        
        [_fileHandle closeFile];
        
        _fileHandle = nil;
    }
    
    BOOL createFileSuccess = [_fileManager createFileAtPath:TEMPLOG_DIRECTORY contents:[allLogs dataUsingEncoding:NSUTF8StringEncoding] attributes:FILE_ATTRIBUTES];
    
    
    if (createFileSuccess) {
        NSLog(@"create temp log file success");
    } else {
        NSLog(@"create temp log file fail");
    }
}

- (void)createLogPanel
{
    _logPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(300, 600, 700, 450) styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
    
    _logScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 25, _logPanel.frame.size.width, _logPanel.frame.size.height - 22 - 25)];
    
    /**
     NSViewNotSizable			=  0,
     NSViewMinXMargin			=  1,
     NSViewWidthSizable			=  2,
     NSViewMaxXMargin			=  4,
     NSViewMinYMargin			=  8,
     NSViewHeightSizable		= 16,
     NSViewMaxYMargin			= 32
     */
    [_logScrollView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [_logScrollView setAutoresizesSubviews:YES];
    
    _showAllLogBtn = [[NSButton alloc] initWithFrame:NSMakeRect(_logPanel.frame.size.width - 120, 2.5, 100, 20)];
    
    
    [_showAllLogBtn setTitle:@"ShowAllLogs"];
    [_showAllLogBtn setButtonType:NSMomentaryPushInButton];
    [_showAllLogBtn setBezelStyle:NSRoundedBezelStyle];
    
    [_showAllLogBtn setTarget:self];
    [_showAllLogBtn setAction:@selector(showAllLogs)];
    
    [_logPanel.contentView addSubview:_showAllLogBtn];
    
    _logView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, _logScrollView.frame.size.width, _logScrollView.frame.size.height)];
    
    _logView.font = LOG_STYLE;
    _logView.textColor = [NSColor greenColor];
    _logView.editable = NO;
    _logView.backgroundColor = [NSColor blackColor];
    
    _logScrollView.documentView = _logView;
    
    [_logPanel.contentView addSubview:_logScrollView];
    
    [_logPanel makeKeyAndOrderFront:nil];
    
}

#pragma mark -fetch
/**
 *  获取默认目录下的所有文件
 *  fetch all log files at the default directory
 */
- (NSArray *)fetchAllLogFiles
{
    NSMutableArray * filesPaths = [[NSMutableArray alloc] init];
    
    if (_logPath != nil) {
        if (![self directoryIsExists:_logPath]) {
            [self createLogDirectory];
        }
        NSArray * logFiles = [_fileManager contentsOfDirectoryAtPath:_logPath error:nil];
        
        for (NSString * fileName in logFiles) {
            [filesPaths addObject:[_logPath stringByAppendingPathComponent:fileName]];
        }
    } else {
        if (![self directoryIsExists:LOGS_DIRECTORY]) {
            [self createLogDirectory];
        }
        NSArray * logFiles = [_fileManager contentsOfDirectoryAtPath:LOGS_DIRECTORY error:nil];
        
        for (NSString * fileName in logFiles) {
            [filesPaths addObject:[LOGS_DIRECTORY stringByAppendingPathComponent:fileName]];
        }
    }
    return filesPaths;
}

/**
 *  获取最新的日志文件
 *  fetch the latest log file
 */
- (NSString *)fetchLatestLogFile
{
    return [[self fetchAllLogFiles] lastObject];
}

/**
 *  获取临时日志文件目录
 *  fetch temp log file directory
 */
- (NSString *)fetchTempLogFile
{
    return TEMPLOG_DIRECTORY;
}

#pragma mark -file operations

/**
 *  向最新的日志里写数据
 *  write content into the lastest log file
 */
- (void)writeToLogFileWithContent:(NSString *)content
{
    NSString * logFilePath = [self fetchLatestLogFile];
    
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    
    [_fileHandle seekToEndOfFile];
    
    [_fileHandle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_fileHandle closeFile];
    
    _fileHandle = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:WRITELOGSUCCESSNOTIFICATION object:content];
}

/**
 *  删除最先创建的日志
 *  delete the oldest log file
 */
- (void)deleteOldestLogFile
{
    if (_logPath != nil) {
        NSArray * conents = [_fileManager contentsOfDirectoryAtPath:_logPath error:nil];
        
        [_fileManager removeItemAtPath:[_logPath stringByAppendingPathComponent:[conents objectAtIndex:0]] error:nil];
    } else {
        NSArray * conents = [_fileManager contentsOfDirectoryAtPath:LOGS_DIRECTORY error:nil];
        
        [_fileManager removeItemAtPath:[LOGS_DIRECTORY stringByAppendingPathComponent:[conents objectAtIndex:0]] error:nil];
    }
}


/**
 *  读取临时日志里的数据
 *  fetch the temp log file
 */
- (NSData *)readFromLogFile
{
    NSString * logFilePath = [self fetchTempLogFile];
    
    _fileHandle = [NSFileHandle fileHandleForReadingAtPath:logFilePath];
    
    NSData * content = [_fileHandle readDataToEndOfFile];
    
    _fileHandle = nil;
    
    return content;
}

#pragma mark -panel operations
/**
 *  显示日志窗口
 *  show log panel
 */

-(void)showLogPanel
{
    if (_logPanel == nil) {
        
        [self createATempLogFile];
        
        [self createLogPanel];
        
        [_logPanel makeKeyAndOrderFront:nil];
        
        NSData * data = [self readFromLogFile];
        
        NSString * content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        _logView.string = content;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(panelWillClose) name:NSWindowWillCloseNotification object:_logPanel];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateLogView:) name:WRITELOGSUCCESSNOTIFICATION object:nil];

        
    }
}


/**
 *  日志窗口将要关闭
 *  log panel will be closed, unregister the notification
 */
- (void)panelWillClose
{
    for (NSView * subview in [_logPanel.contentView subviews]) {
        [subview removeFromSuperview];
    }
    
    _logPanel = nil;
    BOOL deleteSuccess = [_fileManager removeItemAtPath:TEMPLOG_DIRECTORY error:nil];
    
    if (deleteSuccess) {
        NSLog(@"delete temp log file success");
    } else {
        NSLog(@"delete temp log file fail");
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:WRITELOGSUCCESSNOTIFICATION object:nil];
}

/**
 *  刷新日志窗口
 *  refresh log window
 */
- (void)updateLogView:(NSNotification *)notification
{
    NSString * newString = notification.object;
    
    NSRect oldDocumentRect = [[_logScrollView documentView] frame];
    
    NSRect contentRect = [_logScrollView documentVisibleRect];

    [_logView.textStorage appendAttributedString:[[NSMutableAttributedString alloc] initWithString:newString attributes:@{NSFontAttributeName : LOG_STYLE, NSForegroundColorAttributeName : [NSColor greenColor]}]];
    
    if (contentRect.origin.y + contentRect.size.height == oldDocumentRect.size.height) {
        
        [_logView scrollRangeToVisible:NSMakeRange(_logView.textStorage.length, 0)];
    }
    
}




#pragma mark -

-(void)showAllLogs
{
    NSMutableString * tempLogContent = [[NSMutableString alloc] init];
    
    NSArray * allLogFilePaths = [self fetchAllLogFiles];
    
    NSInteger i;
    
    for (i = 0; i < allLogFilePaths.count; i++) {
        _fileHandle = [NSFileHandle fileHandleForReadingAtPath:allLogFilePaths[i]];
        
        [tempLogContent appendFormat:@"%@\n", [allLogFilePaths[i] lastPathComponent]];
        
        NSData * fileContent = [_fileHandle readDataToEndOfFile];
        
        [tempLogContent appendFormat:@"%@", [[NSString alloc] initWithData:fileContent encoding:NSUTF8StringEncoding]];
        
        [_fileHandle closeFile];
    }
    
    if (_logPanel == nil) {
        [self createLogPanel];
    }
    
    _logView.string = tempLogContent;
    [_showAllLogBtn removeFromSuperview];
    _showAllLogBtn = nil;
    
    _logScrollView.frame = NSMakeRect(0, 0, _logPanel.frame.size.width, _logPanel.frame.size.height - 22);
    
}

@end
#pragma mark -setup logs save directory
void SetLogsDirectory(NSString *destFolder)
{
    [[LogManager defaultManager] setLogPath:destFolder];
    
    if ([[LogManager defaultManager] logPath] != destFolder) {
        [[LogManager defaultManager] moveLogsToNewDirectory];
    }
    
}

//加上时间打印时间, 类似NSLog
#pragma mark -print content with timestamp
void CCLog(NSString *format, ...)
{
    va_list list;
    va_start(list, format);
    
    NSString *fullString = [[NSString alloc]initWithFormat:format arguments:list];
    
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    
    NSDate * currentDate = [NSDate dateWithTimeIntervalSince1970:time];
    
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"[HH:mm:ss]"];
    
    NSString * dateString = [formatter stringFromDate:currentDate];
    
    [[LogManager defaultManager] writeToLogFileWithContent:[NSString stringWithFormat:@"%@%@\n", dateString, fullString]];
    
    va_end(list);
}

//无打印时间, 类似printf
#pragma mark -print content without timestamp
void CCPrint(NSString* format, ...)
{
    va_list list;
    va_start(list, format);
    NSString *fullString = [[NSString alloc]initWithFormat:format arguments:list];
    
    [[LogManager defaultManager] writeToLogFileWithContent:[NSString stringWithFormat:@"%@\n", fullString]];
    
    va_end(list);
}

#pragma mark -display log panel
void DisplayLogViewer()
{
    [[LogManager defaultManager] showLogPanel];
}

#pragma mark -output all logs
void ShowAllLogFiles()
{
    [[LogManager defaultManager] showAllLogs];
}

