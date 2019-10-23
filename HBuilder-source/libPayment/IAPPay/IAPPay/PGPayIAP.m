//
//  PGPushIAP.m
//  HBuilder-Integrate
//
//  Created by MacPro on 15-10-22.
//  Copyright (c) 2015年 DCloud. All rights reserved.
//

#import "PGPayIAP.h"

NSString* pStrTitle         = @"title";
NSString* pStrDescription   = @"description";
NSString* pStrPriceLocal    = @"pricelocal";
NSString* pStrPrice         = @"price";
NSString* pStrProductID     = @"productid";
NSString* pStrUserName      = @"username";
NSString* pStrQuantity      = @"quantity";
NSString* pStrRequestData   = @"requestData";
NSString* pStrPayment       = @"payment";
NSString* pStrReceipts      = @"Receipts";
NSString* pStrTransactionReceipt    = @"transactionReceipt";
NSString* pStrTransactionDate       = @"transactionDate";
NSString* pStrTransactionIdentifier = @"transactionIdentifier";
NSString* pStrTransactionState      = @"transactionState";


@interface PGPlatbyIAP ()
{
    // 当前请求的支付ID
    NSString*               pCurrentProductID;
    // 当前支付请求的回调ID
    NSString*               pRequestcbID;
    // 当前订单请求的回调ID
    NSString*               pCurrentcbID;
    // 已经支付完成的非消耗型项目回调ID
    NSString*               pRestorecbID;
    // 事件监听的回调ID
    //NSString*               pOnEventCallBackID;
    // 支付服务器返回的可支付的订单项的列表,可以支付请求需要根据列表中保存的ProduceRequest生成支付订单，如果请求的支付ID没有对应的Produce信息就回调出错
    NSMutableDictionary*    pPaymentQueue;
    //
    NSMutableArray*         pResotreQuary;
}

@end

@implementation PGPlatbyIAP

- (id)init
{
    if (self = [super init]) {
        self.type = @"appleiap";
        self.description = @"In-App Purchase";
        pRequestcbID = nil;
        
        // 如果支付被关闭就返回空
        self.serviceReady = [SKPaymentQueue canMakePayments];
    }
    return self;
}

- (NSDictionary*)JSDict {
    // 如果支付被关闭就返回空
    self.serviceReady = [SKPaymentQueue canMakePayments];
    return [super JSDict];
}


#pragma mark SKRequest & delegates
/*
 * 发送订单请求
 */
- (void)requestOrder:(PGMethod *)command
{
    pCurrentcbID = [[NSString alloc] initWithString:[command.arguments objectAtIndex:1]];

    // 如果支付被关闭就返回空
    if (![SKPaymentQueue canMakePayments]) {
        // 禁止支付错误回调
        [self toErrorCallback:pCurrentcbID withCode:-100 withMessage:@"Payment_appleiap:支付通道已关闭"];
        return;
    }
    
    NSArray* pUserBookIDs = [command.arguments objectAtIndex:2];
    
    if (pPaymentQueue != NULL) {
        [pPaymentQueue removeAllObjects];
    }
    
    if ([pUserBookIDs isKindOfClass:NSArray.class])
    {
        NSSet *nsset = [NSSet setWithArray:pUserBookIDs];
        if (nsset != nil) {
            SKProductsRequest *request=[[SKProductsRequest alloc] initWithProductIdentifiers: nsset];
            request.delegate=self;
            [request start];
        }
    }
    else{
        // 参数错误失败回调
        [self toErrorCallback:pCurrentcbID withCode:-1];
    }
}


/*
 向appstore发送请求结束
 */
