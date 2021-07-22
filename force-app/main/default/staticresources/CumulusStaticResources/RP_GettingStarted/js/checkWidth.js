$(document).ready(function() {

    function checkWidth() {

        if ($(window).width() < 769) {

            $('[id$=bordersDiv]').removeClass("slds-border_left slds-border_right");
        }
        else {

            $('[id$=bordersDiv]').addClass("slds-border_left slds-border_right");
        }
    }
    // Execute on load
    checkWidth();
    // Bind event listener
    $(window).resize(checkWidth);
});