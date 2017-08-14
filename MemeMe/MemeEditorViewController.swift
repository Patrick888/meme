//
//  MemeEditorViewController.swift
//  MemeMe
//
//  Created by Patrick on 7/27/17.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate  {
    @IBOutlet weak var topToolBar: UIToolbar!
    @IBOutlet weak var botToolBar: UIToolbar!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var albumButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var botTextField: UITextField!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        // disable cameraButton if the .camera source is not available.
        
        customizeTextField(topTextField)
        customizeTextField(botTextField)

        print("         viewDidLoad got called")


    }
    
    // MARK: customize the TexTField.
    func customizeTextField(_ textField:UITextField) {
        
        let memeTextAttributes:[String:Any] = [
            NSStrokeColorAttributeName: UIColor.black,
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 22)!,
            NSStrokeWidthAttributeName: -3]
        textField.delegate = self
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(true)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        print("     viewWillAppear got called")
        subscribeToKeyboardNotifications()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        print("     viewWillDisappear got called        ")
        unsubscribeFromKeyboardNotifications()
    }


    // move up keyboard for bottom TexTField
    func keyboardWillShow(_ notification:Notification) {
        print("     keyboardWillShow got called,the notification is \(notification)")
        if botTextField.isFirstResponder {
            view.frame.origin.y = 0 - getKeyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification:Notification) {
        print("     keyboardWillhide got called,the notification is \(notification) ")
        view.frame.origin.y = 0
    }
    
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        print("     getkeyboardHeight got called, userInfo = \(String(describing: userInfo)) and keyboardSize = \(keyboardSize)")
        return keyboardSize.cgRectValue.height
    }

    func subscribeToKeyboardNotifications() {
        
        print("     subscribeToKeyboardNotifications() got called")
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    func unsubscribeFromKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    
    // open ImagePicker View Controller by album and camera buttons
    @IBAction func openImagePicker(_ sender: UIButton) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sender.tag == 1 ? .photoLibrary : .camera
        print("     imagePicker.sourceType is \(imagePicker.sourceType) and the sender is : \(sender)")
        present(imagePicker, animated: true, completion: nil)
        imagePicker.delegate = self
    }
    
    
    // open ActivityViewController by share button
    @IBAction func openShare(_ sender: Any) {
        let image = generateMemedImage()
        let nextcontroller = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(nextcontroller, animated: true, completion: nil)
        
        /* storing the memephoto data and dismiss in completion handler, put closure expression into the property completionWithItemsHandler
         open var completionWithItemsHandler: UIKit.UIActivityViewControllerCompletionWithItemsHandler? // set to nil after call
         public typealias UIActivityViewControllerCompletionWithItemsHandler = (UIActivityType?, Bool, [Any]?, Error?) -> Swift.Void
         */
        
        nextcontroller.completionWithItemsHandler = {
            (activity,completed,returnedItems,activityError) -> Void in
            if completed {
                self.save()
                print(" \(memeArray.count)  read out the memeArray in SaveMeme.swift => \(memeArray)")
                //                self.dismiss(animated: true, completion: nil)
            }
        }

    }
    
    
    // MARK: Delegate Method. TWO buttons Camear and Album call Delegate method from UIImagePickerControllerDelegate protocol to pass the selected image to imageView.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = image
            print("  delegate method imagePickerController() got called and assigned the image to imageView.image")
        } else { print("read out NIL,failed to read out image from album") }
        picker.dismiss(animated: true, completion: nil)
    }
    
    
    /* Render views to an image :render view(the original image and overlayed text) into a UIIamge object and return that new UIImage.
     1. UIGraphicsBeginImageContext creates a bitmap and makes it as current context (like buffer)
     2. view.drawHierarchy sanpshot the all visilbe items and save to the current context
     3. UIGraphicsGetImageFromCurrentImageContext raed out the image from the current context
     4. UIGraphicsEndImageContext close the current context.
     */

    func generateMemedImage() -> UIImage {
        
        botToolBar.isHidden = true
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        print("call rendering, what is view : ", type(of: view))
        botToolBar.isHidden = false
        return memedImage
    }
    
    
    // MARK: delegate method textFieldShouldReturn (UITextFieldDelegate protocol) to hide keyboard after tapping rerturn key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return false // both false and true work here.
    }

    // MARKS: save the new rendered image to struct for future use
    func save() {
        
        let memedImage = generateMemedImage()
        let meme = Meme(topText: topTextField.text!, bottomText: botTextField.text!, originalImage: imageView.image!, memedImage: memedImage)
        memeArray.append(meme)
        print("struct Meme store the property, the toptex is :", meme.topText)
    }

    
}

