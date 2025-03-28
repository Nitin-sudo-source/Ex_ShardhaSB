public class Ex_GenerateQuotation {
    
    public class ChargeDetails{
        @AuraEnabled
        public Decimal allInPrice {get; set;}
        @AuraEnabled
        public Decimal agreementValue {get; set;}
        @AuraEnabled
        public Decimal otherChargesIncludingTax {get; set;}
        @AuraEnabled
        public Decimal registrationCharges {get; set;}
        @AuraEnabled
        public Decimal stampDutyPercentage {get; set;}
        @AuraEnabled
        public Decimal GSTPercentage {get; set;}

        public ChargeDetails(Decimal allInPrice, Decimal agreementValue, Decimal otherChargesIncludingTax,
                             Decimal registrationCharges, Decimal stampDutyPercentage, Decimal GSTPercentage){
            this.allInPrice = allInPrice;
            this.agreementValue = agreementValue;
            this.otherChargesIncludingTax = otherChargesIncludingTax;
            this.registrationCharges = registrationCharges;
            this.stampDutyPercentage = stampDutyPercentage;
            this.GSTPercentage = GSTPercentage;
        }
    }


    @AuraEnabled
    public static Account getAccountInfo(Id accId) {
        List<Account> accList = new List<Account>();
        String[] types = new String[]{'Account'};
            string queryFields = '';
        Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
        
        for(Schema.DescribeSobjectResult res : results) {
            string sObjectname = res.getName();
            Map <String, Schema.SObjectField> fieldMap = res.fields.getMap();
            
            for(Schema.SObjectField sfield : fieldMap.Values()) { 
                schema.describefieldresult dfield = sfield.getDescribe();
                String fieldLabel = dfield.getLabel();
                
                if(queryFields == null || queryFields == '') {
                    queryFields = dField.getName();
                } else {
                    queryFields = queryFields + ', ' + dField.getName();
                }
            }
        }
        String soqlQuery = 'Select ' + queryFields  + ' ,  Society__r.Project__c, Society__r.Project__r.Name,  Tower__r.Name from Account Where Id = \''+accId+'\''; 
        system.debug(soqlQuery);
        accList = Database.query(soqlQuery);
        if (accList.size() > 0) {
            return accList[0];
        } else {
            return null;
        }
    }
    

    /* 
     * Returns the charge details from Unit/Tower
     * TODO :
     *   - If they are going to store All_in_Price__c/Agreement_Value__c depending 
     *     on Unit then you can't mandatory All_In_Price/Agreement_Value__c.
     *     (still not sure on this, recheck this)
    */
    
    
    @AuraEnabled
    public static ChargeDetails getChargeDetails(String unitID){
        
        try {

            Boolean isValidUnitID = isValidRecordID(unitID);
            if(!isValidUnitID){
                throw new CustomException('Invalid Record ID for Unit : ' + unitID);
            }  
            
            Unit__c unit =  [SELECT Id, Name, All_in_Price__c, Agreement_Value__c, Total_Other_Charges_Including_Tax__c,
                                    Tower__r.GST_Percentage__c, Tower__r.Registration_Charges__c, Tower__r.Stamp_Duty_Percentage__c
                             FROM Unit__c 
                             WHERE Id = :unitID AND Tower__c != null LIMIT 1];
            
            // Validate Price Details from Tower and Unit
            if(unit == null ||
               (unit.All_in_Price__c == null && unit.Agreement_Value__c == null) ||
               unit.Total_Other_Charges_Including_Tax__c == null ||
               unit.Tower__r.GST_Percentage__c == null ||
               unit.Tower__r.Registration_Charges__c == null ||
               unit.Tower__r.Stamp_Duty_Percentage__c == null){
                    String message = 'Error in getting charge details from Unit : ' + unitID + ' ' +
                                     '(Please ensure that all required charge details are present on Unit/Tower)';
                    throw new CustomException(message);
            }

            // Prepare Charge Details
            Decimal totalOtherChargeIncGST = getTotalOtherChargeIncGST(unit.Id);
            ChargeDetails chargeDetails = new ChargeDetails(
                unit.All_in_Price__c,
                unit.Agreement_Value__c,
                totalOtherChargeIncGST,     
                unit.Tower__r.Registration_Charges__c,
                unit.Tower__r.Stamp_Duty_Percentage__c,
                unit.Tower__r.GST_Percentage__c
            );
            return chargeDetails;

        } catch (QueryException e) {
            throw new CustomException('Unable to get Charge details from Unit as no Unit found with provided unitID : ' + unitID, e);    
        }

    }

    
    // Returns the sum of all other charges
    private static Decimal getTotalOtherChargeIncGST(List<Other_Charges__c> otherCharges){
        Decimal totalOtherChargeIncGST = 0;
        if(otherCharges != null && !otherCharges.isEmpty()){
            for (Other_Charges__c otherCharge : otherCharges) {
                totalOtherChargeIncGST = totalOtherChargeIncGST + otherCharge.Charge_Amount_Including_GST__c;
            }
        }

        return totalOtherChargeIncGST;
    }

    private static Decimal getTotalOtherChargeIncGST(String unitID){
        List<Other_Charges__c> otherCharges = getOtherCharges(unitID);

        Decimal totalOtherChargeIncGST = 0;
        if(otherCharges != null && !otherCharges.isEmpty()){
            for (Other_Charges__c otherCharge : otherCharges) {
                totalOtherChargeIncGST = totalOtherChargeIncGST + otherCharge.Charge_Amount_Including_GST__c;
            }
        }

        return totalOtherChargeIncGST;
    }

    // Returns the all Other Charges maintained against Unit
    @AuraEnabled(cacheable=true)
    public static List<Other_Charges__c> getOtherCharges(String unitID){
        
        try{

            Boolean isValidUnitID = isValidRecordID(unitID);
            if(!isValidUnitID){
                throw new CustomException('Invalid Record ID for Unit : ' + unitID);
            }

            // Get Other charges
            List<Other_Charges__c> otherCharges = [SELECT Id, Name, Unit__c, Charge_Type__c, Charge_Amount__c,
                                                          GST_Percentage__c, Charge_Amount_Including_GST__c
                                                   FROM Other_Charges__c
                                                   WHERE Unit__c = :unitID];
            return otherCharges;
        }
        catch(Exception e){
            throw new CustomException(
                'Unexpected error occurred while retrieving the other charges, ' +
                'please contact System Administrator'
            );
        }
    }
    
    public class QuotationWrapper{
           @AuraEnabled 
           public Quotation__c q { get; set; }
           public QuotationWrapper(){
               q = new Quotation__c();
           }
    }  
       
       @AuraEnabled
       public static QuotationWrapper getQuotationWrapper(Unit__c unit){
           System.debug('unit: '+unit);
           QuotationWrapper q = new QuotationWrapper();
           if(unit.All_in_Price__c != null){
               q.q.All_in_Price__c = unit.All_in_Price__c;
           }
           if(unit.Project__c != null){
               q.q.Project__c = unit.Project__c;
           }
           if(unit.Tower__c != null){
               q.q.Tower__c = unit.Tower__c;
           }
           if(unit.Id != null){
               q.q.Unit__c = unit.Id;
           }
           if(unit.Tower__r.Stamp_Duty_Percentage__c != null){
               q.q.Stamp_Duty_Percentage__c = unit.Tower__r.Stamp_Duty_Percentage__c;
           }
           if(unit.Tower__r.Registration_Charges__c != null){
               q.q.Registration_Charges__c = unit.Tower__r.Registration_Charges__c;
           }
           if(unit.Tower__r.GST_Percentage__c != null){
               q.q.GST_Percentage__c = unit.Tower__r.GST_Percentage__c;
           }
           if(unit.Total_Other_Charges_Including_Tax__c != null){
               q.q.Total_Other_Charges_Including_Tax__c = unit.Total_Other_Charges_Including_Tax__c;
           }
          
           return q;
       }
       
       
       @AuraEnabled
       public static Unit__c getUnitDetails(String unitId){
           List<Unit__c> uList = new List<Unit__c>(); 
           uList = [Select Id, Name, Floor__c, Sale_Status__c, Configuration_Type__c, Total_carpet_Sq_Ft__c, Tower__c, Tower__r.Name,
                    Tower__r.Stamp_Duty_Percentage__c, Tower__r.Registration_Charges__c, All_in_Price__c, Tower__r.GST_Percentage__c, Project__c, PSF_Rate__c,
                    Tower__r.Project__c, Threshold_Amount__c, PSF__c, Threshold_Percentage__c
                     FROM Unit__c WHERE Id =: unitId];
           system.debug('uList: '+uList);
           if(!uList.isEmpty() && uList != null){
               return uList[0];
           }else{
               return null;
           }
       }
       
       
       @AuraEnabled
       public static List<Payment_Scheme__c> getPaymentSchemeDetails(Id tId) {
           List<Payment_Scheme__c> schemeList = Ex_InventoryPriceManagementServices.getPaymentSchemeInfo(tId);
           system.debug('schemeList: '+schemeList);
           return schemeList;
       }
       
       @AuraEnabled(Cacheable = false)
       public static List<Ex_InventoryPriceManagementServices.CarParkWrapper> getCarParkDetails(String pId, String tId) {
           List<Ex_InventoryPriceManagementServices.CarParkWrapper> carParkList = new List<Ex_InventoryPriceManagementServices.CarParkWrapper>();
           carParkList = Ex_InventoryPriceManagementServices.getCarParkInfo(pId, tId);
           system.debug('carParkList: '+carParkList);
           return carParkList;
       }
       
       @AuraEnabled
       public static Map<String, List<String>> getPriceListGroupMapDetails(Id uId,Decimal OrginalAV,Decimal OrginalAllPriceIn, Decimal OrginalStampDuty, Decimal OrginalRegistration,Decimal OrginalOtherCharges,Decimal carParkAmount,Boolean referalDiscount) {
               System.debug('uId: '+uId);
               System.debug('orginalAV: '+orginalAV);
               System.debug('orginalAllPriceIn: '+orginalAllPriceIn);
               System.debug('orginalStampDuty: '+orginalStampDuty);
               System.debug('orginalRegistration: '+orginalRegistration);
               System.debug('orginalOtherCharges: '+orginalOtherCharges);
               System.debug('carParkAmount: '+carParkAmount);
               if(orginalOtherCharges == null){
                   orginalOtherCharges = 0;
               }
           Map<String, List<String>> priceListGroupMap = Ex_InventoryPriceManagementServices.getPriceListGroupMap(uId, orginalAV, orginalAllPriceIn, orginalStampDuty, orginalRegistration, orginalOtherCharges, carParkAmount, referalDiscount);
           system.debug('priceListGroupMap: '+priceListGroupMap);
           return priceListGroupMap;
       }
       
       @AuraEnabled
       public static Map<String, Decimal> getAllPriceMapDetails(Id uId, Map<String, List<String>> priceListGroupMap, Decimal carParkAmount) {
           Map<String, Decimal> allPriceInfoMap = Ex_InventoryPriceManagementServices.getAllPriceInfo(uId, priceListGroupMap, carParkAmount);
           system.debug('allPriceInfoMap: '+allPriceInfoMap);
           return allPriceInfoMap;
       }
   
       @AuraEnabled
       public static Map<String, String> getAllPriceInfoFormattedMap(Map<String, Decimal> allPriceInfoMap) {
           Map<String, String> allPriceInfoFormattedMap = new Map<String, String>();
           if(allPriceInfoMap != null && !allPriceInfoMap.isEmpty()) {
               for(String ch: allPriceInfoMap.keySet()) {
                   allPriceInfoFormattedMap.put(ch, Ex_InventoryPriceManagementServices.currencyFormat(allPriceInfoMap.get(ch)));
               }
           }
           return allPriceInfoFormattedMap;
       }
   
       @AuraEnabled
       public static List<String> getPicklistValues(String objectName, String picklistField) {
           List<String> values = new List<String>();
           Schema.SObjectType objSobjectType = Schema.getGlobalDescribe().get(objectName) ;
           Schema.DescribeSObjectResult objDescribeSobject = objSobjectType.getDescribe() ;
           Map<String,Schema.SObjectField> fields = objDescribeSobject.fields.getMap() ;
           Schema.DescribeFieldResult fieldResult = fields.get(picklistField).getDescribe();
           List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
           for(Schema.PicklistEntry pickListVal : ple){
               values.add(pickListVal.getValue());
           }
           return values;
       }
       
       @AuraEnabled
       public static List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> getPaymentScheduleDetails(Id uId, Id selectedScheme, Decimal getModifiedAV, Decimal gst, decimal getModifiedGstAmount) {
           List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> paymentMilestoneWrapperList = Ex_InventoryPriceManagementServices.getPaymentSummaryInfo(uId, selectedScheme, getModifiedAV, gst,getModifiedGstAmount );
          system.debug('paymentMilestoneWrapperList: '+paymentMilestoneWrapperList);
           return paymentMilestoneWrapperList;
       }
       
       @AuraEnabled
       public static List<String> validateUpdatedPaymentScheduleDetails(Integer agSeqNumber, Decimal getModifiedAv, List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> updatedPaymentMilestoneWrapperList) {
           List<String> validationErrorList = Ex_InventoryPriceManagementServices.validateUpdatedPaymentSchedule(agSeqNumber, getModifiedAv, updatedPaymentMilestoneWrapperList);
           system.debug('validationErrorList: '+validationErrorList);
           return validationErrorList;
       }
       
       @AuraEnabled
       public static List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> getUpdatedPaymentScheduleDetails(Unit__c u, Integer agSeqNumber, Decimal getModifiedAV, List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> updatedPaymentMilestoneWrapperList, Decimal gstAmount, Decimal gstPer) {
           List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> paymentMilestoneWrapperList = Ex_InventoryPriceManagementServices.getUpdatedPaymentSchedule(u, agSeqNumber, getModifiedAV, updatedPaymentMilestoneWrapperList, gstAmount, gstPer);
           system.debug('paymentMilestoneWrapperList: '+paymentMilestoneWrapperList);
           
           return paymentMilestoneWrapperList;
       }
       
       @AuraEnabled
       public static List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> getModifiedPaymentScheduleDetails(String actionType, Integer rowIndex, List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> paymentMilestoneWrapperList, Unit__c u, Integer agSeqNumber) {
           List<Construction_Stage__c> cStageList = Ex_InventoryPriceManagementServices.getConsturctionStageList(u.Project__c, u.Tower__c);
           
           if(!paymentMilestoneWrapperList.isEmpty() && paymentMilestoneWrapperList != null) {
               if(actionType.endsWithIgnoreCase('Add')) {
                   Payment_Scheme_Milestone__c psm = new Payment_Scheme_Milestone__c();
                   psm.put('Charge_Bucket_'+agSeqNumber+'_Type__c', '');
                   
                   Payment_Milestone__c pm = new Payment_Milestone__c();
                   pm.put('Charge_Bucket_'+agSeqNumber+'__c', 'Agreement Value');
                   pm.put('Number_of_Days__c', 0);
                   pm.put('Milestone_Type__c', '');
                   pm.put('Construction_Stage__c', null);
                   pm.put('Charge_Bucket_'+agSeqNumber+'_Percentage__c', 0);
                   pm.put('Charge_Bucket_'+agSeqNumber+'_Amount__c', 0);
                   
                   Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper pmw = new Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper(psm, pm, cStageList, '', 0, 0, '', 0, '', 0, '', false, true, false);
                   paymentMilestoneWrapperList.add(rowIndex+1, pmw);
               } else if(actionType.endsWithIgnoreCase('Remove')) {
                   paymentMilestoneWrapperList.remove(rowIndex);
               }
           }
           system.debug('Size: '+paymentMilestoneWrapperList.size());
           return paymentMilestoneWrapperList;
       }
       
       
       @AuraEnabled
       public static Id saveQuotationDetails(Unit__c u, Id oppId, Id selectedSchemeId, List<Ex_InventoryPriceManagementServices.CarParkWrapper> carParkList,
                                             List<Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper> paymentMilestoneWrapperList, QuotationWrapper qWrapper,
                                             List<Map<String, Object>> otherCharges, Boolean isTenantAccount, Date diDate, Decimal BillAmount) {
                                                 
           try {
               Quotation__c q = new Quotation__c();
               System.debug('qWrapper: '+qWrapper);
               System.debug('otherCharges: '+otherCharges);
               System.debug('isTenantAccount: '+isTenantAccount+ 'qWrapper.q.Differential_Carpet_Area__c: '+qWrapper.q.Differential_Carpet_Area__c);
               System.debug('diDate: '+diDate+ 'BillAmount: '+BillAmount);
               if(qWrapper.q.All_in_Price__c != null){
                   q.All_in_Price__c = qWrapper.q.All_in_Price__c;
               }
               if(qWrapper.q.Modified_All_in_Price__c != null){
                   q.Modified_All_in_Price__c = qWrapper.q.Modified_All_in_Price__c;
               }
               if(qWrapper.q.Modified_Stamp_Duty__c != null){
                   q.Modified_Stamp_Duty__c = qWrapper.q.Modified_Stamp_Duty__c;
               }
               if(u.Tower__r.Stamp_Duty_Percentage__c != null){
                   q.Stamp_Duty_Percentage__c = u.Tower__r.Stamp_Duty_Percentage__c;
               }
               if(qWrapper.q.Modified_Registration_Charges__c != null){
                   q.Modified_Registration_Charges__c = qWrapper.q.Modified_Registration_Charges__c;
               }
               if(u.Tower__r.Registration_Charges__c != null){
                   q.Registration_Charges__c = u.Tower__r.Registration_Charges__c;
               }
               if(qWrapper.q.Orginal_AV_Value__c != null){
                   q.Orginal_AV_Value__c = qWrapper.q.Orginal_AV_Value__c;
               }
               if(qWrapper.q.Modified_AV_Value__c != null){
                   q.Modified_AV_Value__c = qWrapper.q.Modified_AV_Value__c;
               }
                if(qWrapper.q.Total_Other_Charges_Including_Tax__c != null){
                   q.Total_Other_Charges_Including_Tax__c = qWrapper.q.Total_Other_Charges_Including_Tax__c;
               }
                if(qWrapper.q.Modified_Other_Charges_Including_Tax__c != null){
                   q.Modified_Other_Charges_Including_Tax__c = qWrapper.q.Modified_Other_Charges_Including_Tax__c;
               }
               if(qWrapper.q.Car_Park_Amount__c != null){
                   q.Car_Park_Amount__c = qWrapper.q.Car_Park_Amount__c;
               }
               if(qWrapper.q.Car_Park_Required_Count__c != null){
                   q.Car_Park_Required_Count__c = qWrapper.q.Car_Park_Required_Count__c;
               }
               if(qWrapper.q.Modified_GST__c != null){
                   q.Modified_GST__c = qWrapper.q.Modified_GST__c;
               }
               if(u.Tower__r.GST_Percentage__c != null){
                   q.GST__c = u.Tower__r.GST_Percentage__c;
               }
               if(qWrapper.q.Pricing_Plan__c != null){
                    q.Pricing_Plan__c = qWrapper.q.Pricing_Plan__c;
               }
               
               if(qWrapper.q.GST_Charges__c != null){
                    q.GST_Charges__c = qWrapper.q.GST_Charges__c;
               }
               if(qWrapper.q.Modified_GST_Charges__c != null){
                    q.Modified_GST_Charges__c = qWrapper.q.Modified_GST_Charges__c;
               }

               //  Final Committed Area details
               if(qWrapper.q.Original_Final_Committed_Area__c != null){
                q.Original_Final_Committed_Area__c = qWrapper.q.Original_Final_Committed_Area__c;
               }
               if(qWrapper.q.Modified_Final_Committed_Area__c != null){
                       q.Modified_Final_Committed_Area__c = qWrapper.q.Modified_Final_Committed_Area__c;
               }

               // Stamp Duty Charges
               if(qWrapper.q.Stamp_Duty_Charges__c != null){
                    q.Stamp_Duty_Charges__c = qWrapper.q.Stamp_Duty_Charges__c;
               }
               if(qWrapper.q.Modified_Stamp_Duty_Charges__c != null){
                    q.Modified_Stamp_Duty_Charges__c = qWrapper.q.Modified_Stamp_Duty_Charges__c;
               }

               //  Save Applied Discount
               if(qWrapper.q.Applied_Discount__c != null) {
                    q.Applied_Discount__c = qWrapper.q.Applied_Discount__c;
               }
               if(isTenantAccount){
                   if(qWrapper.q.Original_PSF_Rate__c != null) {
                       q.Original_PSF_Rate__c = qWrapper.q.Original_PSF_Rate__c;
                   }
                   if(qWrapper.q.Modified_PSF_Rate__c != null) {
                       q.Modified_PSF_Rate__c = qWrapper.q.Modified_PSF_Rate__c;
                   }
                   if(qWrapper.q.Differential_Carpet_Area__c != null) {
                       q.Differential_Carpet_Area__c = qWrapper.q.Differential_Carpet_Area__c;
                   }
               }
              
               // q.Referal_Discount__c = qWrapper.q.Referal_Discount__c;
               q.Unit__c = u.Id;
               q.Project__c = u.Tower__r.Project__c;
               q.Tower__c = u.Tower__c;
               q.Payment_Scheme__c = selectedSchemeId;    
               if(!isTenantAccount){
                   q.Opportunity__c = oppId;
               }
               if(isTenantAccount && Integer.valueof(qWrapper.q.Differential_Carpet_Area__c) > 0){
                   q.Tenant_Account__c = oppId; 
               }
               if(isTenantAccount && Integer.valueof(qWrapper.q.Differential_Carpet_Area__c) < 0){
                   List<Bill__c> insertBill = new List<Bill__c>();
                   List<Account> updateTenant = new List<Account>();
                   q.Tenant_Account__c = oppId;

                   //  Create Excess Carpet Area Bill
                   Ex_DraftBillController.createBillForExcessCarpetArea(oppId, diDate, BillAmount);
                   
                   Account ac = new Account();
                   ac.Differential_Payment_Type__c = 'Lumpsum';
                   ac.Differential_Specific_Date__c = diDate;
                   ac.Differential_Amount__c = BillAmount;
                   ac.Differential_Carpet_Area_Eligibility__c = 'Yes';
                   ac.Differential_Frequency__c = 'One Time Payment';
                   ac.Id = oppId;
                   updateTenant.add(ac);
                   System.debug('updateTenantBefore: '+updateTenant);
                   if(updateTenant != null && !updateTenant.isEmpty()){
                       update updateTenant;
                   }
                    System.debug('updateTenantAfter: '+updateTenant);
                    System.debug('insertBillBefore: '+insertBill);
                   if(insertBill != null && !insertBill.isEmpty()){
                       insert insertBill;
                   }
                    System.debug('insertBillAfter: '+insertBill);
               }
               
                      
               
               Id qId = null;
               Database.saveResult sr = Database.insert(q);
               if(sr.isSuccess()) {
                   qId = sr.getId();
                   List<Car_Park_Required__c> carParkReqList = new List<Car_Park_Required__c>();
                   List<Payment_Milestone__c> paymentMilestoneList = new List<Payment_Milestone__c>();
                   if(carParkList != null && !carParkList.isEmpty()) {
                       for(Ex_InventoryPriceManagementServices.CarParkWrapper cp: carParkList) {
                           if(cp.carParkRequiredCount > 0) {
                               Car_Park_Required__c cpr = new Car_Park_Required__c();
                               cpr.Quotation__c = qId;
                               cpr.Car_Park_Type__c = cp.carParkType;
                               cpr.Car_Park_Count__c = cp.carParkRequiredCount;
                               cpr.Car_Park_Amount__c = cp.carParkAmount * cp.carParkRequiredCount;
                               carParkReqList.add(cpr);
                           }
                       }
                   }
                   
                   if(isTenantAccount && q.Modified_AV_Value__c > 0){
                       if(paymentMilestoneWrapperList != null && !paymentMilestoneWrapperList.isEmpty()) {
                           system.debug('paymentMilestoneWrapperList:'+ paymentMilestoneWrapperList);
                           Integer i = 1;
                           for(Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper pmw: paymentMilestoneWrapperList) {
                               if(pmw.pm != null) {
                                   pmw.pm.Sequence_Number__c = i;
                                   pmw.pm.Quotation__c = qId;
                                   paymentMilestoneList.add(pmw.pm);
                                   i++;
                               }
                           }
                       }
                   }
                   if(!isTenantAccount){
                       if(paymentMilestoneWrapperList != null && !paymentMilestoneWrapperList.isEmpty()) {
                           system.debug('paymentMilestoneWrapperList:'+ paymentMilestoneWrapperList);
                           Integer i = 1;
                           for(Ex_InventoryPriceManagementServices.PaymentMilestoneWrapper pmw: paymentMilestoneWrapperList) {
                               if(pmw.pm != null) {
                                   pmw.pm.Sequence_Number__c = i;
                                   pmw.pm.Quotation__c = qId;
                                   paymentMilestoneList.add(pmw.pm);
                                   i++;
                               }
                           }
                       }
                   }
                   
                   
                   if(!carParkReqList.isEmpty() && carParkReqList != null) {
                       insert carParkReqList;
                   }
                   
                   if(!paymentMilestoneList.isEmpty() && paymentMilestoneList != null) {
                       if(isTenantAccount && q.Modified_AV_Value__c > 0){
                           insert paymentMilestoneList;
                       }else if(!isTenantAccount){
                           insert paymentMilestoneList;
                       }
                   }

                   //  Add 'Included Other Charges' records against the Quotation
                   Boolean otherChargesIncludedInsertStatus = insertOtherChargesIncluded(otherCharges, qId);
                   if(!otherChargesIncludedInsertStatus){
                        throw new CustomException('Internal Server Error while inserting records for \'Other Charges Included\' ');
                   }

                   return qId;
               } else {
                   for(Database.Error err : sr.getErrors()) {
                       system.debug('Error: '+err);
                   }
                   return null;
               }
           } catch (Exception e) {
               system.debug('Error: '+e.getMessage());
               return null;
           }
       }


    private static Boolean insertOtherChargesIncluded(List<Map<String, Object>> otherCharges, String quotationID){
        
        Boolean insertionStatus = false;
        List<Other_Charges_Included__c> otherChargesToInsert = new List<Other_Charges_Included__c>();
        
        if(otherCharges != null && !otherCharges.isEmpty()){
            for (Map<String, Object> otherCharge : otherCharges) {
                Other_Charges_Included__c otherChargeIncluded = new Other_Charges_Included__c();
                otherChargeIncluded.Quotation__c =  quotationID;

                String chargeType = (String)otherCharge.get('chargeName');
                otherChargeIncluded.Charge_Type__c = chargeType;

                Decimal chargeAmount = (Decimal)otherCharge.get('chargeAmount');
                otherChargeIncluded.Charge_Amount__c = chargeAmount;

                Decimal GSTPercentage = (Decimal)otherCharge.get('GSTPercentage');
                otherChargeIncluded.GST_Percentage__c = GSTPercentage;

                otherChargesToInsert.add(otherChargeIncluded);
            }
        }

        try {
            INSERT otherChargesToInsert;
            insertionStatus = true;
        } catch (Exception e) {
            System.debug('Error in inserting other charges');
        }
        return insertionStatus;
    }

    // ---- Utility Methods ----

    // Standard Validation to check RecordID 
    private static Boolean isValidRecordID(String recordID){

        if(recordID == null || String.isBlank(recordID) || String.isEmpty(recordID)){
            return false;
        }

        try {
            Id validRecordID = Id.valueOf(recordID);
            return true;
        } catch (StringException e){
            return false;
        } 
    }
       

    // You can create structure of data as Map which can be shared on frontend and 
    // backend as well instead of Wrapper
    
    // ---- Custom Exception ----
    public class CustomException extends Exception {}

    
   }