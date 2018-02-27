//
//  ViewController.m
//  ImageUploadDemo
//
//  Created by pengpeng yan on 16/3/15.
//  Copyright © 2016年 peng yan. All rights reserved.
//

#import "ViewController.h"
#import "AFNetworking.h"
@interface ViewController ()<UIActionSheetDelegate,UIGestureRecognizerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property(nonatomic,strong)UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadImageView];
}

- (void)loadImageView{
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(100, 50, 100, 100)];
    self.imageView.backgroundColor = [UIColor grayColor];
    self.imageView.userInteractionEnabled = YES;//开启用户交互
    [self.view addSubview:self.imageView];
    
    //添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(ImageAction:)];
    [self.imageView addGestureRecognizer:tap];

}

- (void)ImageAction:(UITapGestureRecognizer *)gesture{
    UIActionSheet *sheet;
   //判断是否支持相机
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        sheet = [[UIActionSheet alloc] initWithTitle:@"选择" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"拍照",@"从相册选择", nil];
    }else{
        sheet = [[UIActionSheet alloc] initWithTitle:@"选择" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"取消" otherButtonTitles:@"从相册选择", nil];
    }
    [sheet showInView:self.view];
}
#pragma mark - ActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
     NSUInteger sourceType = 0;
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        switch (buttonIndex) {
            case 0:
                return;
                break;
            case 1:
                sourceType = UIImagePickerControllerSourceTypeCamera;//相机
                break;
            case 2:
                sourceType = UIImagePickerControllerSourceTypePhotoLibrary;// 相册
                break;
            default:
                break;
        }
    }else{
        if (buttonIndex == 0) {
            return;
        }else{
            sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
           
        }
    
    }
    UIImagePickerController *imagePickerVC = [[UIImagePickerController alloc] init];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    imagePickerVC.sourceType = sourceType;
    [self presentViewController:imagePickerVC animated:YES completion:nil];

}

#pragma mark - ImagePickerControllerDelegate
// 图片选择结束之后，走这个方法，字典存放所有图片信息
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    [picker dismissViewControllerAnimated:YES completion:nil];//选完退出图片控制器
    
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    //01.21 应该在提交成功后再保存到沙盒，下次进来直接去沙盒路径取
    
    // 保存图片至本地，方法见下文
    [self saveImage:image withName:@"currentImage.png"];
    //读取路径进行上传
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"currentImage.png"];
    UIImage *savedImage = [[UIImage alloc] initWithContentsOfFile:fullPath];
    
    
    [self.imageView setImage:savedImage];//图片赋值显示
    
    //进到次方法时 调 UploadImage 方法上传服务端
    NSDictionary *dic = @{@"image":fullPath};
    [self UploadImage:dic];

}

#pragma mark - 保存图片至沙盒（应该是提交后再保存到沙盒,下次直接去沙盒取）
- (void) saveImage:(UIImage *)currentImage withName:(NSString *)imageName
{
    
    NSData *imageData = UIImageJPEGRepresentation(currentImage, 0.5);
    // 获取沙盒目录
    
    NSString *fullPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:imageName];
    // 将图片写入文件
    
    [imageData writeToFile:fullPath atomically:NO];
}

//图频上传

-(void)UploadImage:(NSDictionary *)dic
{
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    //网址
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    
    [manager POST:@"http://112.74.67.161:8080/foodOrder/service/file/upload.do" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        //01.21 测试
        NSString * imgpath = [NSString stringWithFormat:@"%@",dic[@"image"]];
        
        UIImage *image = [UIImage imageWithContentsOfFile:imgpath];
        NSData *data = UIImageJPEGRepresentation(image,0.7);
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.jpg", str];
        
        [formData appendPartWithFileData:data name:@"Filedata" fileName:fileName mimeType:@"image/jpg"];
        
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //成功 后处理。
        NSLog(@"Success: %@", responseObject);
        NSString * str = [responseObject objectForKey:@"fileId"];
        if (str != nil) {
            //            [self.delegate uploadImgFinish:str];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        //失败
        NSLog(@"Error: %@", error);
    }];
    
    
    
}








@end
