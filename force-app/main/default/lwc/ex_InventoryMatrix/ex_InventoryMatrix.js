import { LightningElement, api, track, wire } from "lwc";
import getOppDetails from "@salesforce/apex/Ex_InventoryMatrix.getOppDetails";
import getProjectList from "@salesforce/apex/Ex_InventoryMatrix.getProjectList";
import getTower from "@salesforce/apex/Ex_InventoryMatrix.getTower";
import getUnit from "@salesforce/apex/Ex_InventoryMatrix.getUnit";
import getUnitFloorMapDetails from "@salesforce/apex/Ex_InventoryMatrix.getUnitFloorMapDetails";
import getUnitConfigurationMapDetails from "@salesforce/apex/Ex_InventoryMatrix.getUnitConfigurationMapDetails";

import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import Unit__c from "@salesforce/schema/Unit__c"
import Sale_Status__c from "@salesforce/schema/Unit__c.Sale_Status__c";
import Configuration_Type__c from "@salesforce/schema/Unit__c.Configuration_Type__c";


export default class Ex_InventoryMatrix extends LightningElement {
  @api oppId;
  @track fetchOpp;
  @track isOppProject = false;
  @track showSpinner = false;

  @track projectList = [];
  @track towerList = [];
  @track unitList = [];

  @track storeTowerId = "";
  @track storeProjectId = "";
  @track selectedUnitId = "";

  @track defaultdata = false;
  @track showpanel = false;
  @track isAllChecked = false;
  @track isDisabled1 = false;
  @track isDisabled = true;
  @track statuscheckboxBooked = false;
  @track statuscheckboxBookingInProcess = false;
  @track statuscheckboxNotForSale = false;

  @track unitConfigurationMap = [];
  @track originalUnitFloorMap = [];
  @track selectedConfigurations = [];
  @track unitSalesStatusList = [];
  @track unitSalesStatusMap = {};


  @track vacantCount = 0;
  @track bookedCount = 0;
  @track blockedCount = 0;
  @track notForSaleCount = 0;
  @track bookingInProcessCount = 0;
  @track refugeCount = 0;
  @track reservedCount = 0;

  @track filterdata = false;
  @track filteredunitFloorMap = [];

  // Added later

  filterTypeOptions = [Sale_Status__c, Configuration_Type__c];

  @track unitSalesStatusOptions = [];
  @track unitConfigurationTypeOptions = [];

  @track selectedSalesStatusFilters = [];
  @track selectedConfigurationTypeFilters = [];
  @track unitsFoundWithSelectedFilters = true;

  connectedCallback() {
    if (this.oppId == undefined) {
      const urlSearchParams = new URLSearchParams(window.location.search);
      this.oppId = urlSearchParams.get("recordId");
    }
    console.log('oppId: ' + this.oppId);
    this.handleOppData();
  }

  handleOppData() {
    this.showSpinner = true;
    if (this.oppId !== undefined) {
      getOppDetails({ oppId: this.oppId })
        .then((result) => {
          console.log("result ", result);
          this.fetchOpp = result;
          this.error = undefined;
          if (this.fetchOpp.Project__c != undefined) {
            this.isOppProject = true;
            this.storeProjectId = this.fetchOpp.Project__c;
            this.handleProjectData();
            this.showSpinner = false;
          }
        })
        .catch((error) => {
          this.error = error;
          this.fetchOpp = undefined;
        });
    } else {
      this.handleProjectData();
      this.showSpinner = false;
    }
  }

  // Get Unit Sales Status values
  @wire(getObjectInfo, { objectApiName : Unit__c })
  unitInfo;

  @wire(getPicklistValues, {
    recordTypeId: '$unitInfo.data.defaultRecordTypeId',
    fieldApiName: Sale_Status__c
  })
  handlePicklistValues({error, data}){

    // Handle Sales Status values for filter
    if(data){

      this.unitSalesStatusOptions = data.values.map((picklistValue, index) => {
        return {
          'id' : index+1,
          'filterType' : Sale_Status__c.fieldApiName,
          'salesStatus' : picklistValue.value,
          'unitCount' : 0,
          'checkBoxStatus' : false,
          'isAll' : false
        }
      })

      // Add "All" filter 
      this.unitSalesStatusOptions = [
        {
          'id' : 0,
          'filterType' : Sale_Status__c.fieldApiName,
          'salesStatus' : 'All',
          'unitCount' : 0,
          'checkBoxStatus' : true,
          'isAll' : true
        },
        ...this.unitSalesStatusOptions
      ];
      this.selectedSalesStatusFilters = ['All'];
      console.log('Sales status values : ' + JSON.stringify(this.unitSalesStatusOptions));
    }
    // Handle Error
    else if(error){
      console.log("Error in retriving picklist values for Unit : 'Sales Status'");
      this.unitSalesStatusOptions = [];
    }
  }


