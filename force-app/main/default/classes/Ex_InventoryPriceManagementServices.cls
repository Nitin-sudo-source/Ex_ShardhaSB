public class Ex_InventoryPriceManagementServices {
    public static List<CarParkWrapper> getCarParkInfo(Id pId, Id tId) { 
        List<CarParkWrapper> carParkList = new List<CarParkWrapper>();
        List<AggregateResult> cpList = new List<AggregateResult>();
        
        Project__c pro = [SELECT Id, Name, Car_Park_Maintain_At__c FROM Project__c WHERE Id = :pId];
        
        if (pro != null) {
            if (!String.isBlank(pro.Car_Park_Maintain_At__c) && pro.Car_Park_Maintain_At__c.equalsIgnoreCase('Project Level')) {
                cpList = [SELECT Count(Id) cpCount, Car_Park_Type__c, MAX(Amount__c) cpAmount FROM Car_Park__c
                          WHERE Status__c = 'Available' AND Project__c = :pId
                          GROUP BY Car_Park_Type__c ORDER BY Car_Park_Type__c];
                System.debug('cpList: ' + cpList);                
            }
            else if (!String.isBlank(pro.Car_Park_Maintain_At__c) && pro.Car_Park_Maintain_At__c.equalsIgnoreCase('Tower Level')) {
                cpList = [SELECT Count(Id) cpCount, Car_Park_Type__c, MAX(Amount__c) cpAmount FROM Car_Park__c
                          WHERE Status__c = 'Available' AND Project__c = :pId AND Tower__c = :tId
                          GROUP BY Car_Park_Type__c ORDER BY Car_Park_Type__c];
                System.debug('cpList: ' + cpList);
            }
        }
        
        if (cpList != null && !cpList.isEmpty()) {
            for(AggregateResult ag: cpList) {
                carParkList.add(new CarParkWrapper((String)ag.get('Car_Park_Type__c'), (Decimal)ag.get('cpCount'), (Decimal)ag.get('cpAmount'), 0, currencyFormat((Decimal)ag.get('cpAmount'))));
            }
        }
        return carParkList;
    }
    
    public class PriceWrapper {
        @AuraEnabled
        public String chargeBucket { get; set; }
        @AuraEnabled
        public String chargeName { get; set; }
        @AuraEnabled
        public Decimal actualCost { get; set; }
        @AuraEnabled
        public Decimal gst { get; set; }
        @AuraEnabled
        public Decimal chargePercentage { get; set; }
        @AuraEnabled
        public String chargeType { get; set; }
        
        // Constructor
        public PriceWrapper(String chargeBucket, String chargeName, Decimal actualCost, Decimal gst, Decimal chargePercentage, String chargeType) {
            this.chargeBucket = chargeBucket;
            this.chargeName = chargeName;
            this.actualCost = actualCost;
            this.gst = gst;
            this.chargePercentage = chargePercentage;
            this.chargeType = chargeType;
        }
    }
    
    public static List<PriceWrapper> getPriceListInfo(Id uId, Decimal orginalAV, Decimal orginalAllPriceIn,Decimal orginalStampDuty, Decimal orginalRegistration, Decimal orginalOtherCharges,Decimal carParkAmount,Boolean referalDiscount) {
        List<PriceWrapper> priceList = new List<PriceWrapper>();
        //Unit__c u = Ex_GenerateQuotation.getUnitDetails(uId);
        priceList.add(new PriceWrapper('Agreement Value', 'Agreement Value', orginalAV, (orginalAV * 5)/100, 5, 'Lumpsum'));
        priceList.add(new PriceWrapper('Agreement Value', 'Stamp Duty', orginalStampDuty, (orginalStampDuty * 5)/100, 5, 'PSF'));
        priceList.add(new PriceWrapper('Agreement Value', 'Registration Charges', orginalRegistration, (orginalRegistration * 5)/100, 5, 'Lumpsum'));
        System.debug('priceList: '+priceList);
        return priceList;
    }
    
    @AuraEnabled
    public static Map<String, List<String>> getPriceListGroupMap(Id uId,
                                                                 Decimal orginalAV,
                                                                 Decimal orginalAllPriceIn,
                                                                 Decimal orginalStampDuty,
                                                                 Decimal orginalRegistration,
                                                                 Decimal orginalOtherCharges,
                                                                 Decimal carParkAmount,
                                                                 Boolean referalDiscount) {
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
                                                                     
                                                                     if(uId != null) {
                                                                         Map<String, List<String>> priceListGroupMap = new Map<String, List<String>>();
                                                                         List<PriceWrapper> priceList = getPriceListInfo(uId, orginalAV, orginalAllPriceIn, orginalStampDuty, orginalRegistration, orginalOtherCharges, carParkAmount, referalDiscount);
                                                                         System.debug('priceList: '+priceList);
                                                                         if(priceList != null) {
                                                                             for(PriceWrapper pw: priceList) {
                                                                                 if(priceListGroupMap.containsKey(pw.chargeBucket)) {
                                                                                     priceListGroupMap.get(pw.chargeBucket).add(pw.chargeName);
                                                                                 } else {
                                                                                     List<String> newList = new List<String>();
                                                                                     newList.add(pw.chargeName);
                                                                                     priceListGroupMap.put(pw.chargeBucket, newList);
                                                                                 }
                                                                             }
                                                                             /*if(priceListGroupMap.containsKey('Agreement Value')) {
priceListGroupMap.get('Agreement Value').add('Parking Charges');
}*/
                                                                         }
                                                                         System.debug('priceListGroupMap: '+priceListGroupMap);
                                                                         return priceListGroupMap;
                                                                     } else {
                                                                         return null;
                                                                     }
                                                                 }
    
    public static Map<String, Decimal> getAllPriceInfo(String uId, Map<String, List<String>> priceListGroupMap, Decimal carParkPrice) {
        Unit__c u =Ex_GenerateQuotation.getUnitDetails(uId);
        if(u != null) {
            Map<String, Decimal> allPriceInfoMap = new Map<String, Decimal>();
            Map<String, PriceWrapper> priceListMap = new Map<String, PriceWrapper>();
            
            // Creating a PriceWrapper instance
            PriceWrapper pw = new PriceWrapper('Agreement Value', 'Parking Charges', carParkPrice, null, null, 'Lumpsum');
            priceListMap.put(pw.chargeName, pw);
            
            if(carParkPrice != null){
                allPriceInfoMap.put('Total Car Park Price', carParkPrice);
            }
            
            // Assuming priceListGroupMap is available and populated elsewhere
            for(String priceGroup: priceListGroupMap.keySet()) {
                if(!priceGroup.equalsIgnoreCase('Statutory Charges')) {
                    for(String priceList: priceListGroupMap.get(priceGroup)) {
                        Decimal amount = 0;
                        Decimal sgst = 0;
                        Decimal cgst = 0;
                        
                        if(priceListMap.containsKey(priceList)) {
                            PriceWrapper currentPriceWrapper = priceListMap.get(priceList);
                            
                            if(currentPriceWrapper.chargeName.equalsIgnoreCase('Parking Charges')) {
                                amount = carParkPrice;
                                sgst = (((carParkPrice / 100) * priceListMap.get('Basic Charge').gst) / 2).setScale(0, RoundingMode.HALF_UP);
                                cgst = (((carParkPrice / 100) * priceListMap.get('Basic Charge').gst) / 2).setScale(0, RoundingMode.HALF_UP);
                            } else {
                                amount = (currentPriceWrapper.actualCost).setScale(0, RoundingMode.HALF_UP);
                                sgst = (currentPriceWrapper.gst / 2).setScale(0, RoundingMode.HALF_UP);
                                cgst = (currentPriceWrapper.gst / 2).setScale(0, RoundingMode.HALF_UP);
                            }
                            
                            allPriceInfoMap.put(priceList, amount);
                            allPriceInfoMap.put(priceList + ' SGST', sgst);
                            allPriceInfoMap.put(priceList + ' CGST', cgst);
                            allPriceInfoMap.put(priceList + ' TAX', (sgst + cgst));
                            
                            // Grouping Pricing Information
                            if(allPriceInfoMap.containsKey(currentPriceWrapper.chargeBucket)) {
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket, allPriceInfoMap.get(currentPriceWrapper.chargeBucket) + amount);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SGST', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' SGST') + sgst);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' CGST', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' CGST') + cgst);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' TAX', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' TAX') + sgst + cgst);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SIZE', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' SIZE') + 1);
                            } else {
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket, amount);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SGST', sgst);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' CGST', cgst);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' TAX', sgst + cgst);
                                allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SIZE', 1);
                            }
                        }
                    }
                }
            }
            
            // Apply discount logic (similar to original code) and other computations
            
            // Statutory Charges Processing (same logic as original)
            if(priceListGroupMap.containsKey('Statutory Charges')) {
                for(String priceList: priceListGroupMap.get('Statutory Charges')) {
                    PriceWrapper currentPriceWrapper = priceListMap.get(priceList);
                    Decimal amount = 0;
                    Decimal sgst = 0;
                    Decimal cgst = 0;
                    
                    if(currentPriceWrapper.chargeType.equalsIgnoreCase('Percentage')) {
                        Decimal roundednum = ((allPriceInfoMap.get('Agreement Value') * currentPriceWrapper.chargePercentage) / 100).setScale(0, RoundingMode.HALF_UP);
                        Integer rounded = ((Integer.valueOf(roundednum) + 99) / 100) * 100;
                        system.debug('rounded:'+rounded);
                        amount = rounded;
                    } else {
                        amount = (currentPriceWrapper.actualCost).setScale(0, RoundingMode.HALF_UP);
                    }
                    
                    sgst = (((amount / 100) * currentPriceWrapper.gst) / 2).setScale(0, RoundingMode.HALF_UP);
                    cgst = (((amount / 100) * currentPriceWrapper.gst) / 2).setScale(0, RoundingMode.HALF_UP);
                    
                    allPriceInfoMap.put(priceList, amount);
                    allPriceInfoMap.put(priceList + ' SGST', sgst);
                    allPriceInfoMap.put(priceList + ' CGST', cgst);
                    allPriceInfoMap.put(priceList + ' TAX', (sgst + cgst));
                    
                    // Grouping Pricing Information
                    if(allPriceInfoMap.containsKey(currentPriceWrapper.chargeBucket)) {
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket, allPriceInfoMap.get(currentPriceWrapper.chargeBucket) + amount);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SGST', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' SGST') + sgst);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' CGST', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' CGST') + cgst);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' TAX', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' TAX') + sgst + cgst);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SIZE', allPriceInfoMap.get(currentPriceWrapper.chargeBucket + ' SIZE') + 1);
                    } else {
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket, amount);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SGST', sgst);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' CGST', cgst);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' TAX', sgst + cgst);
                        allPriceInfoMap.put(currentPriceWrapper.chargeBucket + ' SIZE', 1);
                    }
                }
            }
            
            system.debug('allPriceInfoMap: ' + allPriceInfoMap);
            return allPriceInfoMap;
        } else {
            return null;
        }
    }
    
    
    public static List<Payment_Scheme__c> getPaymentSchemeInfo(Id tId) {
        List<Payment_Scheme__c> schemeList = new List<Payment_Scheme__c>();
        String[] types = new String[]{'Payment_Scheme__c'};
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
        String soqlQuery = 'Select ' + queryFields  + ' from Payment_Scheme__c Where Tower__c = \''+tId+'\' AND Is_Active__c = true'; 
        system.debug(soqlQuery);
        schemeList = Database.query(soqlQuery);
        if (schemeList.size() > 0) {
            return schemeList;
        } else {
            return null;
        }
    }
    
    public static List<Construction_Stage__c> getConsturctionStageList(Id pId, Id tId) {
        List<Construction_Stage__c> cStageList = new List<Construction_Stage__c>();
        String[] types = new String[]{'Construction_Stage__c'};
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
        String soqlQuery = 'Select ' + queryFields  + ' from Construction_Stage__c Where Tower__c = \''+tId+'\' AND Tower__r.Project__c = \''+pId+'\' ORDER BY Sequence_Number__c ASC'; 
        system.debug(soqlQuery);
        cStageList = Database.query(soqlQuery);
        if (cStageList.size() > 0) {
            return cStageList;
        } else {
            return null;
        }
    }
    
    public static Map<Id, Construction_Stage__c> getConstructionStagesMap(Id pId, Id tId) {
        Map<Id, Construction_Stage__c> cStageMap = new Map<Id, Construction_Stage__c>();
        List<Construction_Stage__c> cStageList = getConsturctionStageList(pId, tId);
        
        if(cStageList != null) {
            for(Construction_Stage__c cs: cStageList) {
                cStageMap.put(cs.Id, cs);
            }
        }
        return cStageMap;
    }
    
    public static List<Payment_Scheme_Milestone__c> getPaymentSchemeMilestoneInfo(Id schemeId) {
        List<Payment_Scheme_Milestone__c> psMilestoneList = new List<Payment_Scheme_Milestone__c>();
        String[] types = new String[]{'Payment_Scheme_Milestone__c'};
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
        String soqlQuery = 'Select Construction_Stage__r.Name, Payment_Scheme__r.Is_Mergeable__c, ' + queryFields  + '  from Payment_Scheme_Milestone__c Where Payment_Scheme__c = \''+schemeId+'\' ORDER BY Sequence_Number__c ASC'; 
        system.debug(soqlQuery);
        psMilestoneList = Database.query(soqlQuery);
        if (psMilestoneList.size() > 0) {
            return psMilestoneList;
        } else {
            return null;
        }
    }
    
    public static List<PaymentMilestoneWrapper> getPaymentSummaryInfo(Id uId, Id schemeId, Decimal getModifiedAV, Decimal gst ,decimal getModifiedGstAmount) {
        System.debug('getModifiedAV: '+ getModifiedAV);
        System.debug('gst: '+ gst);
        System.debug('getModifiedGstAmount: '+ getModifiedGstAmount);
        Decimal  grandTotalTax2 = 0;
        List<PaymentMilestoneWrapper> paymentMilestoneWrapperList = new List<PaymentMilestoneWrapper>();
        List<Payment_Scheme_Milestone__c> psMilestoneList = getPaymentSchemeMilestoneInfo(schemeId);
        Unit__c u = Ex_GenerateQuotation.getUnitDetails(uId);
        
        if(u != null) {
            List<Construction_Stage__c> cStageList = getConsturctionStageList(u.Project__c, u.Tower__c);
            List<SelectOption> cStageOptionList = new List<SelectOption>();
            if(cStageList != null && !cStageList.isEmpty()) {
                cStageOptionList.add(new SelectOption('', '--None--'));
                for(Construction_Stage__c cs : cStageList) {
                    cStageOptionList.add(new SelectOption(cs.Id, cs.Name));
                }
            }
            
            Map<Id, Construction_Stage__c> cStageMap = getConstructionStagesMap(u.Project__c, u.Tower__c);
            
            if(psMilestoneList != null) {
                Decimal tokenAmount = 0;
                Decimal grandAmount = 0;
                Decimal grandPercentage = 0;
                Decimal grandSGST = 0;
                Decimal grandCGST = 0;
                Decimal grandTotalTax = 0;
                Decimal grandTotal = 0;
                
                for(Payment_Scheme_Milestone__c psm: psMilestoneList) {
                    Decimal amount = 0;
                    Decimal percentage = 0;
                    Decimal sgst = 0;
                    Decimal cgst = 0;
                    Decimal totalTax = 0;
                    Decimal total = 0;
                    Decimal roundedValue = 0;
                    Boolean agMilestone = false;
                    
                    Payment_Milestone__c pm = new Payment_Milestone__c();
                    pm.Milestone_Name__c = psm.Milestone_Name__c;
                    pm.Milestone_Type__c = psm.Milestone_Type__c;
                    pm.Number_of_Days__c = psm.Number_of_Days__c;
                    pm.Construction_Stage__c = psm.Construction_Stage__c;
                    pm.Deduct_Token__c = psm.Deduct_Token__c;
                    pm.Sequence_Number__c = psm.Sequence_Number__c;
                    pm.Is_Possession_Milestone__c = psm.Is_Possession_Milestone__c;
                    
                    if(String.isNotBlank(psm.Milestone_Type__c) && psm.Milestone_Type__c.equals('Date Linked')) {
                        if(psm.Number_of_Days__c != null) {
                            pm.Due_Date__c = System.today().addDays(Integer.valueOf(psm.Number_of_Days__c));
                        }
                        
                    } else if(String.isNotBlank(psm.Milestone_Type__c) && psm.Milestone_Type__c.equals('Construction Linked')) {
                        Date completionDate = null;
                        Boolean IsMilestoneAchieved = false;
                        Construction_Stage__c cStage = cStageMap.get(psm.Construction_Stage__c);
                        
                        if(cStage.Actual_Completion_Date__c != null && cStage.Actual_Completion_Date__c > System.today()) {
                            completionDate = cStage.Actual_Completion_Date__c;
                        } else if(cStage.Actual_Completion_Date__c != null && cStage.Actual_Completion_Date__c <= System.today()) {
                            completionDate = system.today().addDays(60);
                            IsMilestoneAchieved = True;
                        } else if(cStage.Expected_Completion_Date__c != null && cStage.Expected_Completion_Date__c > System.today()) {
                            completionDate = cStage.Expected_Completion_Date__c;
                        } else if(cStage.Expected_Completion_Date__c != null && cStage.Expected_Completion_Date__c <= System.today()) {
                            completionDate = system.today();
                        }   
                        if(completionDate == null) {
                            completionDate = system.today().addDays(365);
                        }
                        pm.Due_Date__c = completionDate.addDays(Integer.valueOf(psm.Number_of_Days__c));
                        
                        if(IsMilestoneAchieved) {
                            pm.Milestone_Complete_At_Booking__c = true;
                        } else {
                            pm.Milestone_Complete_At_Booking__c = false;
                        }
                    } else if(String.isNotBlank(psm.Milestone_Type__c) && psm.Milestone_Type__c.equals('Registration Linked')) {
                        //10% of Agreement Value is collected within 30 days.
                        //Hence setting the dates for registration demand as 60th day
                        pm.Due_Date__c = system.today().addDays(60);
                    }
                    
                    for(Integer i = 1; i <= 5; i++) {
                        if(String.isNotBlank((String)psm.get('Charge_Bucket_'+i+'__c'))) { 
                            pm.put('Charge_Bucket_'+i+'__c', psm.get('Charge_Bucket_'+i+'__c'));
                            
                            if(((String)psm.get('Charge_Bucket_'+i+'__c')).equalsIgnoreCase('Agreement Value')) {
                                //Calculation for agreement value bucket
                                if(((String)psm.get('Charge_Bucket_'+i+'_Type__c')).equalsIgnoreCase('Percentage') && psm.get('Charge_Bucket_'+i+'_Percentage__c') != null && psm.get('Charge_Bucket_'+i+'_Percentage__c') != 0) {
                                    // getModifiedAV amount = (((Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c') * allPriceInfoMap.get('Agreement Value')) / 100).setscale(0,RoundingMode.HALF_UP);
                                    system.debug('getModifiedAV:'+getModifiedAV);
                                    system.debug('percentage:'+(((Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c'))));
                                    amount = (((Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c') * getModifiedAV) / 100).setscale(0,RoundingMode.CEILING);
                                    system.debug('amount:'+amount);
                                    
                                    percentage = (Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c');
                                } else {
                                    amount = ((Decimal)psm.get('Charge_Bucket_'+i+'_Amount__c')).setscale(0,RoundingMode.CEILING);
                                    percentage = (((Decimal)psm.get('Charge_Bucket_'+i+'_Amount__c') / getModifiedAV) * 100).setscale(2,RoundingMode.HALF_UP);
                                    // percentage = (((Decimal)psm.get('Charge_Bucket_'+i+'_Amount__c') / allPriceInfoMap.get('Agreement Value')) * 100).setscale(2,RoundingMode.HALF_UP);
                                }
                                if(psm.Token_Amount__c != null && psm.Token_Amount__c != 0) {
                                    tokenAmount = psm.Token_Amount__c;
                                }
                                if(psm.Deduct_Token__c && tokenAmount != 0) {
                                    amount = amount - tokenAmount;
                                    percentage = ((amount / getModifiedAV) * 100).setscale(2,RoundingMode.HALF_UP);
                                    // percentage = ((amount / allPriceInfoMap.get('Agreement Value')) * 100).setscale(2,RoundingMode.HALF_UP);
                                    psm.put('Charge_Bucket_'+i+'_Type__c', 'Amount');
                                }
                                if(getModifiedAV < u.Threshold_Amount__c) {
                                    sgst =  (((amount / 100) * u.Threshold_Percentage__c) / 2);//.setscale(0,RoundingMode.HALF_UP);
                                    cgst =  (((amount / 100) * u.Threshold_Percentage__c) / 2);//.setscale(0,RoundingMode.HALF_UP);
                                } else {
                                    if(getModifiedAV != null) {
                                        sgst = (((amount / 100) * u.Tower__r.GST_Percentage__c) / 2);//.setscale(0,RoundingMode.HALF_UP);
                                        cgst = (((amount / 100) * u.Tower__r.GST_Percentage__c) / 2);//.setscale(0,RoundingMode.HALF_UP);
                                    }
                                }                             
                                agMilestone = true;
                                Decimal totalTax1 = 0;
                                totalTax1 = (sgst + cgst);
                                System.debug('totalTax1: '+totalTax1);
                                Integer integerPart = totalTax1.intValue();
                                System.debug('integerPart: '+integerPart);
                                Decimal decimalPart = totalTax1 - integerPart;
                                System.debug('decimalPart: '+decimalPart);
                                if (decimalPart >= 0.49) {
                                    roundedValue = integerPart + 1;
                                } else {
                                    roundedValue = integerPart;
                                }
                                totalTax = roundedValue;
                                total = amount + totalTax;
                                grandAmount += amount;
                                grandPercentage += percentage;
                                grandSGST += sgst;
                                grandCGST += cgst;
                                grandTotalTax += totalTax;
                                grandTotal += total;
                                //grandTotalTax2 = grandTotalTax;
                                
                                pm.put('Charge_Bucket_'+i+'_Amount__c', amount);
                                pm.put('Charge_Bucket_'+i+'_Percentage__c', percentage);
                                pm.put('Charge_Bucket_'+i+'_SGST__c', sgst);
                                pm.put('Charge_Bucket_'+i+'_CGST__c', cgst);
                                pm.put('Charge_Bucket_'+i+'_Total_Tax__c', totalTax);
                                system.debug('totalTax:'+ pm.put('Charge_Bucket_'+i+'_Total_Tax__c', totalTax));
                            } else {
                                //Calculation for other than agreement value bucket
                                Decimal amountOther = 0;
                                Decimal sgstOther = 0;
                                Decimal cgstOther = 0;
                                Decimal totalTaxOther = 0;
                                
                                pm.put('Charge_Bucket_'+i+'_Percentage__c', (Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c'));
                                if(!Test.isRunningTest())
                                    //     amountOther = (((Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c') * allPriceInfoMap.get((String)psm.get('Charge_Bucket_'+i+'__c'))) / 100);
                                    // pm.put('Charge_Bucket_'+i+'_Amount__c', amountOther);
                                    
                                    /* if(allPriceInfoMap.get((String)psm.get('Charge_Bucket_'+i+'__c')+' TAX') != null && allPriceInfoMap.get((String)psm.get('Charge_Bucket_'+i+'__c')+' TAX') != 0) {
sgstOther = ((allPriceInfoMap.get((String)psm.get('Charge_Bucket_'+i+'__c')+' TAX') / 100) * (Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c')).setscale(0,RoundingMode.HALF_UP);
cgstOther = ((allPriceInfoMap.get((String)psm.get('Charge_Bucket_'+i+'__c')+' TAX') / 100) * (Decimal)psm.get('Charge_Bucket_'+i+'_Percentage__c')).setscale(0,RoundingMode.HALF_UP);
}*/
                                    totalTaxOther = sgstOther + cgstOther;
                                pm.put('Charge_Bucket_'+i+'_SGST__c', sgstOther);
                                pm.put('Charge_Bucket_'+i+'_CGST__c', cgstOther);
                                pm.put('Charge_Bucket_'+i+'_Total_Tax__c', totalTaxOther);
                            }
                        }
                    }
                    if(pm.Milestone_Complete_At_Booking__c && psm.Payment_Scheme__r.Is_Mergeable__c) {
                        if(paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.Milestone_Complete_At_Booking__c) {
                            for(Integer i = 1; i <= 5; i++) {
                                if(String.isNotBlank((String)pm.get('Charge_Bucket_'+i+'__c'))) {
                                    
                                    if(((String)pm.get('Charge_Bucket_'+i+'__c')).equalsIgnoreCase('Agreement Value')) {
                                        pm.put('Charge_Bucket_'+i+'_Amount__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_Amount__c') + amount));
                                        pm.put('Charge_Bucket_'+i+'_Percentage__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_Percentage__c') + percentage));
                                        pm.put('Charge_Bucket_'+i+'_SGST__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_SGST__c') + sgst));
                                        pm.put('Charge_Bucket_'+i+'_CGST__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_CGST__c') + cgst));
                                        pm.put('Charge_Bucket_'+i+'_Total_Tax__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_Total_Tax__c') + totalTax));
                                    } else {
                                        pm.put('Charge_Bucket_'+i+'_Amount__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_Amount__c') + (Decimal)pm.get('Charge_Bucket_'+i+'_Amount__c')));
                                        pm.put('Charge_Bucket_'+i+'_Percentage__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_Percentage__c') + (Decimal)pm.get('Charge_Bucket_'+i+'_Percentage__c')));
                                        pm.put('Charge_Bucket_'+i+'_SGST__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_SGST__c') + (Decimal)pm.get('Charge_Bucket_'+i+'_SGST__c')));
                                        pm.put('Charge_Bucket_'+i+'_CGST__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_CGST__c') + (Decimal)pm.get('Charge_Bucket_'+i+'_CGST__c')));
                                        pm.put('Charge_Bucket_'+i+'_Total_Tax__c', ((Decimal)paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].pm.get('Charge_Bucket_'+i+'_Total_Tax__c') + (Decimal)pm.get('Charge_Bucket_'+i+'_Total_Tax__c')));
                                    }
                                }
                            }
                            Decimal totalMergePercentage = (paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].percentage + percentage);
                            Decimal totalMergeAmount = (paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].amount + amount);
                            Decimal totalMergeTax = (paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].tax + totalTax);
                            Decimal totalMergeTotal = (paymentMilestoneWrapperList[paymentMilestoneWrapperList.size()-1].total + total); 
                            
                            paymentMilestoneWrapperList.remove(paymentMilestoneWrapperList.size()-1);
                            paymentMilestoneWrapperList.add(new PaymentMilestoneWrapper(psm, pm, cStageList, pm.Milestone_Name__c, totalMergePercentage, totalMergeAmount, currencyFormat(totalMergeAmount), totalMergeTax, currencyFormat(totalMergeTax), totalMergeTotal, currencyFormat(totalMergeTotal), false, agMilestone, pm.Milestone_Complete_At_Booking__c));
                        } else {
                            paymentMilestoneWrapperList.add(new PaymentMilestoneWrapper(psm, pm, cStageList, pm.Milestone_Name__c, percentage, amount, currencyFormat(amount), totalTax, currencyFormat(totalTax), total, currencyFormat(total), false, agMilestone, pm.Milestone_Complete_At_Booking__c));
                        }
                    } else {
                        paymentMilestoneWrapperList.add(new PaymentMilestoneWrapper(psm, pm, cStageList, pm.Milestone_Name__c, percentage, amount, currencyFormat(amount), totalTax, currencyFormat(totalTax), total, currencyFormat(total), false, agMilestone, pm.Milestone_Complete_At_Booking__c));
                    }
                }
                paymentMilestoneWrapperList.add(new PaymentMilestoneWrapper(null, null, null, 'Total', grandPercentage, grandAmount, currencyFormat(grandAmount), grandTotalTax, currencyFormat(grandTotalTax), grandTotal, currencyFormat(grandTotal), true, true, false));
            }
        }
        
        // Update the last and second-to-last row elements in the list
        if (paymentMilestoneWrapperList != null && !paymentMilestoneWrapperList.isEmpty()) {
            // Retrieve the last element in the list
            PaymentMilestoneWrapper lastRowElement = paymentMilestoneWrapperList[paymentMilestoneWrapperList.size() - 1];
            // Retrieve the second-to-last element in the list
            PaymentMilestoneWrapper secondToLastElement = paymentMilestoneWrapperList[paymentMilestoneWrapperList.size() - 2];
            
            // Calculate differences for the last row
            Decimal amountDiffLatest = 0;
            amountDiffLatest = getModifiedAV - lastRowElement.amount;
            // allPriceInfoMap.get('Agreement Value') - lastRowElement.amount;
            Decimal taxDiffLatest = 0;
            System.debug('grandTotalTax: '+getModifiedGstAmount);
            if(getModifiedGstAmount !=null)
                taxDiffLatest = getModifiedGstAmount - lastRowElement.tax;
            System.debug('taxDiffLatest:'+taxDiffLatest);
            
            
            //allPriceInfoMap.get('Agreement Value TAX') - lastRowElement.tax;
            
            // Update the last row element
            if (amountDiffLatest != 0) {
                lastRowElement.amount = lastRowElement.amount + amountDiffLatest;
                lastRowElement.amountString = currencyFormat(lastRowElement.amount);
                system.debug('Grand Total Updated Amount: ' + lastRowElement.amountString);
                secondToLastElement.amount = secondToLastElement.amount + amountDiffLatest;
                secondToLastElement.amountString = currencyFormat(secondToLastElement.amount);
                system.debug('Last Milestone Updated Amount: ' + secondToLastElement.amountString);
                
                for(Integer i = 1; i <= 5; i++) {
                    if(String.isNotBlank((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c'))) {
                        if(((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c')).equalsIgnoreCase('Agreement Value')) {
                            secondToLastElement.pm.put('Charge_Bucket_'+i+'_Amount__c', ((Decimal)secondToLastElement.pm.get('Charge_Bucket_'+i+'_Amount__c') + amountDiffLatest));
                        }
                    }
                }
            }
            
            if (taxDiffLatest != 0) {
                lastRowElement.tax = lastRowElement.tax + taxDiffLatest;
                lastRowElement.taxString = currencyFormat(lastRowElement.tax);
                system.debug('Grand Total Updated Tax: ' + lastRowElement.taxString);
                
                secondToLastElement.tax = secondToLastElement.tax;
                secondToLastElement.taxString = currencyFormat(secondToLastElement.tax);
                system.debug('Last Milestone Updated Tax: ' + secondToLastElement.taxString);
                
                for(Integer i = 1; i <= 5; i++) {
                    if(String.isNotBlank((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c'))) {
                        if(((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c')).equalsIgnoreCase('Agreement Value')) {
                            secondToLastElement.pm.put('Charge_Bucket_'+i+'_Total_Tax__c', ((Decimal)secondToLastElement.pm.get('Charge_Bucket_'+i+'_Total_Tax__c')));
                        }
                    }
                }
            }
            
            if (lastRowElement.amount != null && lastRowElement.tax != null) {
                lastRowElement.Total = lastRowElement.amount + lastRowElement.tax;
                lastRowElement.totalString = currencyFormat(lastRowElement.Total);
                
                
                secondToLastElement.Total = secondToLastElement.amount + secondToLastElement.tax;
                secondToLastElement.totalString = currencyFormat(secondToLastElement.Total);
                
            }
        }
        system.debug('paymentMilestoneWrapperList: '+paymentMilestoneWrapperList);
        return paymentMilestoneWrapperList;
    }
    
    public static List<String> validateUpdatedPaymentSchedule(Integer agSeqNumber, Decimal getModifiedAv, List<PaymentMilestoneWrapper> updatedPaymentMilestoneWrapperList) {
        List<String> validationErrorList = new List<String>();
        
        Map<String, Decimal> allPriceInfoMap = new Map<String, Decimal>();
        if(getModifiedAv == null){
            getModifiedAv = 0;
        }else{
            allPriceInfoMap.put('Agreement Value', getModifiedAv);   
        }
        System.debug('allPriceInfoMapValidate: '+allPriceInfoMap);
        if(!updatedPaymentMilestoneWrapperList.isEmpty() && updatedPaymentMilestoneWrapperList != null) {
            Decimal totalAmount = 0;
            Decimal totalPercentage = 0;
            Integer errorCount = 0;
            
            for(PaymentMilestoneWrapper pmw: updatedPaymentMilestoneWrapperList) {
                if(pmw.agMilestone && pmw.pm != null && pmw.psm != null) {
                    if(((String)pmw.psm.get('Charge_Bucket_'+agSeqNumber+'_Type__c')).equalsIgnoreCase('Percentage')) {
                        totalAmount += (((Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Percentage__c') * allPriceInfoMap.get('Agreement Value')) / 100); //.setscale(0,RoundingMode.HALF_UP);
                        totalPercentage += (Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Percentage__c');
                    } else if(((String)pmw.psm.get('Charge_Bucket_'+agSeqNumber+'_Type__c')).equalsIgnoreCase('Amount')) {
                        totalAmount += (Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Amount__c');
                        totalPercentage +=  ((Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Amount__c') / allPriceInfoMap.get('Agreement Value') * 100); //.setscale(2,RoundingMode.HALF_UP);
                    }
                    system.debug('totalAmount: '+totalAmount);
                    system.debug('totalPercentage: '+totalPercentage);
                }
            }
            
            system.debug('Milestone Total Amount: '+totalAmount);
            system.debug('Agreement Value: '+allPriceInfoMap.get('Agreement Value'));
            
            if(validationErrorList.isEmpty()) {
                if(Math.abs(totalAmount - allPriceInfoMap.get('Agreement Value')) >= 1) {
                    if(totalAmount > allPriceInfoMap.get('Agreement Value')) {
                        errorCount++;
                        validationErrorList.add('Error '+errorCount+': There is an excess of ₹ '+currencyFormat(Math.abs(totalAmount - allPriceInfoMap.get('Agreement Value'))));
                        errorCount++;
                        validationErrorList.add('Error '+errorCount+': Percentages add up to: '+totalPercentage);
                    } else {
                        errorCount++;
                        validationErrorList.add('Error '+errorCount+': There is an shortfall of ₹ '+currencyFormat(Math.abs(totalAmount - allPriceInfoMap.get('Agreement Value'))));
                        errorCount++;
                        validationErrorList.add('Error '+errorCount+': Percentages add up to: '+totalPercentage);
                    }
                }
            }
        }
        return validationErrorList;
    }
    
    public static List<PaymentMilestoneWrapper> getUpdatedPaymentSchedule(Unit__c u, Integer agSeqNumber, Decimal getModifiedAV, List<PaymentMilestoneWrapper> updatedPaymentMilestoneWrapperList, Decimal gstAmount, Decimal gstPer) {
        System.debug('getModifiedAV: '+getModifiedAV);
        System.debug('gstAmount: '+gstAmount);
        System.debug('gstPer: '+gstPer);
        
        List<PaymentMilestoneWrapper> paymentMilestoneWrapperList = new List<PaymentMilestoneWrapper>();
        System.debug('gstAmount: '+gstAmount);
        Map<String, Decimal> allPriceInfoMap = new Map<String, Decimal>();
        allPriceInfoMap.put('Agreement Value',getModifiedAv);
        allPriceInfoMap.put('Agreement Value TAX',gstAmount);
        
        System.debug('allPriceInfoMapValidate: '+allPriceInfoMap);
        
        if(u != null) {
            Map<Id, Construction_Stage__c> cStageMap = getConstructionStagesMap(u.Project__c, u.Tower__c);
            if(!updatedPaymentMilestoneWrapperList.isEmpty() && updatedPaymentMilestoneWrapperList != null) {
                Integer count = 0;
                Decimal tokenAmount = 0;
                Decimal grandAmount = 0;
                Decimal grandPercentage = 0;
                Decimal grandSGST = 0;
                Decimal grandCGST = 0;
                Decimal grandTotalTax = 0;
                Decimal grandTotal = 0;
                updatedPaymentMilestoneWrapperList.remove(updatedPaymentMilestoneWrapperList.size()-1);
                
                for(PaymentMilestoneWrapper pmw: updatedPaymentMilestoneWrapperList) {
                    Decimal amount = 0;
                    Decimal percentage = 0;
                    Decimal sgst = 0;
                    Decimal cgst = 0;
                    Decimal totalTax = 0;
                    Decimal roundedValue = 0;
                    Decimal total = 0;
                    Boolean agMilestone = false;
                    
                    if(pmw.agMilestone && pmw.pm != null && pmw.psm != null) {
                        if(((String)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'__c')).equalsIgnoreCase('Agreement Value')) {
                            if(((String)pmw.psm.get('Charge_Bucket_'+agSeqNumber+'_Type__c')).equalsIgnoreCase('Percentage')) {
                                amount = (((Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Percentage__c') * allPriceInfoMap.get('Agreement Value')) / 100).setscale(0,RoundingMode.CEILING);
                               system.debug('Amount:'+amount);
                                percentage = ((Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Percentage__c')).setscale(2,RoundingMode.HALF_UP);
                            } else {
                                amount = ((Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Amount__c')).setscale(0,RoundingMode.CEILING);
                                percentage = (((Decimal)pmw.pm.get('Charge_Bucket_'+agSeqNumber+'_Amount__c') / allPriceInfoMap.get('Agreement Value')) * 100).setscale(2,RoundingMode.HALF_UP);
                            }
                            if(count == 0) {
                                tokenAmount = 0;
                            }
                            if(pmw.psm.Deduct_Token__c && tokenAmount > 0) {
                                amount = amount - tokenAmount;
                                percentage = ((amount / allPriceInfoMap.get('Agreement Value')) * 100).setscale(2,RoundingMode.HALF_UP);
                            }
                            if(gstPer != null && gstPer > 0){
                                //priority to gst put on quotation
                                sgst = (((amount / 100) * gstPer) / 2);
                                cgst = (((amount / 100) * gstPer) / 2);
                            } 
                            else if(allPriceInfoMap.get('Agreement Value') < u.Threshold_Amount__c) {
                               
                            }
                            System.debug('total: '+total);
                            agMilestone = true;
                            Decimal totalTax1 = 0;
                            totalTax1 = (sgst + cgst);
                            System.debug('totalTax1: '+totalTax1);
                            Integer integerPart = totalTax1.intValue();
                            System.debug('integerPart: '+integerPart);
                            Decimal decimalPart = totalTax1 - integerPart;
                            System.debug('decimalPart: '+decimalPart);
                            if (decimalPart >= 0.50) {
                                roundedValue = integerPart + 1;
                            } else {
                                roundedValue = integerPart;
                            }
                            totalTax = roundedValue;
                            System.debug('Rounded value: ' + roundedValue);
                            total = amount + totalTax;
                            System.debug('total: '+total);
                            grandAmount += amount;
                            System.debug('grandAmount: '+grandAmount);
                            grandPercentage += percentage;
                            grandSGST += sgst;
                            grandCGST += cgst;
                            grandTotalTax += totalTax;
                            System.debug('grandTotalTax: '+grandTotalTax);                            
                            grandTotal += total;
                            System.debug('grandTotal: '+grandTotal);  
                            
                            pmw.pm.put('Charge_Bucket_'+agSeqNumber+'_Amount__c', amount);
                            pmw.pm.put('Charge_Bucket_'+agSeqNumber+'_Percentage__c', percentage);
                            pmw.pm.put('Charge_Bucket_'+agSeqNumber+'_SGST__c', sgst);
                            pmw.pm.put('Charge_Bucket_'+agSeqNumber+'_CGST__c', cgst);
                            pmw.pm.put('Charge_Bucket_'+agSeqNumber+'_Total_Tax__c', totalTax);
                            system.debug('totalTax:'+ pmw.pm.put('Charge_Bucket_'+agSeqNumber+'_Total_Tax__c', totalTax));
                            
                            if(String.isNotBlank(pmw.pm.Milestone_Type__c) && pmw.pm.Milestone_Type__c.equals('Date Linked')) {
                                if(pmw.pm.Number_of_Days__c != null) {
                                    pmw.pm.Due_Date__c = System.today().addDays(Integer.valueOf(pmw.pm.Number_of_Days__c));
                                }
                                
                            } else if(String.isNotBlank(pmw.pm.Milestone_Type__c) && pmw.pm.Milestone_Type__c.equals('Construction Linked')) {
                                Date completionDate = null;
                                Boolean IsMilestoneAchieved = false;
                                Construction_Stage__c cStage = cStageMap.get(pmw.pm.Construction_Stage__c);
                                
                                if(cStage.Actual_Completion_Date__c != null && cStage.Actual_Completion_Date__c > System.today()) {
                                    completionDate = cStage.Actual_Completion_Date__c;
                                } else if(cStage.Actual_Completion_Date__c != null && cStage.Actual_Completion_Date__c <= System.today()) {
                                    completionDate = system.today().addDays(60);
                                    IsMilestoneAchieved = True;
                                } else if(cStage.Expected_Completion_Date__c != null && cStage.Expected_Completion_Date__c > System.today()) {
                                    completionDate = cStage.Expected_Completion_Date__c;
                                } else if(cStage.Expected_Completion_Date__c != null && cStage.Expected_Completion_Date__c <= System.today()) {
                                    completionDate = system.today();
                                }   
                                if(completionDate == null) {
                                    completionDate = system.today().addDays(365);
                                }
                                pmw.pm.Due_Date__c = completionDate.addDays(Integer.valueOf(pmw.pm.Number_of_Days__c));
                                
                                if(IsMilestoneAchieved) {
                                    pmw.pm.Milestone_Complete_At_Booking__c = true;
                                } else {
                                    pmw.pm.Milestone_Complete_At_Booking__c = false;
                                }
                            } else if(String.isNotBlank(pmw.pm.Milestone_Type__c) && pmw.pm.Milestone_Type__c.equals('Registration Linked')) {
                                //10% of Agreement Value is collected within 30 days.
                                //Hence setting the dates for registration demand as 60th day
                                pmw.pm.Due_Date__c = system.today().addDays(60);
                            }
                        }
                    }
                    paymentMilestoneWrapperList.add(new PaymentMilestoneWrapper(pmw.psm, pmw.pm, pmw.constructionStageList, pmw.pm.Milestone_Name__c, percentage, amount, currencyFormat(amount), totalTax, currencyFormat(totalTax), total, currencyFormat(total), false, agMilestone, pmw.pm.Milestone_Complete_At_Booking__c));
                    count++;
                }
                paymentMilestoneWrapperList.add(new PaymentMilestoneWrapper(null, null, null, 'Total', grandPercentage, grandAmount, currencyFormat(grandAmount), grandTotalTax, currencyFormat(grandTotalTax), grandTotal, currencyFormat(grandTotal), true, true, false));
            }
        }
        
        // Update the last and second-to-last row elements in the list
        if (allPriceInfoMap != null & paymentMilestoneWrapperList != null && !paymentMilestoneWrapperList.isEmpty()) {
            // Retrieve the last element in the list
            PaymentMilestoneWrapper lastRowElement = paymentMilestoneWrapperList[paymentMilestoneWrapperList.size() - 1];
            system.debug('secondToLastElement: ' + lastRowElement);
            // Retrieve the second-to-last element in the list
            PaymentMilestoneWrapper secondToLastElement = paymentMilestoneWrapperList[paymentMilestoneWrapperList.size() - 2];
            system.debug('secondToLastElement: ' + secondToLastElement);
            // Calculate differences for the last row
            Decimal amountDiffLatest = allPriceInfoMap.get('Agreement Value') - lastRowElement.amount;
            Decimal taxDiffLatest = allPriceInfoMap.get('Agreement Value TAX') - lastRowElement.tax;
            system.debug('Agreement Value: ' + allPriceInfoMap.get('Agreement Value'));
            system.debug('lastRowElement.amount: ' + lastRowElement.amount);
            system.debug('amountDiffLatest: ' + amountDiffLatest);
            system.debug('taxDiffLatest: ' + taxDiffLatest);
            
            // Update the last row element
            if (amountDiffLatest != 0) {
                lastRowElement.amount = lastRowElement.amount + amountDiffLatest;
                lastRowElement.amountString = currencyFormat(lastRowElement.amount);
                system.debug('Grand Total Updated Amount: ' + lastRowElement.amountString);
                
                
                secondToLastElement.amount = secondToLastElement.amount + amountDiffLatest;
                secondToLastElement.amountString = currencyFormat(secondToLastElement.amount);
                system.debug('Last Milestone Updated Amount: ' + secondToLastElement.amountString);
                
                for(Integer i = 1; i <= 5; i++) {
                    if(String.isNotBlank((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c'))) {
                        if(((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c')).equalsIgnoreCase('Agreement Value')) {
                            secondToLastElement.pm.put('Charge_Bucket_'+i+'_Amount__c', ((Decimal)secondToLastElement.pm.get('Charge_Bucket_'+i+'_Amount__c') + amountDiffLatest));
                        }
                    }
                }
            }
            
            if (taxDiffLatest != 0) {
                lastRowElement.tax = lastRowElement.tax + taxDiffLatest;
                lastRowElement.taxString = currencyFormat(lastRowElement.tax);
                system.debug('Grand Total Updated Tax: ' + lastRowElement.taxString);
                system.debug('secondToLastElement Tax: ' + secondToLastElement.tax);
                 system.debug('tax diff : ' + taxDiffLatest);
                 system.debug('secondToLastElement Tax diff : ' + (secondToLastElement.tax - taxDiffLatest));
                secondToLastElement.tax = secondToLastElement.tax;
                secondToLastElement.taxString = currencyFormat(secondToLastElement.tax);
                system.debug('Last Milestone Updated Tax: ' + secondToLastElement.taxString);
                
                for(Integer i = 1; i <= 5; i++) {
                    if(String.isNotBlank((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c'))) {
                        if(((String)secondToLastElement.pm.get('Charge_Bucket_'+i+'__c')).equalsIgnoreCase('Agreement Value')) {
                            secondToLastElement.pm.put('Charge_Bucket_'+i+'_Total_Tax__c', ((Decimal)secondToLastElement.pm.get('Charge_Bucket_'+i+'_Total_Tax__c')));
                        }
                    }
                }
            }
            
            if (lastRowElement.amount != null) {
                lastRowElement.Total = lastRowElement.amount + lastRowElement.tax;
                lastRowElement.totalString = currencyFormat(lastRowElement.Total);
                System.debug('lastRowElement.Total: '+lastRowElement.Total);
                System.debug('lastRowElement.totalString: '+lastRowElement.totalString);
                
                secondToLastElement.Total = secondToLastElement.amount + secondToLastElement.tax;
                secondToLastElement.totalString = currencyFormat(secondToLastElement.Total);
            }
        }
        system.debug('paymentMilestoneWrapperList: '+paymentMilestoneWrapperList);
        return paymentMilestoneWrapperList;
    }
    
    
    
    public class PaymentMilestoneWrapper {
        @AuraEnabled
        public Payment_Scheme_Milestone__c psm {get;set;}
        @AuraEnabled
        public Payment_Milestone__c pm {get;set;}
        @AuraEnabled
        public List<Construction_Stage__c> constructionStageList {get;set;}
        @AuraEnabled
        public String milestoneName {get;set;}
        @AuraEnabled
        public Decimal percentage {get;set;}
        @AuraEnabled
        public String percentageString {get;set;}
        @AuraEnabled
        public Decimal amount {get;set;}
        @AuraEnabled
        public String amountString {get;set;}
        @AuraEnabled
        public Decimal tax {get;set;}
        @AuraEnabled
        public String taxString {get;set;}
        @AuraEnabled
        public Decimal total {get;set;}
        @AuraEnabled
        public String totalString {get;set;}
        @AuraEnabled
        public Boolean isTotal {get;set;}
        @AuraEnabled
        public Boolean agMilestone {get;set;}
        @AuraEnabled
        public String completedMilestone {get;set;}
        public PaymentMilestoneWrapper(){}
        public PaymentMilestoneWrapper(Payment_Scheme_Milestone__c psm, Payment_Milestone__c pm, List<Construction_Stage__c> csList, String milestoneName, Decimal percentage, Decimal amount, String amountString, Decimal tax, String taxString, Decimal total, String totalString, Boolean isTotal, Boolean agMilestone, Boolean completedMilestone) {
            this.psm = psm;
            this.pm = pm;
            this.constructionStageList = csList;
            this.milestoneName = milestoneName;
            this.percentage = percentage;
            this.percentageString = String.valueOf(percentage)+'%';
            this.amount = amount;
            this.amountString = amountString;
            this.tax = tax;
            this.taxString = taxString;
            this.total = total;
            this.totalString = totalString;
            this.isTotal = isTotal;
            this.agMilestone = agMilestone;
            if(completedMilestone)
                this.completedMilestone = 'background-color:#D7BF5E';
        }
    }
    
    public class CarParkWrapper {
        @AuraEnabled
        public String carParkType {get;set;}
        @AuraEnabled
        public Decimal carParkAvailableCount {get;set;}
        @AuraEnabled
        public Decimal carParkAmount {get;set;}
        @AuraEnabled
        public Decimal carParkRequiredCount {get;set;}
        @AuraEnabled
        public String carParkAmountString {get;set;}
        public CarParkWrapper(){}
        public CarParkWrapper(String cpType, Decimal cpAvailableCount, Decimal cpAmount, Decimal cpRequiredCount, String cpAmountString) {
            this.carParkType = cpType;
            this.carParkAvailableCount = cpAvailableCount;
            this.carParkAmount = cpAmount;
            this.carParkRequiredCount = cpRequiredCount;
            this.carParkAmountString = cpAmountString;
        }
    }
    
    @AuraEnabled
    public static String currencyFormat(Decimal amt) {
        String formattedAmount = '';
        System.debug('amt: '+amt);
        if(amt != null && amt >= 0){
            
            
            Decimal tempAmt = amt.setscale(2,RoundingMode.HALF_UP);
            String stringAmt = tempAmt.toPlainString();
            String decimalPart;
            List<String> tempStr = new List<String>();
            if(String.isNotBlank(stringAmt)) {
                tempStr = stringAmt.split('\\.');
                if(tempStr != null && tempStr.size() ==2) {
                    decimalPart = tempStr[1];
                }
            }
            formattedAmount = (tempAmt.format().contains('.')?tempAmt.format():(tempAmt.format()+'.'+decimalPart));
        }
        return formattedAmount+ '/-';
    }
    
}