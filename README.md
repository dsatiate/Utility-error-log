# Utility-error-log

Used to write to a custom object for error logging outside of debug.  
Includes support for Platform Events as well as passing in an exception directly into the static helper class.

Settings are managed via Custom Metadata Types.  By default, logging is turned off.

<a target="_blank" href="https://githubsfdeploy.herokuapp.com?owner=dcinzona&repo=Utility_Error_Logger&ref=v1.0">
  <img alt="Deploy to Salesforce"
       src="https://github.com/dcinzona/Utility_Error_Logger/blob/master/images/deploy.png?raw=true">
</a>

### Enabling for users
For logging to be enabled, the users must be added to the permission set `Utility Logging Enabled`.  This permission set gives the user the ability to create the specific platform event records used by the default implementation.

If the permission set is not assigned to a user, `System.debug` will still log the message.  No need to have separate debug and logging statements.

### Logging in Apex
Simple Exception logging:
* `Utility_Error_Logger.Log(Exception ex);`
* `Utility_Error_Logger.Log('my error message')`

Simple example in context (You can run this using anonymous apex):

```
try{
    insert new Account(); // this will fail
} catch(Exception ex){
    Utility_Error_Logger.Log(ex);
}
```

A more verbose example includes support for bulk logging and custom error log field values:
```
try{
    insert new Account(); // this will fail
} catch(Exception ex){
    Utility_LogRecord rec = new Utility_LogRecord(ex, 'anon apex', 'ran this in dev console');
    Utility_Error_Logger.Log(new List<Utility_LogRecord>{rec});
}
```

### Logging elsewhere
The beauty of using platform events is that you can create one from a flow or an external system.  You can also write your own plugins using the plugin service class and Custom Metadata Type to implement your own logic.

### Custom Services
You can build your own custom logging services instead of using Platform Events and the default logic.  Take a look at `Utility_Logged_Service_PE.cls` for an example of how to implement your own.  Basically, you must create a custom class that extends the `Utility_Logger_Service` class.

```java
global abstract class Utility_Logger_Service {
    global abstract void processRecords(List<String> recordsAsJSON);
}
```

Once this is done, you need to create a new Custom Metadata Type `Utility_Logger_Setting` record where you define the following:

* Logger Service Class (API Name)
* Use Custom Permissions (Boolean)
* Custom Permission API Name (if `Use Custom Permissions` is checked)
