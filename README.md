ZCSAvatarCapture
=================

You've got user avatars in your app. You probably don't have user avatar editing as nice as this.

## Add to your Podfile

`pod 'ZCSAvatarCapture', '~> 0.0.6'`

## Use in your project

### Setup

```obj-c
#import "ZCSAvatarCaptureController.h"

ZCSAvatarCaptureController *avatarCaptureController = [[ZCSAvatarCaptureController alloc] init];
avatarCaptureController.delegate = self;
avatarCaptureController.image = [UIImage imageNamed:@"model-001.jpg"]; // Use your current avatar image here
[self.avatarView addSubview:self.avatarCaptureController.view]; // self.avatarView is a placeholder on the Storyboard in this example
```

### Capture
```obj-c
- (void)imageSelected:(UIImage *)image {
	// Do something with your user's new avatar image
}
```

## Screenshots ##

![Example App with Avatar](/../screenshots/one.png?raw=true "Example App with Avatar")
![Example with Camera](/../screenshots/two.png?raw=true "Example with Camera")
![Example with Photo](/../screenshots/three.png?raw=true "Example with Photo")
![Example App after Avatar](/../screenshots/four.png?raw=true "Example App after Avatar")

## Contributing ##

Send me Pull Requests here, please.