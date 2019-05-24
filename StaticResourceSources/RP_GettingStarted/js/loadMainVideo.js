function loadMainVideo(videoId){

    // Removes main video before loading the selected video so it does not keep playing in the background.
    document.getElementById('selectedVideo').innerHTML = "";

    var iframe = document.createElement('iframe');

    iframe.src = 'https://www.youtube.com/embed/' + videoId;
    iframe.setAttribute('frameborder', 0);
	iframe.setAttribute('allowfullscreen', 1);

    document.getElementById('selectedVideo').appendChild(iframe);
}