  // Get Unit Configuration values
  @wire(getObjectInfo, { objectApiName : Unit__c })
  unitInfo;

  @wire(getPicklistValues, {
    recordTypeId: '$unitInfo.data.defaultRecordTypeId',
    fieldApiName: Configuration_Type__c
  })
  handleUnitConfigurations({error, data}){

  // Handle Configuration Type values of Unit
    if(data){

      this.unitConfigurationTypeOptions = data.values.map((picklistValue, index) => {
        return {
          'id' : index+1,
          'filterType' : Configuration_Type__c.fieldApiName,
          'configurationType' : picklistValue.value,
          'unitCount' : 0,
          'checkBoxStatus' : false,
          'isAll' : false
        }
      })

      // Add "All" filter 
      this.unitConfigurationTypeOptions = [
        {
          'id' : 0,
          'filterType' : Configuration_Type__c.fieldApiName,
          'configurationType' : 'All',
          'unitCount' : 0,
          'checkBoxStatus' : true,
          'isAll' : true
        },
        ...this.unitConfigurationTypeOptions
      ];
      this.selectedConfigurationTypeFilters = ['All'];
      console.log('Configuration type values : ' + JSON.stringify(this.unitConfigurationTypeOptions));
    }
    // Handle Error
    else if(error){
      console.log("Error in retriving picklist values for Unit : 'Configuration Type'");
      this.unitConfigurationTypeOptions = [];
    }
  }
  


  handleProjectData() {
    let array = [];
    array.push(this.fetchOpp);
    this.projectList = array.map((pro) => ({
      label: pro.Project__r.Name,
      value: pro.Project__r.Id
    }));
    if (this.projectList.length === 0) {
      getProjectList({}).then((result) => {
        console.log("projectList result " + JSON.stringify(result));
        this.projectList = result.map((pro) => ({
          label: pro.Name,
          value: pro.Id
        }));
      });
    } else {
      this.getTowers();
    }
    console.log("projectList: " + JSON.stringify(this.projectList));
  }

  handleProject(event) {
    this.storeProjectId = event.detail.value;
    console.log("storeProjectId: ", this.storeProjectId);
    this.getTowers();
  }

  getTowers() {
    this.showSpinner = true;
    getTower({ projId: this.storeProjectId })
      .then((data) => {
        this.towerList = data.map((t) => ({
          label: t.Name,
          value: t.Id
        }));
        console.log("Tower List:", JSON.stringify(this.towerList));
        this.showSpinner = false;
      })
      .catch((error) => {
        console.error("Error:", JSON.stringify(error));
        return Promise.reject(error);
      });
  }

  handleTower(event) {
    this.storeTowerId = event.detail.value;
    console.log("storeTowerId ", this.storeTowerId);
    this.getUnits();
    this.getUnitConfigurationMap();
    this.getUnitFloorMap();
    this.defaultdata = true;
    this.showpanel = true;
    this.isAllChecked = true;
    this.isDisabled1 = false;
    this.statuscheckboxBooked = false;
    this.statuscheckboxBlocked = false;
    this.statuscheckboxBookingInProcess = false;
    this.statuscheckboxNotForSale = false;
    this.updateUnitCountForFilters();
  }

  getUnits() {
    this.showSpinner = true;
    getUnit({ towerId: this.storeTowerId })
      .then((data) => {
        this.unitList = data;
        console.log("Unit List:", JSON.stringify(this.unitList));


        // Store Unit Details 
        this.unitSalesStatusMap = {};
        this.unitSalesStatusList = [];

        // Store as Mapping
        this.unitList.map(unit => {
          console.log('unit '+ unit);
          
          if(this.unitSalesStatusMap[unit.Sale_Status__c] == undefined){
            this.unitSalesStatusMap[unit.Sale_Status__c] = 0;
          }
          this.unitSalesStatusMap[unit.Sale_Status__c] = this.unitSalesStatusMap[unit.Sale_Status__c] + 1;
          console.log('this.unitSalesStatusMap '+ JSON.stringify(this.unitSalesStatusMap));

        })

        // Store as List (Easier to iterate on frontend)
        Object.keys(this.unitSalesStatusList).map( salesStatus => {
            this.unitSalesStatusList.push({
              'salesStatus' : salesStatus,
              'unitCount' : this.unitSalesStatusList[salesStatus]
            })
        })

        console.log('this.unitSalesStatusList : ' + this.unitSalesStatusList);

        this.showSpinner = false;
      })
      .catch((error) => {
        console.error("Error:", JSON.stringify(error));
        return Promise.reject(error);
      });
  }

