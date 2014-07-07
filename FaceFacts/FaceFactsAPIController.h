//
//  FacePlusPlusAPIController.h
//  FaceFacts
//
//  Created by Jerrad Thramer on 5/12/14.
//  Copyright (c) 2014 JerradThramer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FaceppAPI.h"

//To make this application work, you are going to need both a FacePlusPlus API Key/Secret,
//  and a Imgur api ID. Either comment the keys.h and uncomment the macro's below or include them in your
//  own keys.h file.
//
//  FacePlusPlus Signup:    http://www.faceplusplus.com/uc/people/signup
//  Imgur Signup:           https://api.imgur.com/
#import "keys.h"
//#define FPP_API_KEY @"key"
//#define FPP_API_SECRET @"secret"
//#define IMGUR_ID @"imgur"


@protocol FaceFactsAPIDelegate <NSObject>

@required
- (void)apiController:(id)controller willUploadPicture:(UIImage *)pic;
- (void)apiController:(id)controller didSucessfullyUploadPicture:(UIImage *)pic;
- (void)apiController:(id)controller didRecieveReplyFromFPP:(NSDictionary *)reply;

@optional
- (void)apiController:(id)controller didFailToUploadPictureWithError:(NSError *)error;
- (void)apiController:(id)controller didFailToRecieveReplyFromFPPWithError:(FaceppError *)error;
- (void)apiControllerDidFailToFindFace:(id)controller;
@end

@interface FaceFactsAPIController : NSObject
@property (nonatomic, weak) id <FaceFactsAPIDelegate> delegate;

- (instancetype)initWithDelegate:(id)delegate;

- (void)sendImage:(UIImage *)image;

@end



