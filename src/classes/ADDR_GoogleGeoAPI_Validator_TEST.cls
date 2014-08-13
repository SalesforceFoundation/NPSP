/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Validator to provide address geocoding/verification through the Google Geocoding API
 */
@isTest
public with sharing class ADDR_GoogleGeoAPI_Validator_TEST {




    public static testMethod void testParse() {
        String json = '{'+
        '   \"results\" : ['+
        '      {'+
        '         \"address_components\" : ['+
        '            {'+
        '               \"long_name\" : \"1600\",'+
        '               \"short_name\" : \"1600\",'+
        '               \"types\" : [ \"street_number\" ]'+
        '            },'+
        '            {'+
        '               \"long_name\" : \"Amphitheatre Pkwy\",'+
        '               \"short_name\" : \"Amphitheatre Pkwy\",'+
        '               \"types\" : [ \"route\" ]'+
        '            },'+
        '            {'+
        '               \"long_name\" : \"Mountain View\",'+
        '               \"short_name\" : \"Mountain View\",'+
        '               \"types\" : [ \"locality\", \"political\" ]'+
        '            },'+
        '            {'+
        '               \"long_name\" : \"Santa Clara\",'+
        '               \"short_name\" : \"Santa Clara\",'+
        '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
        '            },'+
        '            {'+
        '               \"long_name\" : \"California\",'+
        '               \"short_name\" : \"CA\",'+
        '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
        '            },'+
        '            {'+
        '               \"long_name\" : \"United States\",'+
        '               \"short_name\" : \"US\",'+
        '               \"types\" : [ \"country\", \"political\" ]'+
        '            },'+
        '            {'+
        '               \"long_name\" : \"94043\",'+
        '               \"short_name\" : \"94043\",'+
        '               \"types\" : [ \"postal_code\" ]'+
        '            }'+
        '         ],'+
        '         \"formatted_address\" : \"1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA\",'+
        '         \"geometry\" : {'+
        '            \"location\" : {'+
        '               \"lat\" : 37.42291810,'+
        '               \"lng\" : -122.08542120'+
        '            },'+
        '            \"location_type\" : \"ROOFTOP\",'+
        '            \"viewport\" : {'+
        '               \"northeast\" : {'+
        '                  \"lat\" : 37.42426708029149,'+
        '                  \"lng\" : -122.0840722197085'+
        '               },'+
        '               \"southwest\" : {'+
        '                  \"lat\" : 37.42156911970850,'+
        '                  \"lng\" : -122.0867701802915'+
        '               }'+
        '            }'+
        '         },'+
        '         \"types\" : [ \"street_address\" ]'+
        '      }'+
        '   ],'+
        '   \"status\" : \"OK\"'+
        '}';
    }
}