function toggle_dropdown(ele){
		// ele.parentElement.classList.remove("close-force");
	ele.parentElement.classList.toggle("open");
}

document.onclick = function(event){
	if(!event.target.classList.contains('dropdown-toggle') && !event.target.classList.contains('fa-cog')){
		if(document.querySelector('.dropdown')){
			document.querySelector('.dropdown').classList.remove("open");
		}
	}
}

function mouseoverdownload() {
	var x = document.getElementById("download_chat_history");
  x.style.color = document.getElementById('contakti-user-name').style.color;
  x.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
}

function mouseoutdownload() {
	var x = document.getElementById("download_chat_history");
  x.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  x.style.backgroundColor  = document.getElementById('contakti-user-name').style.color;
}

function mouseoversend() {
	var y = document.getElementById("send_chat_history");
  y.style.color = document.getElementById('contakti-user-name').style.color;
  y.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
}

function mouseoutsend() {
	var y = document.getElementById("send_chat_history");
  y.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  y.style.backgroundColor  = document.getElementById('contakti-user-name').style.color;
}

function mouseovercancel() {
	var z = document.getElementById("contakti-msg-close-chat");
  z.style.color = document.getElementById('contakti-user-name').style.color;
  z.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
}

function mouseoutcancel() {
	var z = document.getElementById("contakti-msg-close-chat");
  z.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  z.style.backgroundColor  = document.getElementById('contakti-user-name').style.color;
}

function mouseoverstart() {
  var z = document.getElementById("contakti-msg-start-chat");
  z.style.color = document.getElementById('contakti-user-name').style.color;
  z.style.backgroundColor = document.getElementById('contakti-msg-head').style.backgroundColor;
}

function mouseoutstart() {
  var z = document.getElementById("contakti-msg-start-chat");
  z.style.color = document.getElementById('contakti-msg-head').style.backgroundColor;
  z.style.backgroundColor  = document.getElementById('contakti-user-name').style.color;
}
