/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController {
    
    // MARK: Properties
    var messages = [JSQMessage]()
    var outgoingBubbleImgaeView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!
    let rootRef = FIRDatabase.database().referenceFromURL("https://fir-demo-43879.firebaseio.com/")
    var messageRef:FIRDatabaseReference!
    var userTypingQuery:FIRDatabaseQuery!
    
    var userIsTypingRef:FIRDatabaseReference! //1
    private var localTyping = false //2
    var isTyping: Bool {
        set{
            //3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
        get{
            return localTyping
        }
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ChatChat"
        setupBubbles()
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        messageRef = rootRef.child("messages")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeMessages()
        observeIsTyping()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    //设置气泡图片
    private func setupBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        outgoingBubbleImgaeView = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
        incomingBubbleImageView = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    }
    
    func addMessage(uid: String, text: String) {
        let message = JSQMessage(senderId: uid, displayName: "", text: text)
        messages.append(message)
    }
    
    //监听消息
    func observeMessages() {
        //1
        let messagesQuery = messageRef.queryLimitedToLast(25)
        //2
        messagesQuery.observeEventType(.ChildAdded) { [weak self] (snpaShot:FIRDataSnapshot) in
            //3
            guard let dict = snpaShot.value as? [String:AnyObject] else { return }
            guard let id = dict["senderId"] as? String else { return }
            guard let text = dict["text"] as? String else { return }
            //4
            self?.addMessage(id, text: text)
            //5
            self?.finishReceivingMessage()
        }
    }
    
    //监听输入
    func observeIsTyping() {
        let typingIndicatorRef = rootRef.child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(senderId)
        userIsTypingRef.onDisconnectRemoveValue()
        
        //1
        userTypingQuery = typingIndicatorRef.queryOrderedByValue().queryEqualToValue(true)
        //2
        userTypingQuery.observeEventType(.Value) { [weak self] (snapShot:FIRDataSnapshot) in
            if let weakself = self {
                
                //3 You're the only typing, don't show the indicator
                if snapShot.childrenCount == 1 && weakself.isTyping { return }
                
                // 4 Are there others typing?
                weakself.showTypingIndicator = snapShot.childrenCount > 1
                weakself.scrollToBottomAnimated(true)
            }
        }
    }
    
    //发送消息
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        let itemRef = messageRef.childByAutoId()
        let messageItem = [
        "text":text,
        "senderId":senderId
        ]
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
        isTyping = false
    }
    
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        isTyping = textView.text != ""
    }
    
}

extension ChatViewController {
    
    //返回消息数组
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    //设置不同发送者的气泡图片
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImgaeView
        } else {
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    //修改Cell颜色
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
         let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView.textColor = UIColor.whiteColor()
        } else {
            cell.textView.backgroundColor = UIColor.blackColor()
        }
        return cell
    }
}