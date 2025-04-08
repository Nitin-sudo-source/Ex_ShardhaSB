public class Ex_PrintBookingFormController {
    public Id bId {get;set;}
    public Ex_PrintBookingFormController() {
        
        
        bId = ApexPages.currentPage().getParameters().get('bId');
        system.debug('bId: '+bId);
    }
}