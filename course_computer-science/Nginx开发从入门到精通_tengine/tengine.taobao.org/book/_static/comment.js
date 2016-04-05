/**
110414 lizziesky:
    ä»…åŒ…å« ç”Ÿæˆ comments å°icon, ä¸”ç‚¹å‡»icon è·³è½¬åˆ°groupsçš„é€»è¾‘,
    - ä¼˜åŒ–äº†DOMç»“æž„,
    - åŽ»é™¤äº† window.resize äº‹ä»¶
    - åŽ»é™¤ ä»¿google code æ–‡æ¡£çš„ä¾§æ åˆ‡æ¢
 */
DESELEMENT = "h1,h2,h3,h4,.highlight-python";//"h1,h2,h3,h4,ul,div.section p,div.highlight-python";

function clean_tag(st){
    return st.replace(/<[^>]+>?[^<]*>/g, '');
}

$(document).ready(function(){
    $("div.body > div.section").find(DESELEMENT).each(function() {
        if (!$(this).prev("div.comment").length) {
            var cmt = $('<div class="comment"><a class="email_link" title="ç‚¹å‡»æäº¤Issue,åé¦ˆä½ çš„æ„è§..."></a></div>');
            $(this).before(cmt);
            cmt.offset({
                left: $(this).parents('.section').offset().left - 20,
                top: $(this).offset().top
            });
        }
    });

    $("a.email_link").hover(function(){
        if ($(this).attr("href") == null||$(this).attr("href") == '') {
            var sub = $("div.documentwrapper div.body div.section:first h1").html();
            var body = $(this).parent("div.comment").next().html();
            // collection doc info from DOCUMENTATION_OPTIONS
            sub = clean_tag(sub);
            
            body = clean_tag(body);
            if (body.length>100) {
                body = body.substring(0, 100)+"...";
            }
            //091117:Zoomq change comment aim
            //$(this).attr("href", "https://groups.google.com/group/obp-comment/post?hl=zh-CN&subject="+encodeURIComponent(sub)+"&body="+encodeURIComponent(body));
            //$(this).attr("href", "../../../bitbucket.org/ZoomQuiet/obp.rwiwpyzh/issues/new.html");
            $(this).attr("href", "https://github.com/taobao/nginx-book/issues/new?title="+encodeURIComponent(sub)+"+"+encodeURIComponent(body)+"&body="+encodeURIComponent("current content:\n ...\nadvice:\n ...\nreason:\n ...\n"));
            $(this).attr("target", "_blank");
        }
    }, function(){
    });

});

