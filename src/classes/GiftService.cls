public with sharing class GiftService {

    public GiftView viewModelFrom(Id giftId) {
        Gift gift = new Gift(giftId);
        GiftDTO giftDTO = new GiftDTO(gift);
        return new GiftView(giftDTO);
    }
}
