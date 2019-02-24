# Bugsnag Auto Version

An Azure DevOps build task for updating your current Bugsnag AppVersion and notifying bugsnag of your release. Available on the [Visual Studio Marketplace](https://marketplace.visualstudio.com/publishers/ThatBlokeCalledJay)

> **Important Notice:** Though Bugsnag have kindly given permission to use their logo, it is important to note that this extension is not an official Bugsnag product. If you are having any difficulties with this extension, please do not contact Bugsnag, conact me through the usual channels, Q&A, and issues etc. Likewise... If you are having difficulties with Bugsnag, unrelated to this extension, please direct your questions to Bugsnag, and not me.  


> Note: Bugsnag Auto Version has been designed to work with Azure DevOps pipelines.

### Looking for help getting setup.

Checkout the getting started wiki [rigt here](https://github.com/ThatBlokeCalledJay/bugsnag-auto-version/wiki/Getting-Started).

### Version Number Madness

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

**On Visual Studio Marketplace**
- [ThatBlokeCalledJay](https://marketplace.visualstudio.com/publishers/ThatBlokeCalledJay)
- [Bugsnag Notify](#)
- [Auto App Version](https://marketplace.visualstudio.com/items?itemName=ThatBlokeCalledJay.thatblokecalledjay-autoappversion)
