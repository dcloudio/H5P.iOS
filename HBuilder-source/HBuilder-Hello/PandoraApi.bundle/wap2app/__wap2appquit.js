!(function() {
    console.log('W2A[launchWebview]:wap2appquit');
    if (!window.wap2app) {
        console.log('W2A[launchWebview]:wap2appquit[wap2app is undefined]');
        return;
    }

    var ID = '__W2A_QUIT_IFRAME';
    var FEEDBACK_ID = '__W2A_FEEDBACK';
    //var REVERSE_VENDORS = ['HTC', 'Sony', 'LGE', 'HUAWEI','Meizu'];
    var REVERSE_VENDORS = ['SONY', 'HTC', 'LGE', 'MOTOROLA'];
    var REVERSE_NEXUS_MODEL = 'NEXUS';

    var isReverse = function() {
        var vendor = plus.device.vendor.toUpperCase();
        var model = plus.device.model.toUpperCase();
        if (~REVERSE_VENDORS.indexOf(vendor)) {
            return true;
        }
        if (~model.indexOf(REVERSE_NEXUS_MODEL)) {
            return true;
        }
        return false;
    };
    /**
     * 打开反馈页面
     */
    var openFeedback = function() {
        plus.nativeUI.showWaiting();
        var feedbackOptions = wap2app.getW2AOptions().globalOptions.feedback;
        var url = feedbackOptions.url;
        var params = feedbackOptions.params;
        if (typeof params === 'function') {
            params = params();
        }
        if (wap2app.util.isObject(params)) {
            url = wap2app.ajax.appendQuery(url, wap2app.extend(params, {
                p: plus.os.name === 'Android' ? 'a' : plus.os.name === 'iOS' ? 'i' : '',
                plus_version: plus.runtime.innerVersion,
                vendor: plus.device.vendor,
                md: plus.device.model
            }));
        }
        var feedbackWebview = plus.webview.create(url, FEEDBACK_ID);
        feedbackWebview.addEventListener('titleUpdate', function() {
            plus.nativeUI.closeWaiting();
            feedbackWebview.show('slide-in-right', 300);
        });
    };
    /**
     * 退出应用
     */
    var quit = function() {
        plus.runtime.quit();
    };

    wap2app.plusReady(function() {
        console.log('W2A[launchWebview]:wap2appquit[plusready]');
        var confirm = wap2app.confirm;
        plus.runtime.getProperty(plus.runtime.appid, function(wgtinfo) {
            console.log('W2A[launchWebview]:wap2appquit[' + wgtinfo.name + ']');
            wap2app.domReady(function() {
                confirm.init({
                    id: ID,
                    html: '<!DOCTYPE html><html><head><meta charset=UTF-8><meta name=viewport content="initial-scale=1,maximum-scale=1,user-scalable=no"><style>.mui-confirm{display:none;position:fixed;top:0;left:0;width:100%;height:100%;text-align:center;background-color:rgba(0,0,0,.3);z-index:10000}.mui-confirm *{-webkit-box-sizing:border-box;box-sizing:border-box;-webkit-user-select:none;outline:0;-webkit-tap-highlight-color:transparent;-webkit-tap-highlight-color:transparent}.mui-confirm.mui-active{display:block}.mui-confirm-inner{position:fixed;left:0;bottom:0;width:100%}.mui-confirm-header{position:relative;background-image:url(data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%2C0%2C360%2C33%22%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%3Cpath%20d%3D%22M0%2033%20C%200%2033%2C%20180%20-33%2C%20360%2033%22%20stroke%3D%22%23dcdcdc%22%20fill%3D%22%23fff%22%20%2F%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%3C%2Fsvg%3E);background-repeat:no-repeat;background-size:100%;background-position:center bottom;padding-bottom:9.167%}.mui-confirm-header .mui-confirm-icon{position:absolute;left:50%;top:-15px;-webkit-transform:translate(-50%,0);transform:translate(-50%,0);width:45px;height:45px;background-color:#50a2ef;border-radius:50%;padding:6px 12px;z-index:1}.mui-confirm-header .mui-confirm-icon:before{position:absolute;display:block;content:\' \';left:11px;top:11px;width:23px;height:23px}.mui-confirm-icon-exclamation:before,.mui-confirm-icon-question:before{background-size:cover;background-repeat:no-repeat;background-position:center center}.mui-confirm-icon-question:before{background-image:url(data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20style%3D%22max-height%3A100%25%3Bmax-width%3A100%25%3B%22%20viewBox%3D%220%200%2031.357%2031.357%22%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%3Cpath%20d%3D%22M15.255%2C0c5.424%2C0%2C10.764%2C2.498%2C10.764%2C8.473c0%2C5.51-6.314%2C7.629-7.67%2C9.62c-1.018%2C1.481-0.678%2C3.562-3.475%2C3.562%20%20%20c-1.822%2C0-2.712-1.482-2.712-2.838c0-5.046%2C7.414-6.188%2C7.414-10.343c0-2.287-1.522-3.643-4.066-3.643%20%20%20c-5.424%2C0-3.306%2C5.592-7.414%2C5.592c-1.483%2C0-2.756-0.89-2.756-2.584C5.339%2C3.683%2C10.084%2C0%2C15.255%2C0z%20M15.044%2C24.406%20%20%20c1.904%2C0%2C3.475%2C1.566%2C3.475%2C3.476c0%2C1.91-1.568%2C3.476-3.475%2C3.476c-1.907%2C0-3.476-1.564-3.476-3.476%20%20%20C11.568%2C25.973%2C13.137%2C24.406%2C15.044%2C24.406z%22%20fill%3D%22%23FFFFFF%22%20%2F%3E%0D%0A%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%20%3C%2Fsvg%3E)}.mui-confirm-icon-exclamation:before{background-image:url(data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20style%3D%22max-height%3A100%25%3Bmax-width%3A100%25%3B%22%20viewBox%3D%220%200%2064%2064%22%3E%3Cg%20fill%3D%22%23ffffff%22%3E%3Cpath%20d%3D%22m26.948%2037.09c.243%202.531.655%204.412%201.222%205.653.574%201.237%201.593%201.854%203.064%201.854.275%200%20.521-.043.765-.093.25.05.495.093.772.093%201.467%200%202.489-.617%203.06-1.854.57-1.241.975-3.122%201.223-5.653l1.306-19.542c.243-3.809.367-6.542.367-8.201%200-2.258-.589-4.02-1.771-5.285-1.186-1.265-2.744-1.896-4.674-1.896-.103%200-.18.023-.281.027-.096-.004-.175-.027-.275-.027-1.934%200-3.489.631-4.673%201.896-1.183%201.267-1.776%203.03-1.776%205.286%200%201.659.121%204.392.368%208.201l1.303%2019.541%22%2F%3E%3Cpath%20d%3D%22m32.05%2051.74c-1.874%200-3.466.591-4.788%201.773-1.321%201.183-1.983%202.619-1.983%204.305%200%201.903.67%203.401%202%204.489%201.336%201.088%202.894%201.632%204.675%201.632%201.813%200%203.394-.536%204.746-1.611%201.35-1.072%202.025-2.578%202.025-4.508%200-1.686-.646-3.122-1.938-4.305-1.292-1.184-2.871-1.775-4.74-1.775%22%2F%3E%3C%2Fg%3E%3C%2Fsvg%3E)}.mui-confirm-body{margin-top:-1px;padding:20px 10px 10px;background-color:#fff}.mui-confirm-title{color:#000;font-size:15px;font-weight:600;line-height:1;padding-bottom:10px}.mui-confirm-content{color:#676767;font-size:12px;line-height:21px}.mui-confirm-content.mui-confirm-media{line-height:0}.mui-confirm-content.mui-confirm-media img{width:100%}.mui-confirm-link{color:#59c2ff}.mui-confirm-checkbox{color:#59c2ff;font-size:12px;font-weight:600;text-align:right;margin-top:5px}.mui-confirm-checkbox{position:relative;color:#59c2ff;font-weight:600;line-height:17px;height:17px;margin-right:10px}.mui-confirm-checkbox input{-webkit-appearance:none;display:inline-block;position:relative;border:1px solid #59c2ff;border-radius:5px;width:17px;height:17px;margin:0;padding:0;margin-right:5px;vertical-align:bottom}.mui-confirm-checkbox input:after{position:absolute;top:0;left:0;content:"";display:block;width:15px;height:15px}.mui-confirm-checkbox input:after{background:0 0}.mui-confirm-checkbox input:checked:after{background:no-repeat center;background-image:url("data:image/svg+xml;charset=utf-8,%3Csvg%20xmlns%3D\'http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg\'%20x%3D\'0px\'%20y%3D\'0px\'%20viewBox%3D\'0%200%2012%209\'%20xml%3Aspace%3D\'preserve\'%3E%3Cpolygon%20fill%3D\'%2359c2ff\'%20points%3D\'12%2C0.7%2011.3%2C0%203.9%2C7.4%200.7%2C4.2%200%2C4.9%203.9%2C8.8%203.9%2C8.8%203.9%2C8.8%20\'%2F%3E%3C%2Fsvg%3E");background-size:12px 9px}.mui-confirm-footer{display:-webkit-box;display:-webkit-flex;display:flex;-webkit-flex-direction:row;flex-direction:row;-webkit-flex-wrap:nowrap;flex-wrap:nowrap;-webkit-justify-content:center;justify-content:center;-webkit-align-content:center;align-content:center;-webkit-align-items:center;align-items:center;height:54px;color:#434343;background-color:#f5f5f5;text-align:center;font-size:15px;border-top:1px solid #dcdcdc}.mui-confirm-footer .mui-confirm-btn{-webkit-box-flex:1;-webkit-flex:1;flex:1;height:54px;line-height:54px}.mui-confirm-footer .mui-confirm-btn small{display:block;font-size:9px}.mui-confirm-footer .mui-confirm-btn{border-right:1px solid #dcdcdc}.mui-confirm-footer .mui-confirm-btn:last-child{color:#50a2ef;font-weight:600;border-right-width:0;line-height:1.2;padding-top:15px}.mui-confirm-reverse .mui-confirm-btn:nth-child(1){order:3;border-right-width:0}.mui-confirm-reverse .mui-confirm-btn:nth-child(2){order:2;border-right-width:1px}.mui-confirm-reverse .mui-confirm-btn:nth-child(3){order:1;border-right-width:1px}</style></head><body><div class="mui-confirm {W2A_QUIT_CONFIRM_REVERSE} mui-confirm-quit mui-active"><div class=mui-confirm-inner><div class=mui-confirm-header><div class="mui-confirm-icon mui-confirm-icon-question"></div></div><div class=mui-confirm-body><div class=mui-confirm-title>确定要退出吗？</div><div class=mui-confirm-content>欢迎使用轻量省电的{W2A_QUIT_APP_NAME}流应用版<br>如有问题请点左下角反馈意见</div></div><div class=mui-confirm-footer><div class=mui-confirm-btn>反馈意见</div><div class=mui-confirm-btn>回到应用</div><div class=mui-confirm-btn>直接退出<small>再按返回键退出</small></div></div></div></div></body></html>'.replace('{W2A_QUIT_APP_NAME}', wgtinfo.name).replace('{W2A_QUIT_CONFIRM_REVERSE}', isReverse() ? 'mui-confirm-reverse' : ''),
                    callback: function(e) {
                        switch (e.index) {
                            case -2: //点击遮罩关闭
                                break;
                            case -1: //点击返回键关闭
                                break;
                            case 0: //点击反馈意见
                                openFeedback();
                                break;
                            case 1: //点击回到应用
                                break;
                            case 2: //点击直接退出
                                quit();
                                break;
                        }
                    }
                });
            });
        });
        wap2app.quit = function() {
            var confirmElem = confirm.isVisible();
            if (confirmElem) { //退出时，如果confirm已显示，则直接退出
                quit();
            } else { //退出时，如果quit未显示，则需要先显示，然后开始计时，直接返回
                confirm.open(ID);
            }
        };
    });
})();