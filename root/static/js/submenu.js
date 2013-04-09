 $("document").ready(function(){
		$("#submenu_puntocuenta").hide();

		$("#menu_correspondencia").click(function(){
			$("#submenu_puntocuenta").hide();
			$("#submenu_correspondencia").fadeIn("slow");
		});

		$("#menu_puntocuenta").click(function(){
			$("#submenu_correspondencia").hide();
			$("#submenu_puntocuenta").fadeIn("slow");
		});

});
