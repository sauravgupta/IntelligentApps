Class Demo.Setup
{

Parameter ProductionName = "Demo.AInterop";

Parameter SSLClientName = "SSL client";

Parameter GMailCredentialName = "GMail demo account";

// Parameter LSMSCredentialName = "LSMailServer";
/// Call this method to set up the demo environment after loading the demo package xml.
/// Make sure pBasePath ends with the proper path delimiter for this platform
ClassMethod Setup(pBasePath As %String = "/tmp/data/", pVerbose As %Boolean = 1) As %Status
{
	set tSC = $$$OK
	try {
		
		// load RxTerm.gof
		w:pVerbose !!,"Loading Demo.Data.* data",!
		set tSC = $SYSTEM.OBJ.Load(pBasePath_"RxTerm.gof",$s(pVerbose:"d", 1:"-d"))
		quit:$$$ISERR(tSC)
		set tSC = $SYSTEM.OBJ.Load(pBasePath_"Medication.gof",$s(pVerbose:"d", 1:"-d"))
		quit:$$$ISERR(tSC)
		
		// build RxTerm indices
		w:pVerbose !!,"Building indices for Demo.Data.RxTerm and .Medication: "
		set tSC = ##class(Demo.Data.RxTerm).%BuildIndices()
		quit:$$$ISERR(tSC)
		set tSC = ##class(Demo.Data.Medication).%BuildIndices()
		quit:$$$ISERR(tSC)
		w:pVerbose "DONE",! 
		
		// create credentials & configs
		w:pVerbose !!,"Creating SSL config: "
		set tNamespace = $namespace
		zn "%SYS"
		if ##class(Security.SSLConfigs).Exists(..#SSLClientName) {
			w:pVerbose "EXISTS",!
		} else {
			kill tProperties
			set tProperties("Type")=0, 
				tProperties("Enabled")=1, 
				tProperties("VerifyPeer")=0,
				tProperties("Protocols")=24
			set tSC = ##class(Security.SSLConfigs).Create(..#SSLClientName, .tProperties)
			if $$$ISERR(tSC) { zn tNamespace  quit }
		}
		zn tNamespace
		w:pVerbose "DONE",!
		
		w:pVerbose !!,"Creating GMail demo account credential: "
		if ##class(Ens.Config.Credentials).%ExistsId(..#GMailCredentialName) {
			w:pVerbose "EXISTS",!
		} else {
			set tSC = ##class(Ens.Config.Credentials).SetCredential(..#GMailCredentialName, "IRISDemo123@gmail.com", "1R1SD3m0!")
			quit:$$$ISERR(tSC)
			w:pVerbose "DONE",!
		}
		/*
		w:pVerbose !!,"Creating LSMailServer credential: "
		if ##class(Ens.Config.Credentials).%ExistsId(..#LSMSCredentialName) {
			w:pVerbose "EXISTS",!
		} else {
			set tSC = ##class(Ens.Config.Credentials).SetCredential(..#LSMSCredentialName, "gs19user01@intersystemslabs.com", "Intersystems19")
			quit:$$$ISERR(tSC)
			w:pVerbose "DONE",!
		}
		*/
		w:pVerbose !!,"Updating production settings"
		w:pVerbose !,"	configuring auto-start: "
		set tSC = ##class(%EnsembleMgr).SetAutoStart("INTELLIGENTAPPS","Demo.AInterop")
		quit:$$$ISERR(tSC)
		w:pVerbose "DONE",!
		
		
		/*
		// start production
		if ##class(Ens.Director).IsProductionRunning(.tProductionName) {
			w:pVerbose !!,"Retarting production: "
			set tSC = ##class(Ens.Director).RestartProduction()
			quit:$$$ISERR(tSC)
			w:pVerbose "DONE",!
		} else {
			w:pVerbose !!,"Starting production: "
			set tSC = ##class(Ens.Director).StartProduction(..#ProductionName)
			quit:$$$ISERR(tSC)
			w:pVerbose "DONE",!
		}
		*/
		
	} catch (ex) {
		set tSC = ex.AsStatus()
	}
	if pVerbose {
		w !
		w:$$$ISERR(tSC) $system.Status.GetErrorText(tSC)
	}
	quit tSC
}

}

