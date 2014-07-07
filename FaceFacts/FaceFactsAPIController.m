//
//  FacePlusPlusAPIController.m
//  FaceFacts
//
//  Created by Jerrad Thramer on 5/12/14.
//  Copyright (c) 2014 JerradThramer. All rights reserved.
//

#import "FaceFactsAPIController.h"

#import "UNIRest.h"
#import "DejalActivityView.h"


@implementation FaceFactsAPIController
- (instancetype)initWithDelegate:(id)delegate
{
    if (self = [super init]) {
        [self setDelegate:delegate];
    }
    return self;
}
//------------------------------------------------------------------------------------------
- (void)sendImage:(UIImage *)image
{
    [[self delegate] apiController:self willUploadPicture:image];
    [self uploadImageToImgur:image];
}
//------------------------------------------------------------------------------------------
- (void)uploadImageToImgur:(UIImage*)image
{
    
    __block typeof(self) weakSelf = self;
    [[UNIRest post:^(UNISimpleRequest* request) {
        NSString *imgurID = [NSString stringWithFormat: @"Client-ID %@", IMGUR_ID];
        NSDictionary* headers = @{@"Authorization": imgurID};
        NSString *base64Image = [[self class] base64forData:UIImageJPEGRepresentation(image, 1.0)];
        NSDictionary* parameters = @{@"image": base64Image};
        
        [request setUrl:@"https://api.imgur.com/3/image"];
        [request setHeaders:headers];
        [request setParameters:parameters];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // This is the asyncronous callback block
        if (response && ([[[response body] JSONObject][@"status"] isEqualToNumber:@200] ) && !error )
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[weakSelf delegate] apiController:weakSelf didSucessfullyUploadPicture:image];
            });
            
            
            UNIJsonNode* body = [response body];
            NSDictionary *dataDict = [body JSONObject][@"data"];
            NSString *link = dataDict[@"link"];
            
            NSLog(@"link:%@", link);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self sendLinkToFacePlusPlus:link];
            });
            
        }
        else // we got an error
        {
            if ([[weakSelf delegate] respondsToSelector:@selector(apiController:didFailToUploadPictureWithError:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[weakSelf delegate] apiController:weakSelf didFailToUploadPictureWithError:error];
                });
                
            }
        }
        
    }];
}
//------------------------------------------------------------------------------------------
- (void)sendLinkToFacePlusPlus:(NSString *)link
{
    
    [FaceppAPI initWithApiKey: FPP_API_KEY andApiSecret: FPP_API_SECRET andRegion:APIServerRegionUS];
    
    
    //but of course they would be doing syncronous requests. Who wouldn't want to block the main thread? grr...
    dispatch_queue_t facePlusPlusQueue = dispatch_queue_create("com.jerrad.faceppQueue", DISPATCH_QUEUE_CONCURRENT);
    __block typeof(self) weakSelf = self;
    dispatch_async(facePlusPlusQueue, ^{
        FaceppResult* result = [[FaceppAPI detection] detectWithURL:link
                                                        orImageData:nil
                                                               mode:FaceppDetectionModeOneFace
                                                          attribute:FaceppDetectionAttributeAll];
        
        if (result && result.success && ![result error])
        {
            NSArray *faceArray = [result content][@"face"];
            if (![faceArray count]) {
                if ([[weakSelf delegate] respondsToSelector:@selector(apiControllerDidFailToFindFace:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[weakSelf delegate] apiControllerDidFailToFindFace:weakSelf];
                    });
                    
                }
            }
            else //we got no faces
            {
                NSDictionary *faceAttributes = faceArray[0][@"attribute"];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[weakSelf delegate] apiController:weakSelf didRecieveReplyFromFPP:faceAttributes];
                });
            }
        }
        else //we got some other kind of error
        {
            if ([[weakSelf delegate] respondsToSelector:@selector(apiController:didFailToRecieveReplyFromFPPWithError:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[weakSelf delegate] apiController:weakSelf didFailToRecieveReplyFromFPPWithError:[result error]];
                });
                
            }
        }
        
    });
    
}
//------------------------------------------------------------------------------------------
// Stolen from StackOverflow. It's your generic base64ForData method.
+ (NSString*)base64forData:(NSData*)theData
{
    const uint8_t* input = (const uint8_t*)[theData bytes];
    NSInteger length = [theData length];
    
    static char table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
    
    NSMutableData* data = [NSMutableData dataWithLength:((length + 2) / 3) * 4];
    uint8_t* output = (uint8_t*)data.mutableBytes;
    
    NSInteger i;
    for (i=0; i < length; i += 3) {
        NSInteger value = 0;
        NSInteger j;
        for (j = i; j < (i + 3); j++) {
            value <<= 8;
            
            if (j < length) {
                value |= (0xFF & input[j]);
            }
        }
        
        NSInteger theIndex = (i / 3) * 4;
        output[theIndex + 0] =                    table[(value >> 18) & 0x3F];
        output[theIndex + 1] =                    table[(value >> 12) & 0x3F];
        output[theIndex + 2] = (i + 1) < length ? table[(value >> 6)  & 0x3F] : '=';
        output[theIndex + 3] = (i + 2) < length ? table[(value >> 0)  & 0x3F] : '=';
    }
    
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] ;
}
@end