# iOS平台5+App/uni-app运行环境开源项目

**重要：请使用HBuilderX2.3.6-20191020生成本地打包App资源，否则uni-app项目可能提示“运行环境版本和编译器版本不一致”，详情参考[https://ask.dcloud.net.cn/article/35627](https://ask.dcloud.net.cn/article/35627)**


## 说明
此次更新梳理了工程结构，现在开发者可以直接修改引擎中的代码，自主编译出新的引擎。

如果开发者要修改本工程源码，请注意“引擎”和“插件”的分界线。
“引擎”是对5+/uni-app规范的实现，修改引擎源码可以优化对规范的实现，但不是提供规范外的功能。规范外的功能，应该做成“插件”。如需公开，则放到[插件市场](https://ext.dcloud.net.cn/)。
比如扫码，5+/uni-app的规范已经存在，但开发者对扫码效率不满意，提供自己更好的实现，则可以改动本源码，重新Build引擎。
而如果是想新增一个ar功能，则应该做成插件，而不是加入到本工程中。即，开发者不能自主新增5+/uni-app的js API规范。

任何一个项目的源码，吃透整体都不是一件容易的事情。一般开发者有改动需求，也多集中在一些能力或SDK的实现上。
比如扫码、视频、地图、直播、摄像头、相册、蓝牙等，以及某些界面的文字。
只关注某些能力模块，吃透和修改会更加容易。

受精力所限，某些模块，比如DCloud定制过的weex源码，还未规整好，暂时以库的方式提供，未来会提供完整源码。不过这不影响开发者修改其他源码和编译工程。


## 模块与源码对应关系
| 功能模块                  | 源码目录                  | 5+APP项目                | uni-app项目              |
| :-------                | :-------                | :-------                | :-------                |
| Accelerometer(加速度传感器)   | libAccelerometer      | [plus.accelerometer](https://www.html5plus.org/doc/zh_cn/accelerometer.html) | https://uniapp.dcloud.io/api/system/compass |
| Audio(音频)                  | libMedia              | [plus.audio](https://www.html5plus.org/doc/zh_cn/audio.html) | https://uniapp.dcloud.io/api/media/record-manager https://uniapp.dcloud.io/api/media/audio-context |
| Barcode(二维码)              | libBarcode            | [plus.barcode](https://www.html5plus.org/doc/zh_cn/barcode.html) | https://uniapp.dcloud.io/api/system/barcode |
| Bluetooth(低功耗蓝牙)        | libBlueTooth          | [plus.bluetooth](https://www.html5plus.org/doc/zh_cn/bluetooth.html) | https://uniapp.dcloud.io/api/system/bluetooth |
| Camera(摄像头)               | libCamera             | [plus.camera](https://www.html5plus.org/doc/zh_cn/camera.html) | https://uniapp.dcloud.io/api/media/image |
| Contacts(通讯录)             | libContacts           | [plus.contacts](https://www.html5plus.org/doc/zh_cn/contacts.html) | https://uniapp.dcloud.io/api/system/contact |
| Fingerprint(指纹识别)        | libFingerprint        | [plus.fingerprint](https://www.html5plus.org/doc/zh_cn/fingerprint.html) | https://uniapp.dcloud.io/api/other/authentication |
| Geolocation(定位)           | libGeolocation         | [plus.geolocation](https://www.html5plus.org/doc/zh_cn/geolocation.html) | https://uniapp.dcloud.io/api/location/location |
| iBeacon                     | libBeacon             | [plus.ibeacon](https://www.html5plus.org/doc/zh_cn/ibeacon.html) | https://uniapp.dcloud.io/api/system/ibeacon |
| IO(文件系统)                 | libIO                 | [plus.io](https://www.html5plus.org/doc/zh_cn/io.html) | https://uniapp.dcloud.io/api/file/file |
| Maps(地图基础库)             | libMap                | [plus.map](https://www.html5plus.org/doc/zh_cn/maps.html) | https://uniapp.dcloud.io/api/location/map |
|Maps(高德德图)                | AMapImp               | [plus.map](https://www.html5plus.org/doc/zh_cn/maps.html) | https://uniapp.dcloud.io/api/location/map |
| Maps(百度地图)               | bmapimp               | [plus.map](https://www.html5plus.org/doc/zh_cn/maps.html) | https://uniapp.dcloud.io/api/location/map |
| Messaging(短彩邮件消息)       | libMessage            | [plus.messaging](https://www.html5plus.org/doc/zh_cn/messaging.html) |
|NativeUI(系统原生界面)         | libNativeUI	           | [plus.nativeUI](https://www.html5plus.org/doc/zh_cn/nativeui.html) |
| Oauth(登录基础库)             | libOauth              | [plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) | https://uniapp.dcloud.io/api/plugins/login |
| Oauth(小米登录)               | MiOauth              | [plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) | https://uniapp.dcloud.io/api/plugins/login |
| Oauth(QQ登录)                 | QQOauth              | [plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) | https://uniapp.dcloud.io/api/plugins/login |
| Oauth(新浪微博登录)            | SinaWBOauth          | [plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) | https://uniapp.dcloud.io/api/plugins/login |
| Oauth(微信登录)                | WXOauth              | [plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) | https://uniapp.dcloud.io/api/plugins/login |
| Orientation(设备方向)          | libOrientation       | [plus.orientation](https://www.html5plus.org/doc/zh_cn/orientation.html) |
| Payment(支付基础库)            | libPayment           | [plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html) | https://uniapp.dcloud.io/api/plugins/payment |
| Payment(支付宝支付)            | alixpayment          | [plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html) | https://uniapp.dcloud.io/api/plugins/payment |
| Payment(苹果应用内支付)        | IAPPay	               | [plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html) | https://uniapp.dcloud.io/api/plugins/payment |
| Payment(微信支付)              | wxpay                | [plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html) | https://uniapp.dcloud.io/api/plugins/payment |
| Push(推送基础库)               | libPush              | [plus.push](https://www.html5plus.org/doc/zh_cn/push.html) | https://uniapp.dcloud.io/api/plugins/push |
| Push(个推推送)                 | GeTuiPush            | [plus.push](https://www.html5plus.org/doc/zh_cn/push.html) | https://uniapp.dcloud.io/api/plugins/push |
| Push(小米推送)                 | XiaomiPush           | [plus.push](https://www.html5plus.org/doc/zh_cn/push.html) | https://uniapp.dcloud.io/api/plugins/push |
| Push(UniPush推送)             | UniPush               | [plus.push](https://www.html5plus.org/doc/zh_cn/push.html) | https://uniapp.dcloud.io/api/plugins/push |
| Proximity(距离传感器)          | libPGProximity        | [plus.proximity](https://www.html5plus.org/doc/zh_cn/proximity.html) |
| Share(分享基础库)              | libShare              | [plus.share](https://www.html5plus.org/doc/zh_cn/share.html) | https://uniapp.dcloud.io/api/plugins/share |
| Share(QQ分享)                 | QQShare               | [plus.share](https://www.html5plus.org/doc/zh_cn/share.html) | https://uniapp.dcloud.io/api/plugins/share |
| Share(新浪微博分享)            | SinaShare             | [plus.share](https://www.html5plus.org/doc/zh_cn/share.html) | https://uniapp.dcloud.io/api/plugins/share |
| Share(微信分享)                | weixinShare           | [plus.share](https://www.html5plus.org/doc/zh_cn/share.html) | https://uniapp.dcloud.io/api/plugins/share |
| Speech(语音识别基础库)          | libSpeech	            | [plus.speech](https://www.html5plus.org/doc/zh_cn/speech.html) | https://uniapp.dcloud.io/api/plugins/voice |
| Speech(百度语音识别)           | baiduSpeech           | [plus.speech](https://www.html5plus.org/doc/zh_cn/speech.html) | https://uniapp.dcloud.io/api/plugins/voice |
| Speech(讯飞语音识别)            | iflySpeech           | [plus.speech](https://www.html5plus.org/doc/zh_cn/speech.html) | https://uniapp.dcloud.io/api/plugins/voice |
| Statistic(友盟统计)             | libStatistic         | [plus.statistic](https://www.html5plus.org/doc/zh_cn/statistic.html) |
| VideoPlayer(视频播放)           | libVideo             | [plus.video.VideoPlayer](https://www.html5plus.org/doc/zh_cn/video.html#plus.video.VideoPlayer) | https://uniapp.dcloud.io/api/media/video |
| XHR(网络请求)                   | libXHR               | [plus.net](https://www.html5plus.org/doc/zh_cn/xhr.html) | https://uniapp.dcloud.io/api/request/request?id=request |
| Zip(文件压缩和解压)	             | libZip               | [plus.zip](https://www.html5plus.org/doc/zh_cn/zip.html) |
| nvue原生组件: barcode(二维码)    | DCUniBarcode         | 不支持 | https://uniapp.dcloud.io/component/barcode |
| nvue原生组件: map(地图基础库)    | DCUniMap             | 不支持 | https://uniapp.dcloud.io/component/map |
| nvue原生组件: map(高德地图)      | DCUniAmap            | 不支持 | https://uniapp.dcloud.io/component/map |
| nvue原生组件: video(视频)        | DCUniVideo           | 不支持 | https://uniapp.dcloud.io/component/video |
| nvue原生组件: canvas            | DCUniCanvas          | 不支持 | https://github.com/dcloudio/NvueCanvasDemo |
| nvue原生模块: FaceID            | DCUniFaceID          | 不支持 | https://uniapp.dcloud.io/api/other/authentication |



## 运行方式

1. 将工程 clone 到本地（或直接下载zip）；
2. 由于源码依赖了一些第三方库超过限制，无法上传请下载 [离线sdk](https://ask.dcloud.net.cn/docs/#//ask.dcloud.net.cn/article/103) 包，解压打开 SDK/Libs 目录，将以下库手动将库复制到本工程的 SDK/Libs 下，然后编译运行即可

	- libBaiduSpeechSDK.a
	- liblibWeex.a
	- MAMapKit.framework

## 许可协议
本工程大部分源码开源，使用者可以自主修改已公开的源码，编译新版本。
但注意：

1. 您不能破解、反向工程、反编译本项目下未开源的各种库文件。
2. 未经DCloud书面许可，您不得利用本项目的全部或部分源码、文件来制作与DCloud根据本项目提供的服务相竞争的产品，例如提供自主品牌的开发者服务。
3. DCloud所拥有的知识产权，包括但不限于商标、专利、著作权，并不发生转移或共享。
4. 您基于本项目，自主开发的代码及输出物，其知识产权归属您所有。除非您通过提交pull request的方式将自己的代码开源。
5. 如果您没有违反本许可协议，那么你使用本项目将无需为DCloud支付任何费用。
