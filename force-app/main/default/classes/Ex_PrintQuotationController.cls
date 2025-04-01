public class Ex_PrintQuotationController {
     public Id qId {get;set;}
     public Ex_PrintQuotationController() {
      
        
        qId = ApexPages.currentPage().getParameters().get('qId');
        system.debug('qId: '+qId);
     }
}