- (void)requestDidFinish:(SKRequest *)request
{
    NSMutableArray* pProductArray = [NSMutableArray array];
    if (pPaymentQueue != nil && [pPaymentQueue count] > 0) {
        for (SKProduct* pPayProduct in [pPaymentQueue allValues]){
            if([pPayProduct isKindOfClass:[SKProduct class]]){
                // 组合返回数据
                NSMutableDictionary* pMutRetValue = [NSMutableDictionary dictionary];
                if (pMutRetValue != nil) {
                    [pMutRetValue setObject:pPayProduct.localizedTitle?pPayProduct.localizedTitle:@"" forKey:pStrTitle];
                    [pMutRetValue setObject:pPayProduct.localizedDescription?pPayProduct.localizedDescription:@"" forKey:pStrDescription];
                    [pMutRetValue setObject:pPayProduct.price?pPayProduct.price:@"" forKey:pStrPrice];
                    [pMutRetValue setObject:pPayProduct.priceLocale.localeIdentifier?pPayProduct.priceLocale.localeIdentifier:@"" forKey:pStrPriceLocal];
                    [pMutRetValue setObject:pPayProduct.productIdentifier?pPayProduct.productIdentifier:@"" forKey:pStrProductID];
                    // 返回结构添加到列表中
                    [pProductArray addObject:pMutRetValue];
                }
            }
            else{
                if (pCurrentcbID) {
                    [self toErrorCallback:pCurrentcbID withCode:-100 withMessage:@"Payment_appleiap:返回订单信息失败"];
                }
            }
        }
        // 准备返回的数据
        PDRPluginResult* pResult = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray:pProductArray];
        if (pCurrentcbID) {
            [self toCallback:pCurrentcbID withReslut:[pResult toJSONString]];
        }
    }
    else{
        if (pCurrentcbID) {
            [self toErrorCallback:pCurrentcbID withCode:-100 withMessage:@"Payment_appleiap:返回订单信息失败"];
        }
    }
}


/*
 向appstore请求交互发生错误回调
 */
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    if (pCurrentcbID) {
        [self toErrorCallback:pCurrentcbID withCode:-100 withMessage:[NSString stringWithFormat:@"Payment_appleiap:%@",error]];
    }
}

/*
 * 发起订单请求回调方法
 */
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSArray *myProduct = response.products;
    if (myProduct != nil && [myProduct count] > 0) {
        for (SKProduct* pPayProduct in myProduct) {
            if (pPaymentQueue == nil) {
                pPaymentQueue = [[NSMutableDictionary dictionary] retain];
            }
            // 添加到列表中
            [pPaymentQueue setObject:pPayProduct forKey: pPayProduct.productIdentifier];
        }
    }
    [request autorelease];
}

#pragma mark Transcation & delegates

/*
 * 发送支付请求
 */
- (void)request:(PGMethod *)command
{
    // 添加监听者
    [self addPaymentObersver];
    
    NSDictionary* pPaymentArgus = nil;
    
    pRequestcbID = [[NSString alloc] initWithString:[command.arguments objectAtIndex:2]];
    
    pPaymentArgus = [command.arguments objectAtIndex:1];
    
    pCurrentProductID = [[pPaymentArgus objectForKey:pStrProductID] retain];
    
    // 根据支付ID获取支付的Product支付ID
    SKProduct* product = [pPaymentQueue objectForKey:pCurrentProductID];
    if (product) {
        
        // 根据product生成payment
        SKMutablePayment *pCurPayment = [SKMutablePayment paymentWithProduct:product];
        if (pCurPayment) {
            // 支付用户的用户名
            NSString* pUserName = [pPaymentArgus objectForKey:pStrUserName];
            if (pUserName) {
                [pCurPayment setApplicationUsername:pUserName];
            }
            // 支付数量
            int nCount = [[pPaymentArgus objectForKey:pStrQuantity] intValue];
            if (nCount > 0) {
                [pCurPayment setQuantity:nCount];
            }
            
            [[SKPaymentQueue defaultQueue] addPayment:pCurPayment];
        }
    }
    else
    {//支付订单的ID不存在
        if (pRequestcbID) {
            [self toErrorCallback:pCurrentcbID withCode:-100 withMessage:@"Payment_appleiap:订单的ID不存在"];
        }
    }
}


/*
 * 支付结果返回方法
 */
