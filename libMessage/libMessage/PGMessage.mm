/*
 *------------------------------------------------------------------
 *  pandora/feature/message/pg_message.mm
 *  Description:
 *      消息插件实现文件
 *      负责和js层代码交互，js native层对象维护
 *  DCloud Confidential Proprietary
 *  Copyright (c) Department of Research and Development/Beijing/DCloud.
 *  All Rights Reserved.
 *
 *  Changelog:
 *	number	author	modify date modify record
 *   0       xty     2013-1-8 创建文件
 *------------------------------------------------------------------
 */

#import "PGMessage.h"
#import "PTPathUtil.h"

@implementation PGMessage

@synthesize to = _to;
@synthesize cc = _cc;
@synthesize bcc = _bcc;
@synthesize UUID;
@synthesize subject = _subject;
@synthesize body = _body;

@synthesize bodyType;
@synthesize silent;
@synthesize attachment = _attachemnt;

@synthesize type;
@synthesize jsBrige;
@synthesize delegate;

- (void) dealloc
{
    [UUID release];
    [_to release];
    [_cc release];
    [_bcc release];
    [_subject release];
    [_body release];
    [_attachemnt removeAllObjects];
    [_attachemnt release];
    [super dealloc];
}

+(PGMessage*)messageWithJSON:(NSMutableDictionary*)json
{
    PGMessage *message = [[[PGMessage alloc] initWithJSON:json]autorelease];
    return message;
}

-(id)initWithJSON:(NSMutableDictionary*)json
{
    if ( self = [super init] )
    {
        if ( json )
        {
            self.UUID = [json objectForKey:@"__uuid__"];
            self.to = [json objectForKey:@"to"];
            self.cc = [json objectForKey:@"cc"];
            self.bcc = [json objectForKey:@"bcc"];
            self.subject = [json objectForKey:@"subject"];
            self.body = [json objectForKey:@"body"];
            self.type = (PGMessageType)[[json objectForKey:@"type"] intValue];
            
            self.bodyType = PGMessageBodyTypeTEXT;
            NSString *bTValue = [json objectForKey:@"bodyType"];
            if ( [bTValue isKindOfClass:[NSString class]] ) {
                if ( NSOrderedSame == [@"html" caseInsensitiveCompare:bTValue] ) {
                    self.bodyType = PGMessageBodyTypeHTML;
                }
            }
            NSArray *attValues = [json objectForKey:@"attachment"];
            for ( NSString *att in attValues )
            {
                if ( nil == _attachemnt )
                {
                    _attachemnt = [[NSMutableArray alloc] initWithCapacity:10];
                }
                NSString *absolutePath = [PTPathUtil absolutePath:att];
                if (absolutePath ==nil) {
                    absolutePath = @"";
                }
                [_attachemnt addObject:absolutePath];
            }
        }
    }
    return self;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      发送信息
 * @Parameters:
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)send
{
    //发送SMS
    if ( PGMessageTypeSMS == self.type ){
        if ( ![MFMessageComposeViewController canSendText] ){
            [self evalJSResult:PDRCommandStatusError message:@"not support text message"];
            if ( [self.delegate respondsToSelector:@selector(sendEnd:)] ){
                [self.delegate sendEnd:self];
            }
            return;
        }
        MFMessageComposeViewController *smsPicker = [[[MFMessageComposeViewController alloc] init] autorelease];
        if ( smsPicker ) {
            smsPicker.messageComposeDelegate = self;
            smsPicker.body = self.body;
            smsPicker.recipients = self.to;
            
            if ([[self pickRootViewController]  respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                [[self pickRootViewController]  presentViewController:smsPicker animated:YES completion:nil];
            } else {
                [[self pickRootViewController]  presentModalViewController:smsPicker animated:YES];
            }
            return;
        }
    }//发送邮件
    else if ( PGMessageTypeMail == self.type ) {
        Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
        if ( /*![MFMailComposeViewController canSendMail] */!mailClass) {
            [self evalJSResult:PDRCommandStatusError message:@"not support mail"];
            if ( [self.delegate respondsToSelector:@selector(sendEnd:)] ) {
                [self.delegate sendEnd:self];
            }
            return;
        }
        MFMailComposeViewController *mailPicker = [[[MFMailComposeViewController alloc] init] autorelease];
        if ( mailPicker ) {
            mailPicker.mailComposeDelegate = self;
            // 添加发送者
            [mailPicker setToRecipients:self.to];
            [mailPicker setCcRecipients:self.cc];
            [mailPicker setBccRecipients:self.bcc];
            [mailPicker setSubject:self.subject];
            [mailPicker setMessageBody:self.body isHTML: PGMessageBodyTypeHTML == self.bodyType ? YES: NO];
            for ( NSString *attPath in self.attachment ) {
                NSData *data = [NSData dataWithContentsOfFile:attPath];
                if ( data ) {
                    NSString *mimeType = [PTPathUtil getMimeTypeFromPath:attPath];
                    [mailPicker addAttachmentData:data mimeType:mimeType? mimeType: @"text/plain" fileName:[attPath lastPathComponent]];
                }
            }
            if ([[self pickRootViewController]  respondsToSelector:@selector(presentViewController:animated:completion:)]) {
                [[self pickRootViewController]  presentViewController:mailPicker animated:YES completion:nil];
            } else {
                [[self pickRootViewController]  presentModalViewController:mailPicker animated:YES];
            }
        } else {
            [self evalJSResult:PDRCommandStatusError message:@"no config account"];
            if ( [self.delegate respondsToSelector:@selector(sendEnd:)] ) {
                [self.delegate sendEnd:self];
            }
        }
        return;
    }
    [self evalJSResult:PDRCommandStatusError message:@"not support"];
    if ( [self.delegate respondsToSelector:@selector(sendEnd:)] ) {
        [self.delegate sendEnd:self];
    }
}

- (UIViewController*) pickRootViewController
{
    return [UIApplication sharedApplication].keyWindow.rootViewController;
}

/*
 *------------------------------------------------------------------
 * @Summary:
 *      通知JS执行结果
 * @Parameters:
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)evalJSResult:(PDRCommandStatus)resultCode message:(NSString*)message
{
    [self.jsBrige result:resultCode message:message callBackId:self.UUID];
}
/*
 *------------------------------------------------------------------
 * @Summary:
 *      短信发送回调
 * @Parameters:
 *      [1] controller邮件控制器
 *      [2] result 发送结果
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if ([controller respondsToSelector:@selector(presentingViewController)]) {
        [[controller presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[controller parentViewController] dismissModalViewControllerAnimated:YES];
    }
    
    switch (result)
    {
        case MessageComposeResultCancelled:
            [self evalJSResult:PDRCommandStatusError message:@"canceled"];
            break;
            
        case MessageComposeResultSent:
            [self evalJSResult:PDRCommandStatusOK message:@"sent success"];
            break;
        case MessageComposeResultFailed:
        default:
            [self evalJSResult:PDRCommandStatusError message:@"sent Failed"];
            break;
            
    }
    if ( [self.delegate respondsToSelector:@selector(sendEnd:)] ){
        [self.delegate sendEnd:self];
    }
}
/*
 *------------------------------------------------------------------
 * @Summary:
 *      邮件发送回调
 * @Parameters:
 *      [1] controller邮件控制器
 *      [2] result 发送结果
 * @Returns:
 *    无
 * @Remark:
 *  
 * @Changelog:
 *------------------------------------------------------------------
 */
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    if ([controller respondsToSelector:@selector(presentingViewController)]) {
        [[controller presentingViewController] dismissModalViewControllerAnimated:YES];
    } else {
        [[controller parentViewController] dismissModalViewControllerAnimated:YES];
    }
	switch (result)
	{
		case MFMailComposeResultCancelled:
            [self evalJSResult:PDRCommandStatusError message:@"canceled"];
			break;
		case MFMailComposeResultSaved:
            [self evalJSResult:PDRCommandStatusError message:@"Saved"];
			break;
		case MFMailComposeResultSent:
            [self evalJSResult:PDRCommandStatusOK message:@"Sent"];
			break;
		case MFMailComposeResultFailed:
			[self evalJSResult:PDRCommandStatusError message:@"Failed"];
			break;
		default:
            [self evalJSResult:PDRCommandStatusError message:@"not sen"];
			break;
	}
    if ( [self.delegate respondsToSelector:@selector(sendEnd:)] ){
        [self.delegate sendEnd:self];
    }
}

