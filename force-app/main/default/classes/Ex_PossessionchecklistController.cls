global without sharing class Ex_PossessionchecklistController {
    
    @AuraEnabled(cacheable = false)
    global static List<Master_Possession__c> getMasterPossession(Id bkId, Boolean isCRMManager, Boolean isAccManager, Boolean isCustomer) {
        List<Master_Possession__c> crmList = new List<Master_Possession__c>();
        List<Master_Possession__c> accList = new List<Master_Possession__c>();
        List<Master_Possession__c> customerList = new List<Master_Possession__c>();
        System.debug('isCRMManager: ' + isCRMManager);
        System.debug('isAccManager: ' + isAccManager);
        System.debug('isCustomer: ' + isCustomer);
        
        try {
            if (bkId != null) {
                Booking__c b = [SELECT Id, Name, Tower__c FROM Booking__c WHERE Id = :bkId];
                
                List<Master_Possession__c> mpList = [
                    SELECT Id, Sr_Number__c, Particulars__c, Tower__c, Section__c, Section_Number__c
                    FROM Master_Possession__c 
                    WHERE Tower__c = :b.Tower__c
                    ORDER BY Section_Number__c ASC, Sr_Number__c ASC
                ];
                
                for (Master_Possession__c mp : mpList) {
                    if (isCRMManager) {
                        crmList.add(mp);
                    } else if (isAccManager) {
                        accList.add(mp);
                    } else if (isCustomer) {
                        customerList.add(mp);
                    }
                }
                System.debug('CRM List: ' + crmList);
                System.debug('Account List: ' + accList);
                System.debug('Customer List: ' + customerList);
            }
        } catch (Exception e) {
            System.debug('Error in getMasterPossession: ' + e.getMessage());
        }
        List<Master_Possession__c> finalList = new List<Master_Possession__c>();
        finalList.addAll(crmList);
        finalList.addAll(accList);
        finalList.addAll(customerList);
        return finalList;
    }
    
    
    // Returns Specified Booking Details along with Current User Details
    @AuraEnabled(cacheable = true)
    global static Map<String, Object> getBookingDetails(Id bkId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        User u = [SELECT Id, Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        boolean isCRMManager = false;    
        boolean isAccManager = false;
        boolean isCRMHead = false;
        
        Booking__c b = [
            SELECT Id, Name/*,Total_Amount_Demanded__c,Total_Interest_Amount__c,
            Total_Amount_Paid_Against_Demand__c ,Total_Tax_Demanded__c,Total_Tax_Paid__c*/,Account_Possession_Checklist__c,
            Tower__r.Customer_Relationship_Manager__c, CRM_Possession_Checklist__c, Tower__c,Customer_Possession_Checklist__c,
            Project__r.CRM_Head__c, /*,Project__r.Sales_Head__c,*/Tower__r.Name, Booking_Date__c, Opportunity__r.Name, Registration_Status__c,
            Unit__r.Name, Tower__r.Finance_Manager__c, Project__c, Primary_Applicant_Address__c, Possession_Approved_By_CRM_Head__c
            FROM Booking__c
            WHERE Id = :bkId
            LIMIT 1
        ];
        
        List<Registration__c> regList = [SELECT Id , Name , Booking__c,SDR_Amount__c FROM Registration__c WHERE Booking__c = :bkId];
        Registration__c r;
        if (!regList.isEmpty()) {
            r = regList[0];
        }
        
        isAccManager = isAccountsManager(b.Tower__c);
        isCRMManager = isCRMManager(b.Id);
        isCRMHead = isCRMHead(b.Project__c);
        
        System.debug('User: ' + u);
        System.debug('Booking: ' + b);
        System.debug('isCRMManager: ' + isCRMManager);
        System.debug('r: ' + r);
        
        if (r != null) {
            resultMap.put('registration', r);
        } else {
            resultMap.put('registration', null);
        }
        resultMap.put('booking', b);
        resultMap.put('isCRMManager', isCRMManager);
        resultMap.put('isAccManager', isAccManager);
        resultMap.put('isCRMHead', isCRMHead);
        return resultMap;
    }
    
    
    // Returns the Possession Checklist for specified booking
    @AuraEnabled(cacheable = false)
    global static List<Possession_checklist__c> getPossessionChecklist(Id bkId) {
        List<Possession_checklist__c> pcList = [SELECT Id, Name, Accounts_Clearance__c,Remarks__c,Particulars__c,Section__c, Received__c, 
                                                Booking__c, CRM_Status__c,FM_Status__c,Customer_Status__c
                                                FROM Possession_checklist__c 
                                                WHERE Booking__c = :bkId AND Particulars__c != null Order By Name];
        return pcList;
    }
    
     @AuraEnabled(cacheable=true)
    public static Boolean checkIfGuestUser(String siteURL, Id bookingId) {
        try {
            Boolean guestUserFlag = UserInfo.getUserType() == 'Guest';
            
            // Perform additional checks based on bookingId or siteURL if necessary
            if (guestUserFlag && bookingId != null) {
                // Example: Check if the booking record exists
                Booking__c booking = [
                    SELECT Id FROM Booking__c WHERE Id = :bookingId LIMIT 1
                ];
                if (booking != null) {
                    return true;
                }
            }
            return guestUserFlag;
        } catch (Exception e) {
            System.debug('Error in checkIfGuestUser: ' + e.getMessage());
            throw new AuraHandledException('An error occurred while checking guest user status.');
        }
    }
    
    private static Boolean isCRMManager(Id bkId){
        
        Boolean isCRMManager = false;
        String loggedInUserId = UserInfo.getUserId();
        
        List<Booking__c> CRMTeamMembers = [ SELECT Id, Name, OwnerId
                                           FROM Booking__c
                                           WHERE Id =:bkId AND OwnerId = :loggedInUserId
                                          ];
        system.debug('CRMTeamMembers:'+CRMTeamMembers);
        if(CRMTeamMembers != null && !CRMTeamMembers.isEmpty()){
            if(loggedInUserId == CRMTeamMembers[0].OwnerId){
                isCRMManager = true;
            }
        }
        return isCRMManager;
    }
    private static Boolean isAccountsManager(String towerId){
        
        Boolean isAccountsManager = false;
        String loggedInUserId = UserInfo.getUserId();
        
        // Account Manager is present on respective "Tower" 
        List<Tower__c> towers =  [SELECT Id, Name, Finance_Manager__c
                                  FROM Tower__c
                                  WHERE Id = :towerId
                                 ];
        if(towers != null && !towers.isEmpty() && towers.size() == 1){
            if(towers[0].Finance_Manager__c != null && towers[0].Finance_Manager__c == loggedInUserId){
                isAccountsManager = true;
            }
        }
        
        return isAccountsManager;
    }
    
    private static Boolean isCRMHead(String projectId){
        
        Boolean isCRMHead = false;
        String loggedInUserId = UserInfo.getUserId();
        
        // CRM Head is present on respective "Project" 
        List<Project__c> projects = [SELECT Id, Name, CRM_Head__c
                                     FROM Project__c
                                     WHERE Id = :projectId
                                    ];
        if(projects != null && !projects.isEmpty() && projects.size() == 1){
            if(projects[0].CRM_Head__c != null && projects[0].CRM_Head__c == loggedInUserId){
                isCRMHead = true;
            }
        }
        
        return isCRMHead;
    }
    
    @AuraEnabled(cacheable = false)
    global static void savePossessionCheckList(List<Possession_checklist__c> mpList, Id bkId , boolean isAccManager , boolean isCRMManager, boolean isCustomer ) {
        List<Possession_checklist__c> existingPCList = [
            SELECT Id, Particulars__c, Section__c, Received__c, Booking__c,Remarks__c, CRM_Status__c, FM_Status__c,Customer_Status__c
            FROM Possession_checklist__c 
            WHERE Booking__c = :bkId AND Particulars__c != null
        ];
        
        // Store Unit ID
        List<Booking__c> bookings =  [SELECT Id, Name, Unit__c, Tower__r.Finance_Manager__c FROM Booking__c WHERE Id =: bkId];
        String unitID = null;
        if(bookings != null && !bookings.isEmpty()){
            unitID = bookings[0].Unit__c;
        }
        Map<String, Map<String, Possession_checklist__c>> existingPCMap = new Map<String, Map<String, Possession_checklist__c>>();
        
        for (Possession_checklist__c pc : existingPCList) {
            if (!existingPCMap.containsKey(pc.Section__c)) {
                existingPCMap.put(pc.Section__c, new Map<String, Possession_checklist__c>());
            }
            existingPCMap.get(pc.Section__c).put(pc.Particulars__c, pc);
        }
        System.debug('mpList :::' + mpList);
        List<Possession_checklist__c> recordsToInsert = new List<Possession_checklist__c>();
        List<Possession_checklist__c> recordsToUpdate = new List<Possession_checklist__c>();
        
        for (Possession_checklist__c mp : mpList) {
            if (existingPCMap.containsKey(mp.Section__c) && existingPCMap.get(mp.Section__c).containsKey(mp.Particulars__c)) {
                Possession_checklist__c existingPC = existingPCMap.get(mp.Section__c).get(mp.Particulars__c);
                if (mp.Received__c != null) {
                    existingPC.Received__c = mp.Received__c;
                }                if (mp.CRM_Status__c != null) {
                    existingPC.CRM_Status__c = mp.CRM_Status__c;
                }
                if (mp.FM_Status__c != null) {
                    existingPC.FM_Status__c = mp.FM_Status__c;
                }
                if (mp.Customer_Status__c != null) {
                    existingPC.Customer_Status__c = mp.Customer_Status__c;
                }
                if (mp.Accounts_Clearance__c != null) {
                    existingPC.Accounts_Clearance__c = mp.Accounts_Clearance__c;
                }
                if (mp.Checklist_Identifier__c != null) {
                    existingPC.Checklist_Identifier__c = mp.Checklist_Identifier__c;
                }
                if (mp.Remarks__c != null) {
                    existingPC.Remarks__c = mp.Remarks__c;
                }
                /*if (bookings != null && !bookings.isEmpty() && bookings[0].Business_Region__c != null) {
                    existingPC.Business_Region__c = bookings[0].Business_Region__c;
                }*/
                recordsToUpdate.add(existingPC);
            } else {
                Possession_checklist__c newPC = new Possession_checklist__c();
                if (mp.Particulars__c != null) {
                    newPC.Particulars__c = mp.Particulars__c;
                }
                if (mp.Received__c != null) {
                    newPC.Received__c = mp.Received__c;
                }
                if (mp.CRM_Status__c != null) {
                    newPC.CRM_Status__c = mp.CRM_Status__c;
                }
                if (mp.FM_Status__c != null) {
                    newPC.FM_Status__c = mp.FM_Status__c;
                }
                if (mp.Customer_Status__c != null) {
                    newPC.Customer_Status__c = mp.Customer_Status__c;
                }
                if (mp.Remarks__c != null) {
                    newPC.Remarks__c = mp.Remarks__c;
                }
                if (mp.Section__c != null) {
                    newPC.Section__c = mp.Section__c;
                }
                if (mp.Accounts_Clearance__c != null) {
                    newPC.Accounts_Clearance__c = mp.Accounts_Clearance__c;
                }
                if (mp.Checklist_Identifier__c != null) {
                    newPC.Checklist_Identifier__c = mp.Checklist_Identifier__c;
                }
               /* if (mp.Balance_due__c != null) {
                    newPC.Balance_due__c = mp.Balance_due__c;
                }
                if (mp.Payment_Received__c != null) {
                    newPC.Payment_Received__c = mp.Payment_Received__c;
                }
                if (mp.Final_dues__c != null) {
                    newPC.Final_dues__c = mp.Final_dues__c;
                }*/
                if (bkId != null) {
                    newPC.Booking__c = bkId;
                }
                if (unitID != null) {
                    newPC.Unit__c = unitID;
                }
               /* if (bookings != null && !bookings.isEmpty() && bookings[0].Business_Region__c != null) {
                    newPC.Business_Region__c = bookings[0].Business_Region__c;
                }*/
                if(isCRMManager){
                    newPC.Customer_Relationship_Manager__c = UserInfo.getUserId();
                }else if(isAccManager){
                    newPC.Account_Manager__c = bookings[0].Tower__r.Finance_Manager__c;
                }   
                recordsToInsert.add(newPC);
            }
        }
        
        System.debug('recordsToInsert :::' + recordsToInsert);
        System.debug('recordsToUpdate :::' + recordsToUpdate);
        
        Booking__c b = [SELECT Id, Name, Account_Possession_Checklist__c, CRM_Possession_Checklist__c,
                        Possession_Checklist_Status__c, Possession_Status__c 
                        FROM Booking__c
                        WHERE Id = :bkId 
                        LIMIT 1];
        
        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
            if(isCRMManager){
                b.Possession_Checklist_Status__c = 'Submitted for Approval';
            }
            UPDATE b;
        }
        
        if (!recordsToUpdate.isEmpty()) {
            UPDATE recordsToUpdate;
        }
        
        Boolean allReceivedByCRM = true;
        Boolean allReceivedByFM = true;
        Boolean allReceivedByCustomer = true;
        
        List<Possession_checklist__c> possessionChecklist = [SELECT Id, Name, Checklist_Identifier__c,CRM_Status__c,FM_Status__c,Customer_Status__c,
                                                             Accounts_Clearance__c, Booking__c
                                                             FROM Possession_checklist__c
                                                             WHERE Booking__c = : bkId];
        
        for (Possession_Checklist__c checklist : possessionChecklist) {
            System.debug('debug--> ' + checklist.Checklist_Identifier__c);
            if (checklist.CRM_Status__c != null &&  checklist.Checklist_Identifier__c != null &&  checklist.CRM_Status__c != 'Completed' && checklist.Checklist_Identifier__c == 'CRM Manager') {
                allReceivedByCRM = false;
                break;
            }
            if (checklist.FM_Status__c != null && checklist.Checklist_Identifier__c != null &&  checklist.FM_Status__c != 'Completed' && checklist.Checklist_Identifier__c == 'Account Manager') {
                allReceivedByFM = false;
                break;
            }
             if (checklist.Customer_Status__c != null && checklist.Checklist_Identifier__c != null &&  checklist.Customer_Status__c != 'Completed' && checklist.Checklist_Identifier__c == 'Customer') {
                allReceivedByCustomer = false;
                break;
            }
        }
        
        if (allReceivedByCRM && isCRMManager) {
            b.CRM_Possession_Checklist__c = true;
            b.Possession_Status__c = 'Sent for FM approval';
            update b;
        }
        if (allReceivedByFM && isAccManager) {
            b.Account_Possession_Checklist__c = true;
            b.Possession_Status__c = 'Sent for CRM approval';
            update b;
        }
        if (allReceivedByCustomer && isCustomer) {
            b.Customer_Possession_Checklist__c = true;
            b.Possession_Status__c = 'Sent for Customer approval';
            update b;
        }else{
            b.Possession_Status__c = 'Rejected by Customer';
            update b;
        }
    }
    
    @AuraEnabled(cacheable = false)
    public static Boolean updatePossessionChecklistStatusFromCRMHead(String bookingId, String approvalStatus){
        try {
            List<Booking__c> bookings = [SELECT Id, Name, Possession_Checklist_Status__c, Possession_Status__c, Possession_Approved_By_CRM_Head__c
                                         FROM Booking__c
                                         WHERE Id =: bookingId
                                        ];
            
            if(bookings != null && !bookings.isEmpty()){
                if(approvalStatus != null && approvalStatus == 'Approved'){
                    bookings[0].Possession_Approved_By_CRM_Head__c = true;
                    bookings[0].Possession_Checklist_Status__c = 'Approved';
                    bookings[0].Possession_Status__c = 'Sent for Customer approval';

                }
                else if(approvalStatus != null && approvalStatus == 'Rejected'){
                    bookings[0].Possession_Approved_By_CRM_Head__c = false;
                    bookings[0].Possession_Checklist_Status__c = 'Rejected';
                }
            }
            update bookings;
            System.debug('update booking :  ' + bookings[0]);
            return true;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}