/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-04-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class RecordOwnershipController {
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectList() {
      List<String> objects = new List<String>{'Account', 'Opportunity', 'Lead', 'Case'};
      return objects;
    }
  
    @AuraEnabled(cacheable=true)
    public static List<OwnershipData> getOwnershipData(String objectName) {
      try {
        // Validate object name to prevent SOQL injection
        List<String> validObjects = new List<String>{'Account', 'Opportunity', 'Lead', 'Case'};
        if (!validObjects.contains(objectName)) {
          throw new AuraHandledException('Invalid object name');
        }
  
        // Query to get record count by owner
        String query = 'SELECT OwnerId, COUNT(Id) recordCount FROM ' + objectName + ' GROUP BY OwnerId';
        List<AggregateResult> results = Database.query(query);
  
        // Collect all OwnerIds
        Set<Id> ownerIds = new Set<Id>();
        Map<Id, Integer> ownerCountMap = new Map<Id, Integer>();
        for (AggregateResult ar : results) {
          Id ownerId = (Id)ar.get('OwnerId');
          ownerIds.add(ownerId);
          ownerCountMap.put(ownerId, (Integer)ar.get('recordCount'));
        }
  
        // Query to identify which OwnerIds are Users (not Queues)
        List<User> users = [SELECT Id, Name FROM User WHERE Id IN :ownerIds];
        Map<Id, String> userIdToNameMap = new Map<Id, String>();
        for (User u : users) {
          userIdToNameMap.put(u.Id, u.Name);
        }
  
        // Build ownership data only for Users
        List<OwnershipData> ownershipData = new List<OwnershipData>();
        for (Id ownerId : ownerCountMap.keySet()) {
          if (userIdToNameMap.containsKey(ownerId)) {
            ownershipData.add(new OwnershipData(
              ownerId,
              userIdToNameMap.get(ownerId),
              ownerCountMap.get(ownerId)
            ));
          }
        }
  
        return ownershipData;
      } catch (Exception e) {
        throw new AuraHandledException('Error fetching ownership data: ' + e.getMessage());
      }
    }
  
    public class OwnershipData {
      @AuraEnabled public String userId;
      @AuraEnabled public String userName;
      @AuraEnabled public Integer recordCount;
  
      public OwnershipData(String userId, String userName, Integer recordCount) {
        this.userId = userId;
        this.userName = userName;
        this.recordCount = recordCount;
      }
    }
  }