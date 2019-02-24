# Bugsnag Auto Version

An Azure DevOps build task for updating your current Bugsnag AppVersion and notifying bugsnag of your release.

> **Important Notice:** Though [Bugsnag](https://www.bugsnag.com/) have kindly given permission to use their logo, it is important to note that this extension is not an official Bugsnag product. If you are having any difficulties with this extension, please do not contact Bugsnag, conact me through the usual channels, Q&A, and issues etc. Likewise... If you are having difficulties with Bugsnag, unrelated to this extension, please direct your questions to Bugsnag, and not me.  
 

> Note: Bugsnag Auto Version has been designed to work with Azure DevOps pipelines.

### Configure your settings file (appsettings.json)

Your Bugsnag section should look something like this

```json
}
  "BugSnag": {
    "ApiKey": "my-super-official-bugsnag-api-key",
    "AppVersion": "1.0.0",
    "AutoCaptureSessions": true
}
```

### Set your Version Mask in BAV  

For example, if you wanted to automate the patch value. Your mask would look like this: **0.0.$**
  
BAV will start to automatically increment the masked version number on each build.
  
> 1.0.0  
> 1.0.1  
> 1.0.2  
> 1.0.3  
  
### Increase your AppVersion minor value

```json
}
  "BugSnag": {
    "ApiKey": "my-super-official-bugsnag-api-key",
    "AppVersion": "1.1.0",
    "AutoCaptureSessions": true
}
```

BAV will detect the minor version has increased, and reset the patch value back to 0.  
  
> 1.1.0  
> 1.1.1  
> 1.1.2  

### Increase your AppVersion major value

```json
}
  "BugSnag": {
    "ApiKey": "my-super-official-bugsnag-api-key",
    "AppVersion": "2.0.0",
    "AutoCaptureSessions": true
}
```

BAV will detect the major version has increased, and reset the patch value back to 0.  

> 2.0.0  
> 2.0.1  
> 2.0.2  
> 2.0.3  
  
BAV writes the new version number directly back into your json file, ready for release. The new version is also saved to a variable, which you specify in your build definition's variables tab.  

### Notify Bugsnag of your release

Once the new version number has been generated and saved, you can choose to notify Bugsnag of your release. This feature makes use of Bugsnag's build api.

### Notify Bugsnag of your release further up-stream

If you decide that notifying Bugsnag of your release is a little premature at the build stage, you can opt to use an additional extension, [Bugsnag Notify](#) which performs the same notification task, either later in your build, or maybe even from a release pipeline.

### Extras

- BAV sets an `Output Variable` which can be accessed by other tasks further up the build stream. 

## Need help getting setup.

Check out the [wiki](https://github.com/ThatBlokeCalledJay/bugsnag-auto-version/wiki/Getting-Started) on getting started.  

### Version number madness

Check out the following scenario:

1. Increment your app's current version.
2. Apply new version number to FileVersion.
3. Apply new version number to AssemblyVersion.
4. Ensure .Net pack uses your new version number when generating new packages.
5. Make sure all new bugs that are sent to Bugsnag include the new version number.
6. Finally, notify Bugsnag of your latest release, and it's new version number.

If you find yourself in this scenario, [click here](https://thatblokecalledjay.com/blog/view/justanotherday/continuous-integration-and-version-number-madness-b95d40aaf761) to find out how my Azure DevOps extensions can be made to work together to automate this entire process.

### Want to notify Bugsnag during release instead of build?

Why not check out my other extensions:  

**On GitHub**
- [ThatBlokeCalledJay](https://github.com/ThatBlokeCalledJay)
- [Bugsnag Notify](https://github.com/ThatBlokeCalledJay/bugsnag-notify)
- [Auto App Version](https://github.com/ThatBlokeCalledJay/auto-app-version)
- [Set Json Property](https://github.com/ThatBlokeCalledJay/set-json-property)

**On Visual Studio Marketplace**
- [ThatBlokeCalledJay](https://marketplace.visualstudio.com/publishers/ThatBlokeCalledJay)
- [Bugsnag Notify](https://marketplace.visualstudio.com/items?itemName=ThatBlokeCalledJay.thatblokecalledjay-bugsnagnotify)
- [Auto App Version](https://marketplace.visualstudio.com/items?itemName=ThatBlokeCalledJay.thatblokecalledjay-autoappversion)
- [Set Json Property](https://marketplace.visualstudio.com/items?itemName=ThatBlokeCalledJay.thatblokecalledjay-setjsonproperty)
