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

@isTest
private class RP_YoutubeTest {

    /*********************************************************************************************************
    * @description operation
    *        load youtube videos data from salesforce.org channel enable from Salesforce.org api (Youtube)
    * verify:
    *       YoutubeWrapper object is uploaded
    */
    @isTest
    public static void testYoutubeListOfVideos () {

        Boolean failedRequest = false;

        //Applying page context here
        Test.setCurrentPage(Page.RP_Resources);

        Test.setMock(HttpCalloutMock.class, new RP_YoutubeTestMock(failedRequest));

        Test.startTest();

        RP_YouTubeController controller = new RP_YouTubeController();

        controller.loadYoutubePlaylistVideos();

        Test.stopTest();

        // Asserting that the controller isn't null
        System.assertNotEquals(controller, null);

        // Asserting that the list of wrapper object isn't returning null
        System.assertNotEquals(controller.youtubeVideosData, null);

        // Asserting that the wrapper object isn't returning null
        System.assertNotEquals(controller.youtubeMainVideo, null);

        // Asserting that youtube channel isn't returning null
        System.assertNotEquals(controller.youtubeChannelName, null);

        // Asserting that each property isn't returning null
        System.assertNotEquals(controller.youtubeMainVideo.videoId, null);
        System.assertNotEquals(controller.youtubeMainVideo.videoTitle, null);
        System.assertNotEquals(controller.youtubeMainVideo.videoDescription, null);
        System.assertNotEquals(controller.youtubeMainVideo.videoThumbnail, null);
    }

    /*********************************************************************************************************
    * @description operation
    *        test failed request from salesforce.org Api (Youtube)
    * verify:
    *       YoutubeWrapper object isn't uploaded
    */
    @isTest
    public static void testFailedRequest() {

        Boolean failedRequest = true;

        Test.setMock(HttpCalloutMock.class, new RP_YoutubeTestMock(failedRequest));

        RP_YouTubeController controller = new RP_YouTubeController();

        Test.startTest();

        controller.loadYoutubePlaylistVideos();

        Test.stopTest();

        RP_YouTubeController.YoutubeWrapper[] youtubeVideosData = new RP_YouTubeController.YoutubeWrapper[]{};

        // Asserting that the controller isn't null
        System.assertNotEquals(controller, null);

        // Asserting that the list of wrapper object is returning empty
        System.assertEquals(controller.youtubeVideosData, youtubeVideosData);

        // Asserting that the wrapper object is returning null
        System.assertEquals(controller.youtubeMainVideo, null);

        // Asserting that youtube channel isn't returning null
        System.assertEquals(controller.youtubeChannelName, RP_Constants.RP_YOUTUBE_CHANNEL_NAME);
    }

}