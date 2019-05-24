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
* @description Component to set a mockup response from Salesforce Org HEROKU APP, in Youtube test classes.
*/

public with sharing class RP_YoutubeTestMock implements HttpCalloutMock{

    private static String body;
    private static String status;
    private static Integer code;

    public RP_YoutubeTestMock(Boolean failedRequest) {

        code = 400;
        status = 'error';

        if (!failedRequest) {

            setRequestBody();

            code = 200;
            status = 'ok';
        }

    }

    /*******************************************************************************************************
    * @description Set all information necesary to simulate a response from salesforce.org api endpoint (Youtube)
    * @return void
    */
    private void setRequestBody() {

        Map<String, Object> bodyMap = new Map<String, Object> ();
        Map<String, Object> contentDetailsMap = new Map<String, Object> ();
        Map<String, Object> itemsMap = new Map<String, Object> ();
        Map<String, Object> snippetMap = new Map<String, Object> ();
        Map<String, Object> thumbnailsMap = new Map<String, Object> ();
        Map<String, Object> thumbnailsMaxRes = new Map<String, Object> ();
        Object[] dataItems = new Object[]{};

        contentDetailsMap.put('videoId', 'k382pT7eooU');

        thumbnailsMaxRes.put('url', 'https://i.ytimg.com/vi/iBrS2LrJ-vo/mqdefault.jpg');
        thumbnailsMap.put('maxres', thumbnailsMaxRes);

        snippetMap.put('title' , 'NPSP How-To Series: Convert a Lead');
        snippetMap.put('description', 'This video is a test');
        snippetMap.put('thumbnails', thumbnailsMap);

        itemsMap.put('contentDetails', contentDetailsMap);
        itemsMap.put('snippet', snippetMap);

        dataItems.add(itemsMap);
        bodyMap.put('items', dataItems);

        body = System.JSON.serialize(bodyMap);
    }



    /*******************************************************************************************************
    * @description operation to simulate a correct or failed response for Youtube videos data
    * @param configured HTTPRequest data
    * @return HTTPResponse
    */
    public HTTPResponse respond(HTTPRequest request) {

        HttpResponse response = new HttpResponse();

        response.setStatusCode(code);
        response.setStatus(status);

        response.setBody(body);

        return response;
    }

}