@end


@implementation PGMessaging

@synthesize hasPendingOperation;

-(void)dealloc
{
    [_messageDict release];
    [super dealloc];
}
/*
 *------------------------------------------------------------------
 * @Summary:
 *      创建js native对象
 * @Parameters:
 *    [1] command, js调用格式应该为 [uuid, type, [args]]
 * @Returns:
 *    无
 * @Remark:
 *
 * @Changelog:
 *------------------------------------------------------------------
 */
-(void)sendMessage:(PGMethod*)command
{
    if ( !command.arguments
        && ![command.arguments isKindOfClass:[NSDictionary class]] ) {
        return;
    }
    NSString *callbackId = [command.arguments objectAtIndex:0];
    NSMutableDictionary *dict = (NSMutableDictionary*)[command.arguments objectAtIndex:1];
    PGMessage *message = [PGMessage messageWithJSON:dict];
    message.delegate = self;
    message.UUID = callbackId;
    message.jsBrige = self;
    if ( !_messageDict ){
        _messageDict = [[NSMutableArray arrayWithCapacity:10] retain];
    }
    
    if ( self.hasPendingOperation ) {
        [self result:PDRCommandStatusError message:@"device busy" callBackId:message.UUID];
        return;
    }
    
    [_messageDict addObject:message];
    self.hasPendingOperation = YES;
    [message send];
    
}


- (void)listenMessage:(PGMethod*)command
{
    if(command && [command.arguments isKindOfClass:[NSArray class]]){
        NSString* callbackID = [command.arguments firstObject];
        if(callbackID){
            [self result:PDRCommandStatusError message:@"not support" callBackId:callbackID];
        }
    }
}

-(void)result:(PDRCommandStatus)resultCode message:(NSString*)message callBackId:(NSString*)callbackId
{
    PDRPluginResult *result = nil;
    if ( PDRCommandStatusOK == resultCode ) {
        result = [PDRPluginResult resultWithStatus:resultCode messageAsString:message];
    } else {
        result = [PDRPluginResult resultWithStatus:resultCode messageToErrorObject:resultCode withMessage:message];
    }
    
    [self toCallback:callbackId  withReslut:[result toJSONString]];
}

-(void)sendEnd:(PGMessage*)message
{
    if ( message ){
        [_messageDict removeObject:message];
    }
    self.hasPendingOperation = NO;
}

@end
