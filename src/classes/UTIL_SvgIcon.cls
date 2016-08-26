/*
    Copyright (c) 2016, Salesforce.org
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
 * @group Utilities
 * @description Utility that converts the static resource sprites to inline svg markup allowing
 * svgs to be rendered everywhere, e.g. IE, Edge, Chrome etc. in both LEx and Aloha
 */
public virtual with sharing class UTIL_SvgIcon {
    /** @description SVG namespace */
    @TestVisible
    private static String NS_SVG = 'http://www.w3.org/2000/svg';
    /** @description XLINK namespace */
    @TestVisible
    private static String NS_XLINK = 'http://www.w3.org/1999/xlink';
    /*******************************************************************************************************
     * @description Returns the string from the shared getSvgIconMarkup method enabling the method for use in Lightning Components.
     * @param spriteName The name of the static resource.
     * @param symbolId The symbol id for the icon in the static resource, this will be used to retrieve the SVG tag.
     * @param iconName Name of the icon.
     * @param className The class of this SVG tag, can be use for CSS purpose.
     * @param category Category of icon- action, standard, utility etc.
     * @param size Size of icon-- small, medium, large.
     * @param prefix The icon class prefix slds-, slds-button__, slds-input__ etc.
     * @return String The full SVG markup
     *******************************************************************************************************/
    @AuraEnabled
    public static String getSvgIconMarkupAura(String spriteName, String symbolId, String iconName, String className, String category, String size, String prefix) {
        try {
            return UTIL_SvgIcon.getSvgIconMarkup(spriteName, symbolId, iconName, className, category, size, prefix);
        } catch (Exception e) {
            AuraHandledException ae = new AuraHandledException(e.getMessage());
            ae.setMessage(e.getMessage());
            throw ae;
        }
    }
    /*******************************************************************************************************
     * @description Returns the full svg markup string from the corresponding sprite.
     * @param spriteName The name of the static resource.
     * @param symbolId The symbol id for the icon in the static resource, this will be used to retrieve the SVG tag.
     * @param iconName Name of the icon.
     * @param className The class of this SVG tag, can be use for CSS purpose.
     * @param category Category of icon- action, standard, utility etc.
     * @param size Size of icon-- small, medium, large.
     * @param prefix The icon class prefix slds-, slds-button__, slds-input__ etc.
     * @return String The full SVG markup
     *******************************************************************************************************/
    @TestVisible
    private static String getSvgIconMarkup(String spriteName, String symbolId, String iconName, String className, String category, String size, String prefix) {
        String namespacePrefix = UTIL_Namespace.getNamespace();
        String iconClassName = getIconClassName(iconName, className, category, size, prefix);

        Dom.Document svgDocument = getBlankSvgDocument();
        Dom.XmlNode svgElement = svgDocument.getRootElement();
        svgElement.setAttribute('aria-hidden', 'true');
        svgElement.setAttribute('class', iconClassName);
        svgElement.setAttribute('name', iconName);

        Dom.XmlNode symbolNode = getIconSymbolNode(
            getSpriteDocument(getStaticResource(namespacePrefix, spriteName)),
            symbolId
        );

        svgElement.setAttribute(
            'viewBox',
            symbolNode.getAttributeValue('viewBox', null)
        );

        for (Dom.XmlNode iconNode : symbolNode.getChildElements()) {
            svgElement.insertBefore(iconNode, null);
        }

        String svgMarkup = svgDocument.toXmlString();

        return svgMarkup.removeStart('<?xml version="1.0" encoding="UTF-8"?>');
    }
    /*******************************************************************************************************
     * @description Returns the icon classes for the svg tag.
     * @param iconName Name of the icon.
     * @param className The class of this SVG tag, can be use for CSS purpose.
     * @param category Category of icon- action, standard, utility etc.
     * @param size Size of icon-- small, medium, large.
     * @param prefix The icon class prefix slds-, slds-button__, slds-input__ etc.
     * @return String The generated icon classes
     *******************************************************************************************************/
    private static String getIconClassName(String iconName, String className, String category, String size, String prefix) {
        return prefix + 'icon ' + prefix + 'icon--' + size + ' ' + prefix + 'icon-' + category +'-' + iconName + ' ' + className;
    }
    /*******************************************************************************************************
     * @description Returns static resource from the name provided.
     * @param namespacePrefix The namespace for the static resource.
     * @param name The name of the static resource.
     * @return StaticResource The corresponding static resource
     *******************************************************************************************************/
    private static StaticResource getStaticResource(String namespacePrefix, String name) {
        try {
            return [
                SELECT Body
                FROM StaticResource
                WHERE NamespacePrefix = :namespacePrefix
                AND Name = :name
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new CustomException(
                'No resource with name \'' + name + '\' found.',
                e
            );
        }
    }
    /*******************************************************************************************************
     * @description Returns the sprite document from the provided sprite static resource.
     * @param spriteResource The sprite static resource.
     * @return Dom.Document The generated sprite document
     *******************************************************************************************************/
    private static Dom.Document getSpriteDocument(StaticResource spriteResource) {
        try {
            String spriteMarkup = spriteResource.Body.toString();
            Dom.Document spriteDocument = new Dom.Document();
            spriteDocument.load(spriteMarkup);
            return spriteDocument;
        } catch (Exception e) {
            throw new CustomException(
                'Could not read sprite resource for icon.',
                e
            );
        }
    }
    /*******************************************************************************************************
     * @description Returns the node corresponding to the symbolId from the spriteDocument.
     * @param spriteDocument The sprite document with the Icon.
     * @return Dom.XmlNode The Icon Symbol Node
     *******************************************************************************************************/
    private static Dom.XmlNode getIconSymbolNode(Dom.Document spriteDocument, String symbolId) {
        List<Dom.XmlNode> symbolElements = spriteDocument.getRootElement().getChildElements();
        System.debug(symbolElements.size());
        for (Dom.XmlNode symbolElement : symbolElements) {
            System.debug(symbolElement.getAttribute('id', null));
            String thisSymbolId = symbolElement.getAttributeValue('id', null);
            if (thisSymbolId == symbolId) {
                return symbolElement;
            }
        }
        System.debug('Throw Exception');
        throw new CustomException(
            'Could not find icon symbol with id ' + symbolId
        );
    }
    /*******************************************************************************************************
     * @description Returns an empty Svg Document
     * @return Dom.Document the empty Svg Document
     *******************************************************************************************************/
    private static Dom.Document getBlankSvgDocument() {
        Dom.Document svgDocument = new Dom.Document();
        Dom.XmlNode svgElement = svgDocument.createRootElement('svg', NS_SVG, '');
        svgElement.setNamespace('xlink', NS_XLINK);
        return svgDocument;
    }
    /*******************************************************************************************************
    * @description Exception raised during the svg markup generation process
    *******************************************************************************************************/
    private class CustomException extends Exception {}
}