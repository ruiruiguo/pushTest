# pushTest
iOS 推送语音播报（类似支付宝微信的收款提醒）

.通过远程推送，在iOS10的时候，发布了UNNotificationServiceExtension扩展，关于此扩展，可以网上选择一些资料iOS10 推送extension之 Service Extension，主要的核心思想就是，在远程推送到底设备之前，给你一个修改的机会，我们知道，推送体是有限制的，而且推送体大小也会影响推送的效率，借助这个，我们可以修改标题、内容，也可以从网络上请求到内容，再去合成一个新的推送。

接下来就是实现手机接收到通知之后播报语音了，关于这个功能的实现在iOS10以后苹果新增了“推送拓展”UNNotificationServiceExtension，我们可以在这里操作，在这里我用的是苹果官方的AVSpeechSynthesizer和AVSpeechUtterance来将接收到的推送内容转换成语音播报

貌似没啥问题，但是iOS12.1以后，不在允许在UNNotificationServiceExtension中播放语音了，只有系统提示音，阿欧。。。心好累。。。，没办法只好先在想办法，上网查找资料发现前辈们果然有解决办法，哈哈。。。

1.配置远程推送

2.在收到远程推送时，调用本地推送

3.把播报金额拆分成，一、二、三，四、五...千、百、万、点、元等一个个音频文件，根据推送过来的金额进行进行筛选然后按照顺序放入数组，具体的在下面有介绍（caculateNumber方法处理）

4.循环（递归）发送本地推送播放项目中的音乐文件


详情参考文章：https://blog.csdn.net/baidu_25743639/article/details/108881999
