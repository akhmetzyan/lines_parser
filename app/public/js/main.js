$(document).ready(function(){
	$('#uploader').submit(function(event){
		event.preventDefault();
		$txt1 = $('input[name=txt1]');
		$txt2 = $('input[name=txt2]');

		if(!$txt1.val() || !$txt1.val()){
			alert('Файлов не хватает');
			return false;
		}
		formData = new FormData($('#uploader')[0]);
		$.ajax({
			url: '/uploadfiles',
			type: "POST",
			data: formData,
			processData: false,
			contentType: false,
			success: function(data, textStatus, jqXHR){if (data.status){window.open('/getcsv', '_blank'); window.open('/getzip', '_blank')}},
			error: function(jqXHR, textStatus, errorThrown){alert('Произошла ошибка сервера');}
		});
		return false;
	});
	$('.fileadder').click(function(){
		$(this).next().trigger('click');
	});
	$('input[type=file]').change(function(){
		$(this).prev().html($(this)[0].files[0].name);
	});
});