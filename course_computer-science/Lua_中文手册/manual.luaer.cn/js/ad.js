
function getAlimama(w,h,c) {
	return '<script type="text/JavaScript">var cpro_id = "u1138988";</script> <script src="../../cpro.baidustatic.com/cpro/ui/c.js" type="text/javascript"> </script>';
}

function flyexec(a) {
	var b = a.length, c = 0, d, o;
	for (c; c<b; c++) {
		d = a[c].split(',');
		o = document.getElementById(d[0]);
		if (o) {
			o.innerHTML = '<iframe name="'+d[0]+'frm" id="indexboxadfrm" style="background-color: transparent;width:'+d[1]+'px;height:'+d[2]+'px;" border=0 frameborder=0 scrolling="no" marginheight="0" marginwidth="0"></iframe>';
			window.frames[d[0] + 'frm'].document.write(getAlimama(d[1],d[2],d[3]));	
		}
	}
}
flyexec(['manualfoot,960,90,mm_10998699_987682_2870856']);;