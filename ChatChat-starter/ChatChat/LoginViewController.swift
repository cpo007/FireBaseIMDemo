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
class LoginViewController: UIViewController {
    
    var ref: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = FIRDatabase.database().referenceFromURL("https://fir-demo-43879.firebaseio.com/")
        
    }

  @IBAction func loginDidTouch(sender: AnyObject) {
    FIRAuth.auth()?.signInAnonymouslyWithCompletion({ (user, error) in
        if error != nil { print(error?.description); return }
        print(user?.uid)
        print(user?.refreshToken)
        self.performSegueWithIdentifier("LoginToChat", sender: nil) // 3
        
    })
  }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        guard let naV = segue.destinationViewController as? UINavigationController else { return }
        guard let chatVC = naV.viewControllers.first as? ChatViewController else { return }
        chatVC.senderId = FIRAuth.auth()?.currentUser?.uid
        chatVC.senderDisplayName = ""
    }
  
}

