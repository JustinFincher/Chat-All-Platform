//
//  ChatViewController.m
//  Mobile Chat
//
//  Created by JustZht on 15/1/6.
//  Copyright (c) 2015年 FHICT. All rights reserved.
//

#import "ChatViewController.h"


@interface ChatViewController ()


@property (nonatomic, readwrite) SRWebSocket *sockjsSocket;
@property (nonatomic, readwrite) BOOL socketReady;

@end

@implementation ChatViewController
@synthesize nameedit;
@synthesize tvStatus;
@synthesize tfOutput;
@synthesize tfInput, tfName;


-(void)viewWillAppear:(BOOL)animated
{
    //Startup websockets
    self.socketReady = NO;
    //This library requires a raw websocket url. It does accept http instead of ws.
    //For NodeJS with SockJS this should be "http://YOUR.URL:PORT/IDENTIFIER/websocket"
    self.sockjsSocket = [[SRWebSocket alloc] initWithURL:[[NSURL alloc] initWithString:@"http://www.justzht.com:6975/mobilechat/websocket"]];
    self.sockjsSocket.delegate = self;
    [self.sockjsSocket open];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(editnamePressed:)];
    
    nameedit.hidden=YES;

}

- (void)editnamePressed:(id)sender
{    nameedit.hidden=NO;
    [self.sockjsSocket close];
    self.sockjsSocket = nil;
    self.socketReady = NO;
    NSLog(@"下线");
    self.title = nil;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(viewWillAppear:)];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"聊天";


self.demoData = [[DemoModelData alloc] init];
    //add delegates to remove keyboard on pressing enter
    self.tfInput.delegate = self;
    self.tfName.delegate = self;
    // Do any additional setup after loading the view, typically from a nib.
    


    /**
     *  You MUST set your senderId and display name
     */
    self.senderId = @"Id";
    self.senderDisplayName = nameedit.text;
    
    
}



- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    
    
    if(self.socketReady){
        
        NSString *addName = [NSString stringWithFormat:@"%@ 说:\n",nameedit.text];
        NSString *combined = [NSString stringWithFormat:@"%@%@", addName, message.text];
        
        [self.sockjsSocket send:combined];
    }
    
    
    [self.demoData.messages addObject:message];
    [self finishSendingMessageAnimated:YES];

}


- (void)didPressAccessoryButton:(UIButton *)sender
{
    NSLog(@"这里是发送地址按钮");
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.demoData.messages objectAtIndex:indexPath.item];
}
- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.demoData.outgoingBubbleImageData;
    }
    
    return self.demoData.incomingBubbleImageData;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        if (![NSUserDefaults outgoingAvatarSetting]) {
            return nil;
        }
    }
    else {
        if (![NSUserDefaults incomingAvatarSetting]) {
            return nil;
        }
    }
    
    
    return [self.demoData.avatars objectForKey:message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.demoData.messages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if ([message.senderId isEqualToString:self.senderId]) {
        return nil;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.demoData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.demoData.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.demoData.messages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor blackColor];
        }
        else {
            cell.textView.textColor = [UIColor whiteColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */
    JSQMessage *currentMessage = [self.demoData.messages objectAtIndex:indexPath.item];
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return 0.0f;
    }
    
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.demoData.messages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}


// SRWebSocket handlers
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{

    
    
    NSString *output = [tfOutput text];
    
    //Set the textview on bottom focus when it becomes scrollable
    if([tfOutput.text hasSuffix:@"\n"])
    {
        if (tfOutput.contentSize.height - tfOutput.bounds.size.height > -30)
        {
            
            double delayInSeconds = 0.2;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
                           {
                               CGPoint bottomOffset = CGPointMake(0, tfOutput.contentSize.height - tfOutput.bounds.size.height);
                               [tfOutput setContentOffset:bottomOffset animated:YES];
                           });
        }
    }
    
    //Combine old messages with new messages
    NSString *combined = [NSString stringWithFormat:@"%@%@", message, @""];
    NSString *newOutput = [NSString stringWithFormat:@"%@%@", output, combined];
    
    tfOutput.text = newOutput;
    
    [self scrollToBottomAnimated:YES];
    JSQMessage *newMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSystem
                                     displayName:kJSQDemoAvatarDisplayNameSystem
                                            text:combined];

    NSString *addName = [NSString stringWithFormat:@"%@ 说:\n",nameedit.text];
    
    if ([newMessage.text hasPrefix:addName])
    {
        nil;
    }
    else
    {
        [self.demoData.messages addObject:newMessage];
        [self finishReceivingMessageAnimated:YES];
    }

    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.sockjsSocket close];
    self.sockjsSocket = nil;
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.socketReady = YES;
    NSLog(@"上线");
        self.title = @"在线";

}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.socketReady = NO;
    NSLog(@"下线");
    JSQMessage *EXITMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSystem
                                                 displayName:kJSQDemoAvatarDisplayNameSystem
                                                        text:@"当前离线状态\n 如果您在编辑名字，请点击'保存'/'save'回到在线状态"];
    [self.demoData.messages addObject:EXITMessage];
    [self finishReceivingMessageAnimated:YES];

    
}

@end
