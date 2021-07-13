public with sharing class GiftService {

    public GiftView viewModelFrom(GiftId giftId) {
        GiftTemplate defaultGiftTemplate = new GiftTemplate();
        GiftSelector selector = new GiftSelector(defaultGiftTemplate);

        Gift gift = new Gift(giftId);
        GiftDTO giftDTO = new GiftDTO(gift);
        return new GiftView(giftDTO);
    }
}