-(void) PurchasedTransaction: (SKPaymentTransaction *)transaction
{
    NSArray *transactions =[[NSArray alloc] initWithObjects:transaction, nil];
    
    [self paymentQueue:[SKPaymentQueue defaultQueue] updatedTransactions:transactions];
    
    [transactions release];
    
}

/*
 * 更新支付信息，并做相关处理
 */
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions//交易结果
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased://交易完成
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed://交易失败
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored://已经购买过该商品
                [self restoreTransaction:transaction];
                break;
            case SKPaymentTransactionStatePurchasing://商品添加进列表
                
                break;
            default:
                break;
        }
    }
}


/*
 * 交易成功
 */
- (void) completeTransaction: (SKPaymentTransaction *)transaction
{
    // 读取交易详情，并返回数据
    NSString *product = transaction.payment.productIdentifier;
    NSDictionary* pDictran = [self MakeTransactionDic:transaction];
    
    if ([product length] > 0 && pDictran != nil) {
        // 当前如果支付的id和请求的ID一致就回调通知。
        if (pRequestcbID && [transaction.payment.productIdentifier compare:pCurrentProductID] == NSOrderedSame) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary: pDictran];
            [self toCallback:pRequestcbID withReslut:[result toJSONString]];
            [pRequestcbID release];
            pRequestcbID = nil;
        }
    }
    else
    {
        [self toErrorCallback:pRequestcbID withCode:-100 withMessage:[NSString stringWithFormat:@"Payment_appleiap:%@",transaction.error]];
    }
    
    // Remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}


/*
 购买失败回调
 */
- (void) failedTransaction: (SKPaymentTransaction *)transaction{
    // 回调通知支付失败
    if (pRequestcbID && [transaction.payment.productIdentifier compare:pCurrentProductID] == NSOrderedSame) {
        [self toErrorCallback:pRequestcbID withCode:-100 withMessage:[NSString stringWithFormat:@"Payment_appleiap:%@",transaction.error]];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    
}


#pragma mark restorepayment & delegate
// 恢复已经购买的项目
- (void)restoreComplateRequest:(PGMethod*)command
{
    NSString* pAccount = nil;
    
    // 添加监听者
    [self addPaymentObersver];
    
    if (command.arguments.count > 1) {
        pRestorecbID =  [[NSString alloc] initWithString:[command.arguments objectAtIndex:1] ];
    }
    
    if (command.arguments.count > 2) {
        pAccount = [[command.arguments objectAtIndex:2] objectForKey:pStrUserName];
    }
    
    SKPaymentQueue* payQuary = [SKPaymentQueue defaultQueue];
    if (payQuary) {
        if (pAccount != nil && [pAccount isKindOfClass:NSString.class]) {
            [payQuary restoreCompletedTransactionsWithApplicationUsername:pAccount];
        }
        else{
            [payQuary restoreCompletedTransactions];
        }
    }
}

- (NSData*)appStoreReceipt
{
    NSData* pRetData = nil;
    NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    if (receiptURL) {
        NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
        if (receipt) {
            NSString *receiptString = [receipt base64EncodedStringWithOptions:0];
            return [self resultWithString:receiptString?receiptString:@""];
        }
    }
    return pRetData;
}

/*
 商品已经购买过,看看是不是有可用的回调，如果有回调，就回调成功
 */
- (void) restoreTransaction: (SKPaymentTransaction *)transaction
{
    // 读取交易详情，并返回数据
    NSString *product = transaction.payment.productIdentifier;
    // 获取收据的信息
    NSDictionary* pDictran = [self MakeTransactionDic:transaction];
    
    if ([product length] > 0 && pDictran != nil) {
        // 当前如果支付的id和请求的ID一致就回调通知。
        if (pRequestcbID && [transaction.payment.productIdentifier compare:pCurrentProductID] == NSOrderedSame) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsDictionary: pDictran];
            [self toCallback:pRequestcbID withReslut:[result toJSONString]];
            [pRequestcbID release];
            pRequestcbID = nil;
        }
    }
    else{
        [self toErrorCallback:pRequestcbID withCode:-100 withMessage:@"Payment_appleiap:-5"];
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [self toErrorCallback:pRestorecbID withNSError:error];
}

