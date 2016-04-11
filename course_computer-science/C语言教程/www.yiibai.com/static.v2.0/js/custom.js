
$(document).ready(function() {		
	view_times();	
	yearfrom();
})

// �鿴����
function view_times(){
	var aid = $("#aid").val();
	var postdata = {'aid': aid};
	$.ajax({
		url : '../../index_48be68cb.php.html',
		type : 'post',
		dataType : 'json',
		data : postdata,
		error : function() {},
		success : function(data, textStatus) {
			//$("#click_times").html(data.rs);
		}
	});
}

// �汾����
function yearfrom(){
	$.ajax({
		url : '../../index_fbd694f5.php.html',
		type : 'get',
		dataType : 'html',
		data : '',
		error : function() {},
		success : function(data, textStatus) {
			$("#year-from").html(data);
		}
	});
}});
}