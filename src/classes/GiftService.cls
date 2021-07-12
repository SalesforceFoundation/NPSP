public with sharing class GiftService {

    public GiftView viewModelFrom(Id giftId) {
        GiftTemplate giftTemplate = new GiftTemplate();
        GiftSelector selector = new GiftSelector(giftTemplate);

        Gift gift = new Gift(giftId);
        GiftDTO giftDTO = new GiftDTO(gift);
        return new GiftView(giftDTO);
    }
}
