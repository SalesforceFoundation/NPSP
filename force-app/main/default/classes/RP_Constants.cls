/*
    Copyright (c) 2011, Salesforce.org
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
* @description Constant values class.
*/
public with sharing class RP_Constants {

    // Configuration for the Youtube component.
    public static final String RP_YOUTUBE_API_ENDPOINT = 'https://sfdo-status.herokuapp.com/api/youtube/playlists';
    public static final String RP_YOUTUBE_PLAYLIST_ID = 'PLU8xqF8ZASbXWAHIF0SB1P9_3G4vvRMXI';
    public static final String RP_YOUTUBE_CHANNEL_NAME = 'playlist?list=' + RP_YOUTUBE_PLAYLIST_ID;

    // Configuration for the GitHub component. Remains a Cumulus link for now.
    public static final String RP_GITHUB_SALESFORCE_ORG_ENDPOINT = 'https://sfdo-status.herokuapp.com/api/repository/SalesforceFoundation/Cumulus?format=json';

    // Configuration for the Getting Started page links
    public static final String RP_CUSTOMER_JOURNEY_LINK = 'http://www.salesforce.org/events/';
    public static final String RP_TRAILHEAD_LINK = 'https://trailhead.salesforce.com/en/content/learn/modules/nonprofit-cloud-basics';
    public static final String RP_US_LINK = 'https://trailhead.salesforce.com/trailblazer-community/groups/0F94S000000kHitSAE';
}
