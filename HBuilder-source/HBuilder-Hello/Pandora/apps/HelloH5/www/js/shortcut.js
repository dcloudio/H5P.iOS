(function(w){
	
document.addEventListener('plusready',function(){
	checkArguments();
},false);

// 判断启动方式
function checkArguments(){
	console.log("Shortcut-plus.runtime.launcher: "+plus.runtime.launcher);
	if(plus.runtime.launcher=='shortcut'){
	try{
		var cmd = JSON.parse(plus.runtime.arguments);
		console.log("Shortcut-plus.runtime.arguments: "+plus.runtime.arguments)
		var type=cmd&&cmd.type;
		switch(type){
			case 'share':
				openWebview('plus/share.html');
			break;
			case 'about':
				openWebview('about.html','zoom-fade-out',true);
			break;
			default:
			break;
		}
	}catch(e){
		console.log("Shortcut-exception: "+e);
	}
	}
}
// 打开页面
function openWebview(id,a,s){
	if(!_openw||_openw.id!=id){
		clicked(id,a,s);
	}
}

// 处理从后台恢复
document.addEventListener('newintent',function(){
	console.log("Shortcut-newintent");
	checkArguments();
},false);

})(window);