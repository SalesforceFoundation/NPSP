/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description The UTIL_HtmlOutput_CTRL is used to safely unescape any allowed tags and urls
*/
public with sharing class UTIL_HtmlOutput_CTRL {

    /** @description The map of allowed tags and their temporary substitution values */
    private static final Map<String, String> SUBSTITUTION_BY_ALLOWED_TAG = new Map<String, String> {
        '/>' => '|backClose|',
        '</' => '|closeFront|',
        '>' => '|emptyClose|',
        '<br' => '|break|',
        '<b' => '|bold|',
        '<ol' => '|orderList|',
        '<ul' => '|unorderedList|',
        '<li' => '|lineItem|',
        '<p' => '|para|',
        '<h1' => '|head1|',
        '<h2' => '|head2|',
        '<h3' => '|head3|'
    };

    /** @description The map of allowed urls and their temporary substitution values */
    private static final Map<String, String> SUBSTITUTION_BY_ALLOWED_URL = new Map<String, String> {
        '<a href="https://trailhead.salesforce.com/' => '|hubURL|',
        '<a href="https://help.salesforce.com/' => '|helpURL|',
        '<a href="https://powerofus.force.com/' => '|powerOfUsURL|',
        '<a href="/lightning/setup/' => '|lightningSetupURL|',
        '<a href="/setup/' => '|setupURL|',
        '<a href="#" onclick="ShowPanel(\'idPanelHealthCheck\');return false;"' => '|showPanelHealthCheck|',
        '<a href="#" onclick="ShowPanel(\'idPanelErrorLog\');return false;"' => '|showPanelErrorLog|',
        '<a href="#" onclick="window.open(\'/' => '|openRelative|',
        '" target="_blank"' => '|blankTarget|',
        '" target="_new"' => '|newTarget|',
        '"' => '|quote|'
    };

    /** @description The unescaped html passed in by the page. */
    public String unsafeHtml { 
        get; 
        set {
            if (value != null) {
                unsafeHtml = value;
            }
        }
    }

    /** @description True when the html contains a url that should be safely escaped. */
    public Boolean hasURL {
        get; 
        set {
            if (value != null) {
                hasURL = value;
            } else {
                hasURL = false;
            }
        }
    }

    /*******************************************************************************************************************
    * @description Returns the escaped html with the unescaped allowed tags and url
    */
    public String getSafeHtml() {
        if (String.isBlank(unsafeHtml)) {
            return '';
        }

        String safeHtml = replaceAllowedList(unsafeHtml);
        safeHtml = safeHtml.escapeHtml4();
        safeHtml = resetAllowedList(safeHtml);

        return safeHtml;
    }

    /*******************************************************************************************************************
    * @description Strips un-allowed javascript from string
    */
    public String sanitizeInlineJavaScript(String unsanitaryLink) {
        if (String.isBlank(unsanitaryLink)) {
            return '';
        }

        String quoteString = '(\'|\\Q' + SUBSTITUTION_BY_ALLOWED_URL.get('"') + '\\E)';
        Pattern stripJavaScript = Pattern.compile('(?i)on[a-z]*\\s*=\\s*' + quoteString + '.*\\(.*\\)\\s*\\1');
        Matcher matchStrip = stripJavaScript.matcher(unsanitaryLink);

        return matchStrip.replaceAll('');
    }

    /*******************************************************************************************************************
    * @description Returns the unescaped html with the allowed tags and url replaced with temporary values
    */
    private String replaceAllowedList(String unescapedHtml) {
        String replacedHtml = unescapedHtml.normalizeSpace();

        for (String allowedTag : SUBSTITUTION_BY_ALLOWED_TAG.keySet()) {
            replacedHtml = replacedHtml.replace(allowedTag, SUBSTITUTION_BY_ALLOWED_TAG.get(allowedTag));
        }

        if (hasURL) {
            for (String allowedUrl : SUBSTITUTION_BY_ALLOWED_URL.keySet()) {
                replacedHtml = replacedHtml.replace(allowedUrl, SUBSTITUTION_BY_ALLOWED_URL.get(allowedUrl));
            }
        }

        replacedHtml = sanitizeInlineJavaScript(replacedHtml);

        return replacedHtml;
    }

    /*******************************************************************************************************************
    * @description Returns the escaped html with the temporary tags and url to their original allowed values
    */
    private String resetAllowedList(String escapedHtml) {
        String html = escapedHtml;

        for (String allowedTag : SUBSTITUTION_BY_ALLOWED_TAG.keySet()) {
            html = html.replace(SUBSTITUTION_BY_ALLOWED_TAG.get(allowedTag), allowedTag);
        }

        if (hasURL) {
            for (String allowedUrl : SUBSTITUTION_BY_ALLOWED_URL.keySet()) {
                html = html.replace(SUBSTITUTION_BY_ALLOWED_URL.get(allowedUrl), allowedUrl);
            }
        }

        return html;
    }

}
