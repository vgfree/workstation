// jQuery cookie ²å¼þ
(function($,document,undefined){var pluses=/\+/g;function raw(s){return s}function decoded(s){return unRfc2068(decodeURIComponent(s.replace(pluses," ")))}function unRfc2068(value){if(value.indexOf('"')===0){value=value.slice(1,-1).replace('\\"','"').replace("\\\\","\\")}return value}var config=$.cookie=function(key,value,options){if(value!==undefined){options=$.extend({},config.defaults,options);if(value===null){options.expires=-1}if(typeof options.expires==="number"){var days=options.expires,t=options.expires=new Date();t.setDate(t.getDate()+days)}value=config.json?JSON.stringify(value):String(value);return(document.cookie=[encodeURIComponent(key),"=",config.raw?value:encodeURIComponent(value),options.expires?"; expires="+options.expires.toUTCString():"",options.path?"; path="+options.path:"",options.domain?"; domain="+options.domain:"",options.secure?"; secure":""].join(""))}var decode=config.raw?raw:decoded;var cookies=document.cookie.split("; ");var result=key?null:{};for(var i=0,l=cookies.length;i<l;i++){var parts=cookies[i].split("=");var name=decode(parts.shift());var cookie=decode(parts.join("="));if(config.json){cookie=JSON.parse(cookie)}if(key&&key===name){result=cookie;break}if(!key){result[name]=cookie}}return result};config.defaults={};$.removeCookie=function(key,options){if($.cookie(key)!==null){$.cookie(key,null,options);return true}return false}})(jQuery,document);

