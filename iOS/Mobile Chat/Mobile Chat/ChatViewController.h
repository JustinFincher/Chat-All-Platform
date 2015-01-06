//
//  ChatViewController.h
//  Mobile Chat
//
//  Created by JustZht on 15/1/6.
//  Copyright (c) 2015年 FHICT. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import <UIKit/UIKit.h>
#import "SRWebSocket.h"
#import "JSQMessages.h"
#import "DemoModelData.h"
#import "NSUserDefaults+DemoSettings.h"

@class DemoMessagesViewController;

@interface ChatViewController : JSQMessagesViewController


@property (weak, nonatomic) IBOutlet UILabel *tvStatus;

@property (weak, nonatomic) IBOutlet UITextView *tfOutput;
@property (weak, nonatomic) IBOutlet UITextField *tfInput;
@property (weak, nonatomic) IBOutlet UITextField *tfName;
@property (weak, nonatomic) IBOutlet UITextField *nameedit;




- (IBAction)btnSend:(id)sender;



@property (strong, nonatomic) DemoModelData *demoData;
- (void)receiveMessagePressed:(UIBarButtonItem *)sender;

- (void)closePressed:(UIBarButtonItem *)sender;
@end