  handleUnit(event) {
    this.selectedUnitId = event.detail.value;
    console.log("selectedUnitId: ", this.selectedUnitId);
  }

  getUnitConfigurationMap() {
    this.showSpinner = true;
    this.unitConfigurationMap = [];
    getUnitConfigurationMapDetails({ towerId: this.storeTowerId }).then(
      (data) => {
        if (data != null) {
          console.log("Unit Configuration Map: " + JSON.stringify(data));
          for (let config in data) {
            this.unitConfigurationMap.push({
              key: config,
              value: data[config]
            });
          }
          this.showSpinner = false;
        } else if (error) {
          console.error("Error In getUnitConfigurationMapDetails: ", error);
          this.unitConfigurationMap = null;
        }
      }
    );
    console.log(
      "unitConfigurationMap: " + JSON.stringify(this.unitConfigurationMap)
    );
  }

  getUnitFloorMap() {
    this.showSpinner = true;
    this.unitFloorMap = [];
    this.vacantCount = 0;
    this.bookedCount = 0;
    this.blockedCount = 0;
    this.bookingInProcessCount = 0;
    this.refugeCount = 0;
    this.reservedCount = 0;
    this.notForSaleCount = 0;

    getUnitFloorMapDetails({ towerId: this.storeTowerId }).then((data) => {
      if (data) {
        if (data != null) {
          console.log("Unit Map: " + JSON.stringify(data));
          this.originalUnitFloorMap = data;
          this.updateUnitCountForFilters();

          for (let floor in data) {
            console.log("floor: " + floor);
            this.unitList = data[floor];
            this.unitList = this.unitList.map((item) => ({ ...item }));

            // this.unitList = data[floor].map(u => ({
            //     ...u
            //     // isBlockedOpp: u.Opportunity__c && u.Opportunity__c.slice(0, u.Opportunity__c.length - 3) === this.oppId && u.Sale_Status__c === 'Blocked'
            // }));
            console.log("unitList: " + JSON.stringify(this.unitList));
            this.unitList.forEach((unit) => {
              if (unit.Sale_Status__c === "Vacant") {
                this.vacantCount = this.vacantCount + 1;
              } else if (unit.Sale_Status__c === "Booked") {
                this.bookedCount = this.bookedCount + 1;
              } else if (unit.Sale_Status__c === "Blocked") {
                this.blockedCount = this.blockedCount + 1;
              } else if (unit.Sale_Status__c === "Booking-In-Process") {
                this.bookingInProcessCount = this.bookingInProcessCount + 1;
              } else if (unit.Sale_Status__c === "Not for Sale") {
                this.notForSaleCount = this.notForSaleCount + 1;
              }
            });
            this.unitFloorMap.push({ key: floor, value: this.unitList });
            this.showSpinner = false;
          }
          this.unitCount =
            this.vacantCount +
            this.bookedCount +
            this.blockedCount +
            this.bookingInProcessCount +
            this.notForSaleCount;
          console.log("Unit Count: ", this.unitCount);
          console.log("unitFloorMap: " + JSON.stringify(this.unitFloorMap));
          console.log("unitFloorMap: " + JSON.stringify(this.unitFloorMap));
        } else if (error) {
          console.error("Error In getUnitFloorMapDetails: ", error);
        }
      }
    });
  }

  // Handle Quotation
  handleQuotation(event) {
    this.selectedUnitId = event.currentTarget.dataset.value;
    var link = document.createElement("a");
    if (this.selectedUnitId) {
      const url =
        "/apex/Ex_GenerateQuotationVF?uId=" +
        this.selectedUnitId +
        "&oppId=" +
        this.oppId;
      link.href = url;
      link.target = "_blank";
      link.click();
    }
  }

