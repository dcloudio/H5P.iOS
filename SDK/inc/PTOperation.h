/*
 *------------------------------------------------------------------
 *  pandora/tools/pdr_operation.h
 *  Description:
 *     调度功能头文件
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-02-19 创建文件
 *------------------------------------------------------------------
 */
//优先级
typedef NS_ENUM(NSInteger, PTOperationPriority) {
    PTOperationPriorityLow = 0,
    PTOperationPriorityNormal,
    PTOperationPriorityHigh
};

//执行状态
typedef NS_ENUM(NSInteger, PTOperationStatus) {
    PTOperationStatusReady = 0,
    PTOperationStatusWait,
    PTOperationStatusRun,
    PTOperationStatusPause,
    PTOperationStatusStop,
    PTOperationStatusAbort,
    PTOperationStatusQueuePause,
    PTOperationStatusCount
};


@interface PTOperation : NSObject<NSCoding>
{
@private
    id _invoke;
    NSInteger _priority;
    PTOperationStatus _status;
}
@property(nonatomic, readonly)NSInteger priority;
//目前只支持读取
@property(nonatomic, readonly)PTOperationStatus status;


- (id)initWithPriotiry:(NSInteger)priority;
//开始一个任务
- (void)start;
- (void)stop;
- (void)pause;
- (void)resume;
- (void)abort;
// 该任务需要执行的代码
- (void)main;
// 任务退出时执行的代码
- (void)exit;

-(void) encodeWithCoder:(NSCoder *)aCoder;
-(id) initWithCoder:(NSCoder *)aDecoder;

- (void)willChangeToStatus:(PTOperationStatus)status;
- (void)didChangeToStatus;

@end

/*
 **@任务调度
 ** 目前只支持操作最大并行串行
 ** 优先级调用
 */
@interface PTOperationQueue : NSObject
{
@private
    NSMutableArray *_operationQueue;
    NSUInteger _maxRunOpation;
    NSUInteger _bitFlg;
}

//添加一个任务到队列,添加到对列中的任务不会立即执行
//必须带啊用op.start()开始
- (void)addOperation:(PTOperation *)op;
- (void)removeOperation:(PTOperation*)op;
- (void)addOperations:(NSArray *)objects;
- (void)removeOperations:(NSArray*)objects;
// 使处于调度器暂停状态
// 的任务处于真正的暂停状态
// 调用该接口前应该先条用pause
- (void)truePause;
// 暂停调度器
- (void)pause;
// 恢复调度器
- (void)resume;
//启动所有
- (void)startAll;
- (void)onStateChange:(PTOperation*)op toStatus:(PTOperationStatus)status;
- (void)onDidStateChange:(PTOperation*)op;
@end

