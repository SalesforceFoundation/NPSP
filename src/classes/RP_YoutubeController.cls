/*
    Copyright (c) 2017 Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2017
* @group Getting Started
* @description Component that retrieves youtube videos from the Salesforce Fundation channel.
*/
public with sharing class RP_YoutubeController {

    //Variables used to load all information of videos from salesforce.org youtube channel
    public YoutubeWrapper[] youtubeVideosData {get; set;}
    public YoutubeWrapper youtubeMainVideo {get; set;}
    public String youtubeChannelName {get; set;}
    public Boolean timeoutError {get; set;}
    public Boolean remoteSiteSettingIsNotActive {get; set;}

    public RP_YoutubeController() {

        youtubeChannelName = RP_Constants.RP_YOUTUBE_CHANNEL_NAME;
        youtubeVideosData = new YoutubeWrapper []{};

        loadYoutubePlaylistVideos();
    }

    /*******************************************************************************************************
    * @description method used to load information from salesforce.org youtube channel into a map
    * @return void
    */
    @TestVisible private void loadYoutubePlaylistVideos() {

        RP_YoutubeClient client = new RP_YoutubeClient();
        HttpResponse response = client.getPlaylistVideos();
        timeoutError = true;
        remoteSiteSettingIsNotActive = client.remoteSiteSettingIsNotActive;
        
        if (response != null) {

            String responseBody = response.getBody();

            Map<String, Object> responseBodyMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            setData(responseBodyMap);

            timeoutError = false;
        }

    }

    /*******************************************************************************************************
    * @description method used to load information from map to a YoutubeWrapper instance
    * @param a deserialize json load in a map with the response values from salesforce org api
    * @return void
    */
    public void setData(Map<String, Object> responseBodyMap) {

        if (responseBodyMap != null && !responseBodyMap.isEmpty()) {

            for (Object instance : (List<Object>) responseBodyMap.get('items')){

                YoutubeWrapper video = new YoutubeWrapper(instance);
                youtubeVideosData.add(video);
            }

            youtubeMainVideo = youtubeVideosData[0];
        }
    }


    /*******************************************************************************************************
    * @description inner class, used to access salesforce.org youtube videos data
    */
    public class YoutubeWrapper {

        public String videoId {get; set;}
        public String videoTitle {get; set;}
        public String videoDescription {get; set;}
        public String videoThumbnail {get; set;}

        //Load map data into a YoutubeWrapper instance
        public YoutubeWrapper (Object instance) {

            Map<String,Object> videoInfo = (Map<String,Object>) instance;
            Map<String,Object> contentDetails = (Map<String,Object>) videoInfo.get('contentDetails');
            Map<String,Object> snippet = (Map<String,Object>) videoInfo.get('snippet');
            Map<String,Object> thumbnails = (Map<String,Object>) snippet.get('thumbnails');
            Map<String,Object> maxResolutionThumbnail = (Map<String,Object>) thumbnails.get('maxres');

            videoId = (String) contentDetails.get('videoId');
            videoTitle = (String) snippet.get('title');
            videoDescription = (String) snippet.get('description');
            videoThumbnail = (String) maxResolutionThumbnail.get('url'); // default, medium or high
        }
    }

}