  // Handle Block and Unblock functionality;
  handleBlock(event) {
    console.log("oppId::: ", this.oppId);
    console.log("projValue::: ", this.storeProjectId);

    this.selectedUnitId = event.target.dataset.value;
    console.log("selectedUnitId:: ", this.selectedUnitId);
    const compDefinition = {
      componentDef: "c:ex_BlockingDetailPage",
      attributes: {
        uniValue: this.selectedUnitId,
        projValue: this.storeProjectId,
        oppvalue: this.oppId
      }
    };
    var encodedCompDef = btoa(JSON.stringify(compDefinition));
    var url = "/one/one.app#" + encodedCompDef;
    var link = document.createElement("a");
    link.href = url;
    link.target = "_self";
    link.click();
    // location.reload();
  }

  /*
    * This handles the filter selection and unselection events for below filter types
      - Configuration Type
      - Sales Status
    * It stores the selected filters to help filter wise data rendering of Units
  */
  handleFilterSelection(event){

      var checkBoxStatus = event.target.checked;
      var filterType = event.target.dataset.filterType;
      var filterBy = event.target.dataset.filterBy;
      var isAll = event.target.dataset.isAll == 'true';

      console.log('checkBoxStatus : ' + checkBoxStatus);
      console.log('filterType : ' + filterType);
      console.log('filterBy : ' + filterBy);
      console.log('isAll : ' + isAll);
      

      // Handle Sales Status Filter
      if(filterType === Sale_Status__c.fieldApiName){

        // If "All" is selected, clear existing filters and keep only "All"
        if(isAll === true){
            if(checkBoxStatus === true){
              this.selectedSalesStatusFilters = [];
              this.selectedSalesStatusFilters.push(filterBy);
            }
            else{
              this.selectedSalesStatusFilters = [];
            }
        }
        else{
          if(checkBoxStatus === true && this.selectedSalesStatusFilters.indexOf(filterBy) == -1){
            this.selectedSalesStatusFilters.push(filterBy);
          }
          else if(!checkBoxStatus === true && this.selectedSalesStatusFilters.indexOf(filterBy) != -1){
            this.selectedSalesStatusFilters = this.selectedSalesStatusFilters.filter((salesStatus, index) => {
              return this.selectedSalesStatusFilters.indexOf(filterBy) != index;
            })
          }

          // Remove "All" if present 
          if(this.selectedSalesStatusFilters.indexOf("All") != -1){
            this.selectedSalesStatusFilters = this.selectedSalesStatusFilters.filter(salesStatus => {
              return salesStatus != 'All';
            })
          }

          // If applied filters are empty then add "All"
          if(this.selectedSalesStatusFilters.length == 0){
            this.selectedSalesStatusFilters.push('All');
          }

        }
      }

      // Handle Configuration Type Filter
      if(filterType === Configuration_Type__c.fieldApiName){
        
        if(isAll === true){
            if(checkBoxStatus === true){
              this.selectedConfigurationTypeFilters = [];
              this.selectedConfigurationTypeFilters.push(filterBy);
            }
            else{
              this.selectedConfigurationTypeFilters = [];
            }
        }
        else{
          if(checkBoxStatus === true && this.selectedConfigurationTypeFilters.indexOf(filterBy) == -1){
            this.selectedConfigurationTypeFilters.push(filterBy);

          }
          else if(!checkBoxStatus === true && this.selectedConfigurationTypeFilters.indexOf(filterBy) != -1){
            this.selectedConfigurationTypeFilters = this.selectedConfigurationTypeFilters.filter((salesStatus, index) => {
              return this.selectedConfigurationTypeFilters.indexOf(filterBy) != index;
            })
          }
          
          // Remove "All" if present
          if(this.selectedConfigurationTypeFilters.indexOf("All") != -1){
            this.selectedConfigurationTypeFilters = this.selectedConfigurationTypeFilters.filter(salesStatus => {
              return salesStatus != 'All';
            })
          }

          // If applied filters are empty then add "All"
          if(this.selectedConfigurationTypeFilters.length == 0){
            this.selectedConfigurationTypeFilters.push('All');
          }
          
        }
      }
      this.updateCheckboxUIStates();
  }


  // Update the checkbox state based on selections.
  updateCheckboxUIStates(){

      // Update Sales Status Checkbox states
      this.unitSalesStatusOptions = this.unitSalesStatusOptions.map(option => {
        var isOptionSelected = this.selectedSalesStatusFilters.indexOf(option.salesStatus) != -1;
        
        if(isOptionSelected) option.checkBoxStatus = true;
        else option.checkBoxStatus = false;

        return option;
      })


      // Update Sales Status Checkbox states
      this.unitConfigurationTypeOptions = this.unitConfigurationTypeOptions.map(option => {
        var isOptionSelected = this.selectedConfigurationTypeFilters.indexOf(option.configurationType) != -1;

        if(isOptionSelected) option.checkBoxStatus = true;
        else option.checkBoxStatus = false;

        return option;
      })

  }

