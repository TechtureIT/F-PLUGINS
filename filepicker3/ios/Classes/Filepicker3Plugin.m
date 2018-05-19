#import "Filepicker3Plugin.h"




@implementation Filepicker3Plugin


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"filepicker3"
            binaryMessenger:[registrar messenger]];



  Filepicker3Plugin* instance = [[Filepicker3Plugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

   if ([@"selectFile" isEqualToString:call.method]) {

       //result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);


        UIDocumentMenuViewController *documentProviderMenu =
        [[UIDocumentMenuViewController alloc] initWithDocumentTypes:[self UTIs]
                                                             inMode:UIDocumentPickerModeImport];

        documentProviderMenu.delegate = self;
        [self presentViewController:documentProviderMenu animated:YES completion:nil];

     }else if ([@"getPlatformVersion" isEqualToString:call.method]) {

    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
