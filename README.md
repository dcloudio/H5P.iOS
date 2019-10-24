# iOS平台5+App/uni-app运行环境开源项目

**开源项目需与HBuilderX2.3.6-20191020配套使用**

## 模块与源码对应关系
| 文件夹 | 说明 | 5+APP项目 | uni-app项目 |
|:-------|:-------| :-------|:-------|
| DCUniBarcode		|barcode（uni原生插件）| |[https://uniapp.dcloud.io/api/system/barcode](https://uniapp.dcloud.io/api/system/barcode)
| DCUniZXing			|barcode 依赖库| |
| DCUniCanvas			|canvas (uni原生插件)| |
| DCUniFaceID			|FaceID (uni原生插件)| |[https://uniapp.dcloud.io/api/other/authentication](https://uniapp.dcloud.io/api/other/authentication)
| DCUniMap			|地图基础库| |
| DCUniAmap			|高德地图（uni原生插件）| |
| DCUniVideo			|视频播放器（uni原生插件）| |[https://uniapp.dcloud.io/api/media/video](https://uniapp.dcloud.io/api/media/video)
| DCUniVideoPublic  |视频播放器 依赖库| |
| libAccelerometer	|传感器模块|[plus.accelerometer](https://www.html5plus.org/doc/zh_cn/accelerometer.html)|[https://uniapp.dcloud.io/api/system/compass](https://uniapp.dcloud.io/api/system/compass)
| libBarcode			|barcode|[plus.barcode](https://www.html5plus.org/doc/zh_cn/barcode.html) |[https://uniapp.dcloud.io/api/system/barcode](https://uniapp.dcloud.io/api/system/barcode)
| libBeacon			|ibeacon|[plus.ibeacon](https://www.html5plus.org/doc/zh_cn/ibeacon.html) |[https://uniapp.dcloud.io/api/system/ibeacon](https://uniapp.dcloud.io/api/system/ibeacon)
| libBlueTooth		|蓝牙模块		|[plus.bluetooth](https://www.html5plus.org/doc/zh_cn/bluetooth.html) |[https://uniapp.dcloud.io/api/system/bluetooth](https://uniapp.dcloud.io/api/system/bluetooth)
| libCamera			|camera模块	|[plus.camera](https://www.html5plus.org/doc/zh_cn/camera.html) |[https://uniapp.dcloud.io/api/media/video ](https://uniapp.dcloud.io/api/media/video) [https://uniapp.dcloud.io/api/media/image](https://uniapp.dcloud.io/api/media/image)
| libContacts			|通讯录操作	|[plus.contacts](https://www.html5plus.org/doc/zh_cn/contacts.html) |[https://uniapp.dcloud.io/api/system/contact](https://uniapp.dcloud.io/api/system/contact)
| libFingerprint		|指纹识别	|[plus.fingerprint](https://www.html5plus.org/doc/zh_cn/fingerprint.html) |[https://uniapp.dcloud.io/api/other/authentication](https://uniapp.dcloud.io/api/other/authentication)
| libGeolocation		|定位基础	|[plus.geolocation](https://www.html5plus.org/doc/zh_cn/geolocation.html) |[https://uniapp.dcloud.io/api/location/location](https://uniapp.dcloud.io/api/location/location)
| libIO				|文件操作	|[plus.io](https://www.html5plus.org/doc/zh_cn/io.html) |[https://uniapp.dcloud.io/api/file/file](https://uniapp.dcloud.io/api/file/file)
| libMap				|地图基础库 |[plus.map](https://www.html5plus.org/doc/zh_cn/maps.html)| [https://uniapp.dcloud.io/api/location/map](https://uniapp.dcloud.io/api/location/map) 
| AMapImp				|高德德图  |[plus.map](https://www.html5plus.org/doc/zh_cn/maps.html)|
| bmapimp				|百度地图	|[plus.map](https://www.html5plus.org/doc/zh_cn/maps.html)|
| libMedia			|audio 	| [plus.audio](https://www.html5plus.org/doc/zh_cn/audio.html) |[https://uniapp.dcloud.io/api/media/record-manager](https://uniapp.dcloud.io/api/media/record-manager) [https://uniapp.dcloud.io/api/media/audio-context](https://uniapp.dcloud.io/api/media/audio-context)
| libMessage			|通讯管理	| [plus.messaging](https://www.html5plus.org/doc/zh_cn/messaging.html) |
| libNativeUI		   	|nativeUI |[plus.nativeUI](https://www.html5plus.org/doc/zh_cn/nativeui.html) |
| libOauth			|授权登录基础	|[plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) |[https://uniapp.dcloud.io/api/plugins/login](https://uniapp.dcloud.io/api/plugins/login)
| MiOauth 			|小米授权登录|[plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html) |
| QQOauth				|QQ授权登录|[plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html)|
| SinaWBOauth			|新浪微博授权登录|[plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html)|
| WXOauth				|微信授权登录|[plus.oauth](https://www.html5plus.org/doc/zh_cn/oauth.html)|
| libOrientation    |管理设备的方向信息|[plus.orientation](https://www.html5plus.org/doc/zh_cn/orientation.html)|
| libPayment			|支付基础模块|[plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html)|[https://uniapp.dcloud.io/api/plugins/payment](https://uniapp.dcloud.io/api/plugins/payment)
| alixpayment 		|支付宝支付|[plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html)|
| IAPPay	 			|苹果支付|[plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html)|
| wxpay 				|微信支付|[plus.payment](https://www.html5plus.org/doc/zh_cn/payment.html)|
| libPGProximity 	|管理设备距离传感器|[plus.proximity](https://www.html5plus.org/doc/zh_cn/proximity.html)|
| libPush				|推送基础库|[plus.push](https://www.html5plus.org/doc/zh_cn/push.html)|
| GeTuiPush			|个推推送|[plus.push](https://www.html5plus.org/doc/zh_cn/push.html)|
| XiaomiPush			|小米推送|[plus.push](https://www.html5plus.org/doc/zh_cn/push.html)|
| UniPush				|UniPush|[plus.push](https://www.html5plus.org/doc/zh_cn/push.html)|
| libShare			|分享基础库|[plus.share](https://www.html5plus.org/doc/zh_cn/share.html)|[https://uniapp.dcloud.io/api/plugins/share](https://uniapp.dcloud.io/api/plugins/share)
| QQShare				|QQ分享|[plus.share](https://www.html5plus.org/doc/zh_cn/share.html)|
| SinaShare			|新浪微博分享|[plus.share](https://www.html5plus.org/doc/zh_cn/share.html)|
| TencentShare		|腾讯微博分享|[plus.share](https://www.html5plus.org/doc/zh_cn/share.html)|
| weixinShare			|微信分享|[plus.share](https://www.html5plus.org/doc/zh_cn/share.html)|
| libSpeech			|语音识别基础库	|[plus.speech](https://www.html5plus.org/doc/zh_cn/speech.html)|[https://uniapp.dcloud.io/api/plugins/voice](https://uniapp.dcloud.io/api/plugins/voice)
| baiduSpeech			|百度语音识别|[plus.speech](https://www.html5plus.org/doc/zh_cn/speech.html)|
| iflySpeech			|讯飞语音识别|[plus.speech](https://www.html5plus.org/doc/zh_cn/speech.html)|
| libStatistic		|统计功能|[plus.statistic](https://www.html5plus.org/doc/zh_cn/statistic.html)|
| libVideo			|videoplayer视频模块|[plus.video.*](https://www.html5plus.org/doc/zh_cn/video.html) |[https://uniapp.dcloud.io/api/media/video](https://uniapp.dcloud.io/api/media/video)
| libXHR				|网络请求模块		|[plus.net](https://www.html5plus.org/doc/zh_cn/xhr.html) |
| libZip				|文件压缩和解压		|[plus.zip](https://www.html5plus.org/doc/zh_cn/zip.html)


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
