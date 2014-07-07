FaceFacts 1.0
==================
Jerrad Thramer 2014


Abstract
FaceFacts is a fun little sample app that allows you to take a “Selfie”, uploads it to Imgur, and then uses the FacePlusPlus Computer Vision API to determine statistics (age, sex, race, etc) about the user. 

General Notes
-This app was rapidly prototyped in an afternoon using code from Apple’s “AVCam” Sample App, as well as several open source libraries listed below.
-This app was created with robustness in mind. Try to break it!
-Keep in mind that any selfie you take with this app is being uploaded to Imgur.
*-Note: You will need FacePlusPlus and Imgur API credentials for this app to work. More information can be found in FaceFactsAPIController.h.*

Technical Notes
- Okay, I know, technically this is a two-view app, but considering that the AVCameraView was more-or-less stolen directly from apple sample code, i’m considering the “ResultsView” my “single view.”
- You’ll notice that the FaceFactsAPIController makes heavy use of GCD and Asynchronous blocks. Unfortunately, as cool as the FacePlusPlus API is, their included SDK wrapper uses blocking synchronous requests to its API, and that is no bueno. So we wrap those calls in GCD and call it a day.

Known Limitations
- To keep the complexity of the project down, this app will only give you statistics for one face per selfie. If a selfie contains more then one face, it will return the statistics for the largest face in the photo.


Open Source Credits:
- SFGaugeView: https://github.com/simpliflow/SFGaugeView
- DejalActivityView: https://github.com/Dejal/DejalActivityView
- UniREST for Objective-C: http://unirest.io/objective-c.html
- FacePlusPlus SDK: https://github.com/FacePlusPlus/facepp-ios-sdk
