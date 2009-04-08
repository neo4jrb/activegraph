$(document).ready(function() {
   $("a").click(function(event) {
	data = $("#editor").val()
	$.ajax({
		type: "POST",
		contentType: "text/plain",
		url: "neo",
		data: data,
		cache: false,
	    success: function(res){
		    $("#statusbar").append(res);
		    return true;
		}
	});
	event.preventDefault();
	
   });
});