  // Get all the Units with floors
  get getFloorWiseAllUnits(){

      var floorWiseAllUnitsFiltered = [];
      
      Object.keys(this.originalUnitFloorMap).map( floor => {
        var units = this.originalUnitFloorMap[floor];

        var filteredUnits1 = [];
        if(this.selectedSalesStatusFilters.includes('All')){
          filteredUnits1 = units;
        }
        else{
          filteredUnits1 = units.filter(unit => {
            return this.selectedSalesStatusFilters.includes(unit.Sale_Status__c);
          });
        }

        console.log('filteredUnits1 : ' + JSON.stringify(filteredUnits1));
        
        var filteredUnits2 = [];
        if(this.selectedConfigurationTypeFilters.includes('All')){
          filteredUnits2 = filteredUnits1;
        }
        else{
          filteredUnits2 = filteredUnits1.filter(unit => {
            return this.selectedConfigurationTypeFilters.includes(unit.Configuration_Type__c);
          });
        }

        filteredUnits2 = filteredUnits2.map(unit => {
          return {
          ...unit,
          isUnitBlocked : unit.Sale_Status__c === 'Blocked',
          isQuotationVisible : unit.Sale_Status__c === 'Vacant',
          isBlockVisible : unit.Sale_Status__c === 'Vacant',
          isUnblockVisible : (unit.Sale_Status__c === 'Blocked') &&
                             (unit.Opportunity__c && unit.Opportunity__c.slice(0, unit.Opportunity__c.length - 3) === this.oppId),
          }
        })

        console.log('filteredUnits2 : ' + JSON.stringify(filteredUnits2));
        
        if(filteredUnits2.length > 0){
          floorWiseAllUnitsFiltered.push({
            'key' : floor,
            'value' : filteredUnits2
          });
        }

      })

      console.log('floorWiseAllUnitsFiltered : ' + JSON.stringify(floorWiseAllUnitsFiltered));

      return floorWiseAllUnitsFiltered;
  }


  // Update Unit counts as per filters
  updateUnitCountForFilters(){

    console.log('this.originalUnitFloorMap : ' + JSON.stringify(Object.keys(this.originalUnitFloorMap)));

    // Calculate the Unit Counts as per filters
    var unitCountBySalesStatus = { "All" : 0 };
    var unitCountByConfigurationType = {"All" : 0 };

    
    Object.keys(this.originalUnitFloorMap).map(floor => {
        console.log('FLOOR : ' + floor)
        var units = this.originalUnitFloorMap[floor];
        units.map(unit => {
            if(unitCountBySalesStatus[unit.Sale_Status__c] == undefined){
              unitCountBySalesStatus[unit.Sale_Status__c] = 0;
            }
            if(unitCountByConfigurationType[unit.Configuration_Type__c] == undefined){
              unitCountByConfigurationType[unit.Configuration_Type__c] = 0;
            }
            unitCountBySalesStatus[unit.Sale_Status__c] = unitCountBySalesStatus[unit.Sale_Status__c] + 1;
            unitCountByConfigurationType[unit.Configuration_Type__c] = unitCountByConfigurationType[unit.Configuration_Type__c] + 1;
        });
        unitCountBySalesStatus['All'] = unitCountBySalesStatus['All'] + units.length;
        unitCountByConfigurationType['All'] = unitCountByConfigurationType['All'] + units.length;
    });

    console.log('unitCountBySalesStatus : ' + JSON.stringify(unitCountBySalesStatus));
    console.log('unitCountByConfigurationType : ' + JSON.stringify(unitCountByConfigurationType));
    

    // Update the filter counts
    this.unitSalesStatusOptions = this.unitSalesStatusOptions.map( option => {
        if(unitCountBySalesStatus[option.salesStatus] != undefined){
          option.unitCount = unitCountBySalesStatus[option.salesStatus];
        }
        else{
          option.unitCount = 0;
        }
        return option;
    })
    this.unitConfigurationTypeOptions = this.unitConfigurationTypeOptions.map( option => {
      if(unitCountByConfigurationType[option.configurationType] != undefined){
        option.unitCount = unitCountByConfigurationType[option.configurationType];
      }
      else{
        option.unitCount = 0;
      }
      return option;
    })
    
  }
}