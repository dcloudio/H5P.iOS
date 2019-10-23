(function(window, document) {
    var TabBar = function(options) {
        options = options || {};

        this.tabClass = options.tabClass || 'tab'; //容器元素
        this.itemClass = options.itemClass || 'tab-item'; //选项样式名称
        this.selectedClass = options.selectedClass || 'active'; //选项激活样式名称

        this.itemIconClass = options.itemIconClass || 'tab-item-icon'; //选项图标样式名称
        this.itemLabelClass = options.itemLabelClass || 'tab-item-label'; //选项标题样式名称

        this.list = options.list || []; //选项列表

        this.selected = 0;

        if (this.list.length) {
            this.render();
        }

        this.tabElem = document.querySelector('.' + this.tabClass);
        this.itemElems = [].slice.call(document.querySelectorAll('.' + this.itemClass));

        this.handleOldVersion();

        this.initEvent();

    };
    var proto = TabBar.prototype;

    proto.refresh = function() {
        this.itemElems = [].slice.call(document.querySelectorAll('.' + this.itemClass));
    };

    proto.handleOldVersion = function() {
        var list = this.list;
        if (!list.length) {
            for (var i = 0; i < this.itemElems.length; i++) {
                list.push({
                    url: this.itemElems[i].getAttribute('href')
                });
            }
        }
        window.__wap2app_old_tab_item_urls = [];
        for (var i = 0; i < list.length; i++) {
            __wap2app_old_tab_item_urls.push(list[i].url);
        }
    };
    proto.render = function() {
        var tabbarElem = document.createElement('nav');
        tabbarElem.className = this.tabClass;
        if (!this.list[0].iconPath) {
            tabbarElem.className = tabbarElem.className + ' no-icon';
        }
        if (!this.list[0].text) {
            tabbarElem.className = tabbarElem.className + ' no-label';
        }
        var html = [];
        for (var i = 0; i < this.list.length; i++) {
            html.push(this.renderItem(this.list[i], i));
        }
        tabbarElem.innerHTML = '<div class="' + this.tabClass + '-inner">' + html.join('') + '</div>';
        document.body.appendChild(tabbarElem);
    };
    proto.renderItem = function(item, index) {
        var isSelected = this.selected === index;
        var html = ['<div class="' + this.itemClass + (isSelected ? (' ' + this.selectedClass) : '') + '" href="' + item.url + '">'];
        if (item.iconPath) {
            html.push('<div class="' + this.itemIconClass + '"><img src="' + item.iconPath + '"/><img src="' + item.selectedIconPath + '"/></div>');
        }
        if (item.text) {
            html.push('<div class="' + this.itemLabelClass + '">' + item.text + '</div>');
        }
        html.push('</div>');
        return html.join('');
    };
    proto.initEvent = function() {
        if (!this.tabElem) {
            throw new Error('未找到TabBar容器');
        }
        if (!this.itemElems || !this.itemElems.length) {
            throw new Error('TabBar容器内无选项');
        }
        var self = this;
        //全局回调
        window.__wap2app_change_tab_callback = function(e) {
            self.highlight(e.index);
        };

        this.tabElem.addEventListener('click', function(e) {
            var target = e.target;
            for (; target && target !== self.tabElem; target = target.parentNode) {
                var index = self.itemElems.indexOf(target);
                if (~index) {
                    if (index === self.selected) {
                        return;
                    }
                    e.preventDefault();
                    e.stopPropagation();
                    var url = target.getAttribute('href');
                    if (!url) {
                        throw new Error('未指定选项打开的链接地址');
                    }
                    self.highlight(index);
                    var id = plus.runtime.appid;
                    wap2app.switchTab(id, id + '_' + index, url);
                }
            }
        });
    };
    proto.highlight = function(index) {
        this.itemElems[this.selected].classList.remove(this.selectedClass);
        var currentItemElem = this.itemElems[index]
        currentItemElem.classList.add(this.selectedClass);
        if (currentItemElem.scrollIntoView) {
            currentItemElem.scrollIntoView();
        }
        this.selected = index;
    };
    window.TabBar = TabBar;
})(window, document);