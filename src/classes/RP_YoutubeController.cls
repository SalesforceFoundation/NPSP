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
*
* @group Resource Page
*
* @description Component that retrieves youtube videos from the Salesforce Fundation channel.
*/
public with sharing class RP_YoutubeController {

    private static final String CUSTOM_METADATA_YOUTUBE_NAME = 'Youtube';
    private RP_Youtube__mdt youtubeMetadata;

    public YoutubeWrapper[] youtubeVideosData {get; set;}
    public YoutubeWrapper youtubeMainVideo {get; set;}
    public String youtubeChannelName {get; set;}

    public RP_YoutubeController() {

        youtubeMetadata = [SELECT Id,
                                  RP_Youtube_API_endpoint__c,
                                  RP_Youtube_channel_name__c,
                                  RP_Youtube_Playlist_Id__c
                               FROM RP_Youtube__mdt
                               WHERE DeveloperName =: CUSTOM_METADATA_YOUTUBE_NAME
                               LIMIT 1
                           ];

        if (youtubeMetadata != null) {

            youtubeChannelName = youtubeMetadata.RP_Youtube_channel_name__c;
            youtubeVideosData = new YoutubeWrapper []{};

            updateYoutubePlaylist();
        }

    }

    private void updateYoutubePlaylist() {

        String responseBody;
        RP_YoutubeClient client = new RP_YoutubeClient();
        String salesforceOrgEndpoint = youtubeMetadata.RP_Youtube_API_endpoint__c + '/' + youtubeMetadata.RP_Youtube_Playlist_Id__c;
        HttpResponse response = client.getSFORGInformation(salesforceOrgEndpoint);

        if (response != null) {

            responseBody = response.getBody();

            Map<String, Object> mapResponseBody = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            setData(mapResponseBody);

        }

    }

    public void setData(Map<String, Object> mapResponseBody) {

        if (mapResponseBody != null) {

            for (Object instance : (List<Object>)mapResponseBody.get('items')){

                Map<String,Object> videoInfo = (Map<String,Object>)instance;
                Map<String,Object> contentDetails = (Map<String,Object>)videoInfo.get('contentDetails');
                Map<String,Object> snippet = (Map<String,Object>)videoInfo.get('snippet');
                Map<String,Object> thumbnails = (Map<String,Object>)snippet.get('thumbnails');
                Map<String,Object> maxResolutionThumbnail = (Map<String,Object>)thumbnails.get('maxres');

                YoutubeWrapper video = new YoutubeWrapper();
                video.videoId = (String)contentDetails.get('videoId');
                video.videoTitle = (String)snippet.get('title');
                video.videoDescription = (String)snippet.get('description');
                video.videoThumbnail = (String)maxResolutionThumbnail.get('url'); // default, medium or high

                youtubeVideosData.add(video);
            }

            youtubeMainVideo = youtubeVideosData[0];
        }
    }

    public class YoutubeWrapper {

        public String videoId {get; set;}
        public String videoTitle {get; set;}
        public String videoDescription {get; set;}
        public String videoThumbnail {get; set;}

        public YoutubeWrapper () {

        }

    }


}