// 恢复已购项目结束的回调
-(void) paymentQueueRestoreCompletedTransactionsFinished: (SKPaymentQueue *)queue
{
    NSMutableArray* pTransacQueue = [NSMutableArray array];
    
    if (queue.transactions.count > 0) {
        for (SKPaymentTransaction* transaction in queue.transactions) {
            NSDictionary* pTransacDic = [self MakeTransactionDic:transaction];
            [pTransacQueue addObject: pTransacDic];
        }
    }
    [self triggerEventFunction:pTransacQueue];
}

#pragma mark Listener function

// 添加监听器
/*
 - (void)addRequestListener:(PGMethod*)command
 {
 pOnEventCallBackID = [[NSString alloc] initWithString:[command.arguments objectAtIndex:1]];
 
 [self addPaymentObersver];
 }*/



// 当前页面关闭取消监听
- (void) onAppFrameWillClose:(PDRCoreAppFrame*)theAppframe
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

// 当前应用关闭取消监听
- (void) onAppTerminate
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}


#pragma mark local functions

//Local Functions

- (void)addPaymentObersver
{
    static dispatch_once_t predicate; dispatch_once(&predicate, ^{
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    });
}

-(NSString*)DateTranceToString:(NSDate*)pdate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *strDate = [dateFormatter stringFromDate:pdate];
    NSLog(@"%@", strDate);
    [dateFormatter release];
    return strDate;
}

/*
 * 处理返回的收据信息，并生成一个Dic返回
 */
- (NSDictionary*)MakeTransactionDic:(SKPaymentTransaction*)transaction
{
    NSMutableDictionary* pDictran = [NSMutableDictionary dictionary];
    if (pDictran) {
        //收据信息
        if (transaction.transactionReceipt != nil) {
            [pDictran setValue:[transaction.transactionReceipt base64EncodedStringWithOptions:0] forKey:pStrTransactionReceipt];
        }
        else
        {
            NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
            if (receiptURL) {
                NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
                if (receipt) {
                    [pDictran setValue:[receipt base64EncodedStringWithOptions:0] forKey:pStrTransactionReceipt];
                }
            }
        }
        
        [pDictran setValue:[self DateTranceToString:transaction.transactionDate] forKey:pStrTransactionDate];
        [pDictran setValue:transaction.transactionIdentifier forKey:pStrTransactionIdentifier];
        [pDictran setObject: [NSString stringWithFormat:@"%d",(int)transaction.transactionState] forKey:pStrTransactionState];
        
        NSMutableDictionary* pPaymentDic = [NSMutableDictionary dictionary];
        if (pPaymentDic) {
            [pPaymentDic setValue:transaction.payment.productIdentifier forKey:pStrProductID];
            [pPaymentDic setValue:transaction.payment.applicationUsername forKey:pStrUserName];
            [pPaymentDic setValue:[NSString stringWithFormat:@"%d", (int)transaction.payment.quantity] forKey:pStrQuantity];
            
            if (transaction.payment.requestData != nil) {
                NSString* pPayRequest = [[[NSString alloc] initWithData:transaction.transactionReceipt encoding:NSUTF8StringEncoding] autorelease];
                [pPaymentDic setValue:pPayRequest forKey:pStrRequestData];
            }
        }
        [pDictran setValue:pPaymentDic forKey:pStrPayment];
        
    }
    return pDictran;
}

- (void)triggerEventFunction:(NSArray*)RecQueue
{
    NSMutableDictionary* pEventDic = [NSMutableDictionary dictionary];
    if (pEventDic) {
        if (pRestorecbID != nil) {
            PDRPluginResult *result = [PDRPluginResult resultWithStatus:PDRCommandStatusOK messageAsArray:RecQueue];
            [self toCallback:pRestorecbID withReslut:[result toJSONString]];
        }
    }
}

@end