$(document).ready(function(){
	// ÓÃ»§µÇÂ¼
	(function(){
		var uid = $.cookie("uid");
		var username = $.cookie("username");
		var vip = $.cookie("vip");
		var vipexpire = $.cookie("vipexpire");
		var timenow = parseInt( (new Date()).getTime() / 1000 );
		var isVipValid = vipexpire>timenow ? 1 : 0;
		//var isOnline = false;

		if(uid && username){
			$("#user-info").html('' +
				'<a id="btn-logout" class="right" href="#">ÍË³ö</a>' +
				'<span class="right">&nbsp;&nbsp;|&nbsp;&nbsp;</span>' +
				'<span class="right" id="vip-type" style="background-image: url(' + window.cmsTemplets + '/images/vip_' + vip + '_' + isVipValid + '.png' + ')"></span>' +
				'<span class="right"><a href="../../../../../vip.biancheng.net/index.html">' + username + '</a>&nbsp;</span>'
			);
			//isOnline = true;
		}else{
			$("#user-info").html('' +
				'<a href="../../../../../vip.biancheng.net/login.php.html" target="_blank">µÇÂ¼</a>&nbsp;&nbsp;|&nbsp;' +
				'<a href="../../../../../vip.biancheng.net/register.php.html" target="_blank">×¢²á</a>'
			);
		}

		// ÍË³öµÇÂ¼
		$("body").delegate("#btn-logout", "click", function(e){
			e.preventDefault();

			var expire = -1;
			var path = "/";
			$.cookie("username", '', {"path": path, "expires": expire});
			$.cookie("uid", '', {"path": path, "expires": expire});
			$.cookie("vip", '', {"path": path, "expires": expire});
			$.cookie("vipexpire", '', {"path": path, "expires": expire});

			$.getScript("../../../../../vip.biancheng.net/logout_jsonp.php.html", function(){
				history.go(0);
			});
		});

		//Èç¹ûÊÇvip½Ì³Ì
		if(window.thisArtFlag && /f/.test(window.thisArtFlag)){
			if(!parseInt(vip) || !isVipValid){
				$("#art-body").html(
					'<p class="vip-tip col-red">' +
					'ÄúºÃ£¬ÄúÕýÔÚÔÄ¶Á¸ß¼¶½Ì³Ì»òÏîÄ¿Êµ¼ù£¬ÐèÒª<a href="../../../../../vip.biancheng.net/index.html" target="_blank">¿ªÍ¨VIP»áÔ±£¨µÍÖÁ19.9Ôª/ÔÂ£©</a>¡£¿ªÍ¨VIP»áÔ±ºó£¬ÎÒÃÇ»¹½«Ìá¹©QQÒ»¶ÔÒ»´ðÒÉ£¬ÔùËÍ1T±à³Ì×ÊÁÏ£¬Çë<a href="../../../../../vip.biancheng.net/index.html" target="_blank">ÃÍ»÷ÕâÀï</a>ÁË½âÏêÇé¡£' +
					'</p>'
				);
			}
			$("#art-body").css("display", "block");
		}
	})();

	var activeNode = null;
	// ajax¶¯Ì¬¼ÓÔØÄ¿Â¼£¬²¢Îªµ±Ç°ÕÂ½Ú×ÅÉ«
	(function(){
		var contents = $("#course-contents"),
			thistypeid = contents.attr("thistypeid"),
			thisDdTem = contents.children("dd[typeid='" + thistypeid + "']"),
			thisDd = thisDdTem && thisDdTem.length && thisDdTem.first();
		if(thisDd){
			var channelnum = thisDd.attr("channelnum"),
				dds = '';
			$.ajax({
				method: 'get',
				url: "/cpp/ajaxapi/getArtList.php?v=" + window.cmsTempletsVer + "&typeid=" + thistypeid,
				dataType: 'text',
				
				success: function(retData){
					retData = $.parseJSON( decodeURIComponent(retData) );
					if(!retData || !retData.success){
						thisDd.after('<div class="errorMsg">¼ÓÔØÕÂ½ÚÁÐ±íÊ§°Ü£¡</div>');
						return;
					}
					// Èç¹ûÃ»ÓÐÊý¾Ý£¬Ôò°Ñ¸ÃÕÂ±êÌâÉèÎªactive
					if( !retData.data || !retData.data.length ){
						return;
					}

					$.each( retData.data, function( i, record ){
						dds += '<dd>' + channelnum + '.' + (++i) + ' ' + record + '</dd>';
					});
					thisDd.after( '<dl class="dl-sub">' + dds + '</dl>' );

					if(window.thisArtId){ // ÎÄÕÂÒ³
						var aActiveTem = $("#course-contents a[artid='" + thisArtId + "']"),
							aActive = aActiveTem && aActiveTem.first();
						aActive && aActive.parent().addClass("active");
						activeNode = aActive.parent();
					}else{  // ÎÄÕÂÁÐ±íÒ³
						thisDd && thisDd.addClass("active");
						activeNode = thisDd;
					}
				},
				error: function(jqXHR, textStatus, errorThrown){
					thisDd.after('<div class="errorMsg">¼ÓÔØÕÂ½ÚÁÐ±íÊ§°Ü£¡</div>');
				}
			});
		}
	})();

	// ¼ÓÔØÎÄÕÂ¶¥²¿¹ã¸æ
	$("#ad-arc-top-diy").html('' +
		'<table>'+
			'<tr><td id="ad-beifeng-top"><a class="col-red" href="../../../fudao/index.html" target="_blank">CÓïÑÔ¸¨µ¼°à£¬°ïÖúÓÐÖ¾ÇàÄê£¡°´ÔÂ¸¶·Ñ£¬¼õÇá¸ºµ££¬½öÐè200Ôª£¬ÇîÈËÒ²ÄÜÑ§£¡</a></td></tr>'+
			'<tr><td><a class="col-green" href="../../../dayi/index.html" target="_blank">CÓïÑÔÒ»¶ÔÒ»´ðÒÉ£ºQQÔÚÏß£¬ËæÊ±ÏìÓ¦£¬¼¼ÊõÎÊÌâ + Ñ§Ï°Â·Ïß + ¾ÍÒµÖ¸ÄÏ£¬ÄÄÀï²»¶®ÎÊÄÄÀï£¡</a></td></tr>'+
		'</table>'

		/*'<div id="ad-beifeng-top">' +
			'<a class="col-red" href="../../../redirect_f0a89006.html" target="_blank">Áã»ù´¡ÔÚÏßÑ§Ï°ITÈÈÃÅ¿Î³Ì£¬ÕÆÎÕ×îÇ°ÑØ¼¼Êõ£º±±·çÍø</a>' +
		'</div>'*/ //+
		//'<div id="ad-fudaoban-top">' +
		//	'<a class="col-link" href="../../../../../www.weixueyuan.net/shoutu/index.html" target="_blank">¡¾±à³Ì¸¨µ¼°à¡¿Ò»¶ÔÒ»¸¨µ¼ + ×¨Ìâ½²½â + ÊÓÆµ½Ì³Ì + ¾ÍÒµÖ¸ÄÏ</a>' +
		//'</div>'
	);
	
	// ¼ÓÔØ±±·çÍøµ×²¿¹ã¸æ
	/*$("#id-beifeng-pic").html('' +
		'<a href="../../../redirect_6fc6ada7.html" target="_blank">' +
			'<img src="' + cmsPath + '/uploads/ads/beifeng_728_80.jpg?v=' + window.cmsTempletsVer + '" alt="±±·çÍø">' +
		'</a>');*/

	/*// ¼ÓÔØ#main¶¥²¿¹ã¸æ
	$("#ad-position").html('' +
		'<a class="left" href="../../../redirect_6b94f2cf.html" target="_blank"><img src="' + cmsPath + '/uploads/ads/beifeng_515_60.jpg?v=' + window.cmsTempletsVer + '" alt="±±·çÍø" /></a>' +
		'<a class="right" href="../../../html/2873.html" target="_blank"><img src="' + cmsPath + '/uploads/ads/dayi.gif?v=' + window.cmsTempletsVer + '" alt="CÓïÑÔ´ðÒÉ" /></a>'
	);*/

	// ¼ÓÔØÓÒÏÂ½Ç¹ã¸æ
	/*(function(){
		var adRbStr = $('<div id="ad-rb">' +
    					'<span class="close">¡Á</span>' +
    					'<div class="content">' +
	        				'<h3 class="title col-red">µçÄÔ£¿OutÁË£¡ÊÖ»úÉÏÒ²ÄÜÑ§±à³Ì</h3>' +
        					'<p class="info">¹úÄÚµÚÒ»¸öÊÖ»ú±à³ÌÖúÊÖ£¡Î¢ÐÅÉ¨Ãè¶þÎ¬Âë£¬¹Ø×¢¹«ÖÚºÅ(ÂëÅ©ËÞÉá)¼´¿É²ÎÓëÑ§Ï°£¡</p>' +
        					'<div class="img"><img height="222" src="' + cmsTemplets + '/images/bianchengziliao.jpg' + '" /></div>' +
	        			'</div>' +
					'</div>');
		$("body").append(function(){
			adRbStr.find("span.close").click(function(){ adRbStr.hide(); });
			return adRbStr;
		});
	})();*/
	// ÒÔÏÂÊÇÁíÍâÒ»¸ö°æ±¾
	/*(function(){
		var adRbStr = '<div id="ad-rb">' +
	    			  	'<div class="title">±à³Ì×ÊÁÏÏÂÔØ <span class="right close">¡Á</span></div>' +
	    				'<div class="content">' +
	        				'<h3><a class="col-red" href="../../../html/beifeng_card.html" target="_blank">³¬¹ý2TBµÄ±à³Ì×ÊÁÏÃâ·ÑÏÂÔØ</a></h3>' +
	        				'<p>±±·çÍøÊÇÒ»¼Ò×¨ÃÅ´ÓÊÂÔÚÏß½ÌÓýµÄÍøÕ¾£¬ÓµÓÐ¹úÄÚ×î¶àµÄ<b class="col-red">ÊÓÆµ</b>×ÊÔ´£¬°üÀ¨C/C++¡¢Java¡¢IOS¡¢AndroidµÈ¡£CÓïÑÔÖÐÎÄÍøÓÐÐÒ»ñµÃ±±·çÍøµÄÑ§Ï°¿¨£¬ÃæÖµ<b class="col-red">200Ôª</b>£¬Ãâ·ÑÔùËÍ¸ø´ó¼Ò¡£<a class="col-link" href="../../../html/beifeng_card.html" target="_blank">ÃÍ»÷ÕâÀï²é¿´ÏêÇé&gt;&gt;</a></p>' +
	    				'</div>' +
					'</div>';
		var body = $("body");
		body.append(adRbStr);
		body.delegate("#ad-rb", "click", function(e){
			/close/.test(e.target.getAttribute("class")) && ( this.style.display = "none" );
		})
	})(); */

	//±³¾°¸ôÐÐ»»É«
	(function(){
		$(".bg_change").each(function(){
			var nodes = $(this).children("li:even");
			if(nodes && nodes.length){
				nodes.addClass('bg-f7f7f7');
			}else{
				$(this).children("dd:even").addClass('bg-f7f7f7');
			}
		});
	})();

	// ¼ÓÔØ´úÂë¸ßÁÁ²å¼þ
    (function(){
        var pres = document.getElementsByTagName("pre");
        if(!pres || !pres.length)
        	return;

        $.getScript(window.cmsTemplets+"/js/jquery.snippet.js",function(){
            $(pres).each(function(){
                var thisClass = $(this).attr("class");
                thisClass = thisClass && thisClass.replace( /^shell$/, "sh" );  // Shell
                thisClass = thisClass && thisClass.replace( /^objective-c$/, "oc" );  // Shell

                thisClass && !/info-box/.test(thisClass) && !/console/.test(thisClass) && $(this).snippet(thisClass,{
                    style:"bright",
                    clipboard:window.cmsTemplets+"/js/ZeroClipboard.swf"
                });
            });
        });
    })();

    // ÏÂÀ­²Ëµ¥
    (function(){
    	$(".share,.sub-menu").mouseover(function(){
        	$(this).children('ul').css({
        		'display': 'block'
        	});
        }).mouseout(function(){
        	$(this).children('ul').css({
        		'display': 'none'
        	});
        });
    })();

    // ·ÖÏí°´Å¥
    (function(){
    	var shareWrap = $(".share");

    	// °Ù¶È¿ìÕÕµÄÃèÊöÀïÃæ»á³öÏÖ·ÖÏíµÄÎÄ×Ö£¬¸ÄÎª¶¯Ì¬¼ÓÔØ
    	shareWrap.append('' + 
    		'<dt>·ÖÏíµ½£º</dt>' +
			'<dd class="qzone">QQ¿Õ¼ä</dd>' +
			'<dd class="weibo">ÐÂÀËÎ¢²©</dd>' +
			'<dd class="tweibo">ÌÚÑ¶Î¢²©</dd>' +
			'<dd class="douban">¶¹°ê</dd>' +
			'<dd class="renren">ÈËÈËÍø</dd>');

        // QQ¿Õ¼ä
        shareWrap.delegate('.qzone', 'click', function(){
        	window.open('../../../../../sns.qzone.qq.com/cgi-bin/qzshare/cgi_qzshare_onekey_2d2816fe.html'+
        		'title=' + encodeURIComponent(shareParam.title) + '&'+
        		'desc=' + encodeURIComponent(shareParam.desc) + '&'+
        		'summary=' + encodeURIComponent(shareParam.summary_qzone) + '&'+
        		'url=' + shareParam.url + '&'+
        		'pics=' + encodeURIComponent(shareParam.pic_qzone), '_blank');
			return false;
        });

        // ÐÂÀËÎ¢²©
        shareWrap.delegate('.weibo', 'click', function(){
        	window.open('../../../../../service.weibo.com/share/share_2d2816fe.php.html'+
        		'title=' + encodeURIComponent(shareParam.desc) + '&'+
        		'url=' + shareParam.url + '&'+
        		'pic=' + shareParam.pic_tweibo, '_blank');
			return false;
        });

        // ÌÚÑ¶Î¢²©
        shareWrap.delegate('.tweibo', 'click', function(){
        	window.open('../../../../../share.v.t.qq.com/index_8554a93e.php.html'+
        		'title=' + encodeURIComponent(shareParam.desc) + '&'+
        		'url=' + shareParam.url + '&'+
        		'pic=' + shareParam.pic_tweibo, '_blank');
			return false;
        });

        // ¶¹°ê
        shareWrap.delegate('.douban', 'click', function(){
        	window.open('http://www.douban.com/share/service?'+
        		'name=' + encodeURIComponent(shareParam.title) + '&'+
        		'text=' + encodeURIComponent(shareParam.summary_douban) + '&'+
        		'sel=' + encodeURIComponent(shareParam.desc) + '&'+
        		'href=' + shareParam.url + '&'+
        		'image=' + shareParam.pic_douban, '_blank');
			return false;
        });

        // ÈËÈË
        shareWrap.delegate('.renren', 'click', function(){
        	window.open('../../../../../widget.renren.com/dialog/share_2d2816fe.html'+
        		'title=' + encodeURIComponent(shareParam.title) + '&'+
        		'description=' + encodeURIComponent(shareParam.summary_douban) + '&'+
        		'resourceUrl=' + shareParam.url + '&'+
        		'pic=' + shareParam.pic_douban + '&' +
        		'charset=utf-8', '_blank');
			return false;
        });

    })();

    // ¾²Ì¬Ä¿Â¼£¬²¢Îªµ±Ç°ÕÂ½Ú×ÅÉ«
	(function(){
		var contents = $("#course-contents"),
			loadMode = contents.attr('loadmode');
		if(loadMode === 'static'){
			var url = document.location.pathname,
				as = contents.find('a');
			as.each(function(){
				if($(this).attr('href') === url){
					activeNode = $(this).parent();
					activeNode.addClass('active');
					return false;
				}
			});
		}
	})();

	// ÉÏÒ»½Ú¡¢ÏÂÒ»½Ú°´Å¥
	(function(){
		$(".paging-btn").click(function(){
			var isPreBtn = /paging-pre/.test( $(this).attr("class") );
			if(isPreBtn){
				var preNextNode = $(activeNode).prevAll("dd").first();
				preNextNode = preNextNode.length ? preNextNode : $(activeNode).parent().prev("dd");
			}else{
				var preNextNode = $(activeNode).nextAll("dd").first();
				preNextNode = preNextNode.length ? preNextNode : $(activeNode).next("dl").children("dd").first();
				if(!preNextNode.length){
					var preNextNode = $(activeNode).parent().next("dd");
				}
			}
			var preNextLink = (preNextNode && preNextNode.length) ? preNextNode.children("a").attr("href") : location.href;
			location.href = preNextLink;
		});
	})();

	// ÎªÎÄÕÂÄÚµÄÍ¼Æ¬Ìí¼ÓÁ´½Ó
	$("#art-body img").click(function(){
		window.open($(this).attr("src"));
	});

    // ¼ÓÔØ¶àËµ²å¼þ
    (function(){
    	if(!window.duoshuoQuery)
    		return;

		var ds = document.createElement('script');
		ds.type = 'text/javascript';
		ds.async = true;
		ds.src = '../../../../../static.duoshuo.com/embed.js';
		ds.charset = 'UTF-8';
		(document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(ds);
    })();

    /*(function(){
    	$("#nav-top").after(''+
    		'<ul id="ad-link-top" class="left hover-none">'+
				'<li class="fudaoban"><a href="../../../../../vip.biancheng.net/index.html" target="_blank">CÓïÑÔÖÐÎÄÍøVIP»áÔ±</a></li>'+
			'</ul>'
		);
    })();*/
});