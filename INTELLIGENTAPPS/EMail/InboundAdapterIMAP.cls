/// Adapter that receives email messages via the IMAP protocol.
Class EMail.InboundAdapterIMAP Extends Ens.InboundAdapter [ System = 4 ]
{

Parameter SERVICEINPUTCLASS = "%Net.MailMessage";

/// Address of the IMAP Email Server to get mail from
Property IMAPServer As %String;

/// TCP Port on the IMAP Email Server to get mail from. If left blank, the adapter will use port 143 for plain text and port 995 for SSL/TLS.
Property IMAPPort As %Integer;

/// A list of strings to look for in the From: field of incoming email messages, separated by semicolons (';').<p>
/// If empty, matches every message. If not, only messages containing any of these (partial) strings AND matching other match settings (To:,Subject:) will be processed.
Property MatchFrom As %String;

/// A list of strings to look for in the To: field of email messages, separated by semicolons (';').<p>
/// If empty, matches every message. If not, only messages containing any of these (partial) strings AND matching other match settings (From:,Subject:) will be processed.
Property MatchTo As %String;

/// A list of strings to look for in the Subject: field of email messages, separated by semicolons (';').<p>
/// If empty, matches every message. If not, only messages containing any of these (partial) strings AND matching other match settings (From:,To:) will be processed.
Property MatchSubject As %String;

/// Emails sent before a specific day (ODBC format:[YY]YY-MM-DD (1997-07-01)).
Property MatchBefore As %String;

/// Emails sent after a specific day (ODBC format:[YY]YY-MM-DD (1997-07-01)).
Property MatchSince As %String;

/// Look for mail messages into all mailboxes.<br/>
/// If not, the adapter looks for into a specific mailbox (see <var>MailboxName</var> parameter).
Property SeachAllMailboxes As %Boolean [ InitialExpression = 0 ];

/// Search emails into a specific mailbox.
Property MailboxName As %String;

/// To use email with Secure Socket Layer / Transport Layer Security,
/// the SSLConfig field must contain the name of 
/// an existing SSL/TLS Configuration of the Client type. You can create one using the 
/// System Management Portal [Security Management] > [SSL/TLS Configurations] page.
/// <p>If your SSL Configuration requires you to supply a password when connecting, specify it in the SSLConfig field by
/// adding a '|' after the configuration name, followed by the password string;
/// for example:<br/>MySSLItem|mypassword
/// <p>When you specify a value in the SSLConfig field, the normal case is that
/// inbound email will open a socket on default port 993 and use IMAP over SSL/TLS.
/// <p>The SSLConfig field also supports the special case when you want the server interaction 
/// to begin on a normal TCP socket and then switch to SSL/TLS on the same port as the 
/// normal socket. (RFC2595 provides the details.) In this case the default port is 143 for IMAP. 
/// To use this convention, append '*' to your entry in the SSLConfig field; 
/// for example:<br/>MySSLItem*<br/>or:<br/>MySSLItem|mypassword*
Property SSLConfig As %String;

/// Specifies whether or not to delete emails from the IMAP server after successful processing <br/>
/// If not deleted, the adapter will ignore emails already processed until something else removes them from the IMAP server.
Property DeleteFromServer As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "IMAPServer:Basic,IMAPPort:Basic,Credentials:Basic:credentialsSelector,DeleteFromServer:Basic,SSLConfig:Connection:sslConfigSelector,MatchFrom,MatchTo,MatchSubject,MatchBefore,MatchSince,SeachAllMailboxes,MailboxName";

Property MailServer As EMail.FetchImapProtocol;

/// %UIDArray(%UIDKey,SIZE,FOLDER)
/// Made this multidimensional to allow it to be NULLOREF sometimes.
Property %UIDArray [ MultiDimensional, Private ];

/// Sequence of UID message number
Property %UIDKey As %String;

Property %ILastMsg As %Integer [ InitialExpression = 0 ];

/// Array of UIDs of messages found in a single query.
Property %MsgsFound [ MultiDimensional, Private ];

Method OnInit() As %Status
{
	#; Set up IMAP MailServer object
	Do ..MailServerNewObject()  $$$ASSERT($IsObject(..MailServer))

	#; If there is an SSL Configuration identified, see if it also wants to use STARTTLS (look for the '*')
	Set ..SSLConfig = $ZSTRIP(..SSLConfig,"<>WC")
	If (""'=..SSLConfig) { 
		Set ..MailServer.SSLConfiguration = $S("*"=$E(..SSLConfig,*):$E(..SSLConfig,1,*-1),1:..SSLConfig)
		Set ..MailServer.UseSTARTTLS = ("*"=$E(..SSLConfig,*))
	}
	Set ..%UIDArray=$$$NULLOREF
	Quit ##super()
}

Method OnTask() As %Status
{
	#define MsgTable(%msgid) $$$EnsRuntimeAppData(..BusinessHost.%ConfigName,%msgid)
	#define DoneRowTable(%msgid) $$$EnsStaticAppData(..BusinessHost.%ConfigName,"adapter.imap",%msgid)

	Set $ZT="Trap",tSC=$$$OK,tCurrMsgID=""
	
	#; test dates (Match since and Match before)
	Set tSC=..TestDates() Quit:$$$ISERR(tSC) tSC
	
	Do {
		$$$sysTRACE("..%UIDArray='"_..%UIDArray_"', ..%ILastMsg="_..%ILastMsg_", ..%UIDKey="_..%UIDKey_", ..%UIDArray.Count()="_$S($IsObject(..%UIDArray):..%UIDArray.Count(),1:0)_", ..MailServer.Connected="_..MailServer.Connected)
	    
		#; (Re-)connect to the server if in clean state
		If '$IsObject(..%UIDArray) {
			$$$ASSERT(""=..%UIDKey&&(0=..%ILastMsg)&&'..MailServer.Connected)
			$$$TRACE("Connecting...")
			If '$IsObject(..%CredentialsObj) Do ..CredentialsSet(..Credentials) If '$IsObject(..%CredentialsObj) { Set tSC=$$$EnsError($$$EnsErrNoCredentials,..Credentials) Quit }
			Set tSC = ..MailServer.Connect(..IMAPServer,..%CredentialsObj.Username,..%CredentialsObj.Password)
			If $$$ISOK(tSC) {
				$$$TRACE("Connecting to IMAP server OK : "_..IMAPServer)
			}
			Else { $$$LOGSTATUS(tSC) }
				
			s a=..SearchConditions()
			$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,..MailServer.Connected_"|"_$$$timeUTC_"|"_..IMAPServer_":"_..IMAPPort)
		    #; Check for a matching messages we can deal with
		    Set:$$$ISOK(tSC) tSC=..MailServer.FetchUIDMailBoxes(..SeachAllMailboxes,..MailboxName,a,.tUIDArray)
		   			
			If $$$ISERR(tSC) || '$IsObject(tUIDArray) || (0=tUIDArray.Count()) {
				$$$TRACE("No Messages - Disconnecting...")
				If ..MailServer.Connected { Set tSCQuit = ..MailServer.QuitAndCommit()  Set:$$$ISOK(tSC) tSC = tSCQuit }
				If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
				Quit
			} Else {
				Set TotalSize=..TotalSize(tUIDArray)
				If (0'=tUIDArray.Count()) { $$$TRACE("IMAP server reports : "_tUIDArray.Count()_" message(s) found with search criteria(s) (total size "_TotalSize_" Bytes).") }
			} 
			
			Set ..%UIDArray=tUIDArray
			Kill ..%MsgsFound
		}
		
		#; Loop on the next one that can be processed
		For {
			
			Set ..%UIDKey = ..%UIDArray.Next(..%UIDKey), ..%ILastMsg=..%ILastMsg+1  Quit:""=..%UIDKey  ; done finding them
			
			Set tOneUID =..%UIDKey  $$$ASSERT(""'=tOneUID)
			Set tOneSizeUID = ..%UIDArray.GetAt(..%UIDKey).GetAt("size") $$$ASSERT(""'=tOneSizeUID)
			Set tOneFolder = ..%UIDArray.GetAt(..%UIDKey).GetAt("folder") $$$ASSERT(""'=tOneFolder)
			#; Get message-id
			Set tSC = ..MailServer.GetMessageId(tOneFolder,tOneUID,.tOneMsgID)  Quit:$$$ISERR(tSC)
			If ""=tOneMsgID $$$LOGWARNING("Received message "_..%UIDKey_" with no message-id (Unable to lock or mark it errored) in folder "_tOneFolder)
		
			#; Check for a matching message we can deal with
			If ""'=tOneMsgID {
				Set ..%MsgsFound(tOneMsgID)=1
				Lock +$$$MsgTable(tOneMsgID):0 Else  $$$LOGINFO("Skipping locked Message '"_tOneMsgID_"'") Continue
				
				#; Skip the rows we have already processed or that errored; only warn once
				If $G($$$DoneRowTable(tOneMsgID),0) { $$$TRACE("Skipping previously processed row '"_tOneMsgID_"'"_" in folder "_tOneFolder)  Lock -$$$MsgTable(tOneMsgID) Continue }
					
				If $G($$$MsgTable(tOneMsgID),0) If $G(^(tOneMsgID,"wrn")) { Kill ^("wrn") $$$LOGWARNING("Skipping previously errored message '"_tOneMsgID_"'"_" in folder "_tOneFolder) } Lock -$$$MsgTable(tOneMsgID) Continue
			}
			$$$TRACE("Got matching msg - header '"_tOneMsgID_"' in folder "_tOneFolder)
			Set:""'=tOneMsgID $$$MsgTable(tOneMsgID)=1, ^(tOneMsgID,"wrn")=1
			Set tCurrMsgID=$S(""'=tOneMsgID:tOneMsgID,1:"x")
			Quit ; found a good one
		}
		
		If ""=..%UIDKey || $$$ISERR(tSC) {
			#; Done with this UIDArray now; Disconnect
			$$$ASSERT($$$ISERR(tSC)||(""=tCurrMsgID && (..%ILastMsg-1=..%UIDArray.Count())))

			$$$TRACE("Disconnecting...")
			If ..MailServer.Connected { Set tSCQuit = ..MailServer.QuitAndCommit()  Set:$$$ISOK(tSC) tSC = tSCQuit }

			#; Remove errored and/or processed rows from the globals if they no longer exist
			Set m="" For  Set m=$Order($$$MsgTable(m))  Quit:m=""  If '$G(..%MsgsFound(m),0) Kill $$$MsgTable(m) $$$sysTRACE("Removed absent message '"_m_"' from errored list")
			Set f="" For  Set f=$Order($$$DoneRowTable(f)) Quit:f=""  If '$G(..%MsgsFound(f),0) $$$sysTRACE("Removed absent row '"_f_"' from processed list")  Kill $$$DoneRowTable(f)
			Kill ..%MsgsFound
			Set ..%UIDArray= $$$NULLOREF, ..%UIDKey="", ..%ILastMsg=0
			Quit
		}
		$$$ASSERT(tCurrMsgID'="x")	
		
		#; call BusinessService for processing
		Set tSC = ..MailServer.FetchMail(tOneFolder,tOneUID,tOneSizeUID,.tMailMessage,..DeleteFromServer)  Quit:$$$ISERR(tSC) ; Get full message
		$$$LOGINFO("Processing Mail Message "_..%ILastMsg_"/"_..%UIDArray.Count()_":'"_tCurrMsgID_"' (folder "_tOneFolder_") ;From: "_tMailMessage.From_", To: "_tMailMessage.To.GetAt(1)_", Subject: "_tMailMessage.Subject_", Date: "_tMailMessage.Date)
		Set tSC = ..BusinessHost.ProcessInput(tMailMessage)  Quit:$$$ISERR(tSC)
		
		#; Mark the Message Not Errored
		Kill:"x"'=tCurrMsgID $$$MsgTable(tCurrMsgID)
		#; Mark the Message done 
		Set:"x"'=tCurrMsgID $$$DoneRowTable(tCurrMsgID)=1
	} While 0
Exit
	Lock:""'=tCurrMsgID&&("x"'=tCurrMsgID) -$$$MsgTable(tCurrMsgID)
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,..MailServer.Connected_"|"_$$$timeUTC_"|"_..IMAPServer_":"_..IMAPPort)
	Quit tSC
Trap
	Set $ZT="",tSC=$$$EnsSystemError
	#; Disconnect if needed
	Do:..MailServer.Connected ..MailServer.QuitAndCommit()
	Goto Exit
}

Method OnTearDown() As %Status
{
	Do:..MailServer.Connected ..MailServer.QuitAndCommit()
	$$$SetJobMonitor(..BusinessHost.%ConfigName,$$$SystemName_":"_$Job,$$$eMonitorConnected,..MailServer.Connected_"|"_$$$timeUTC_"|"_..IMAPServer_":"_..IMAPPort)
	Quit $$$OK
}

/// <P> Unlike POP3 IMAP servers actually try to parse the messages stored in the folders in order to extract some information from the headers, such as sender address, recipient address, messageid and general message structure (such as attachments). The reason and upshot of this is that the server can search for messages having certain properties (for example, all messages by a certain sender) without having the client download all messages and doing the search itself. There are two search commands (SEARCH and UID SEARCH) which differ in the results they return. The first command returns sequence numbers, the second returns message UIDs.
/// Multiple search conditions can be used in one search request, those are ANDed (i.e., all have to be satisfied).</P>
/// Searching criteria are :
///  <blockquote>
/// * Emails sent before a specific day and/or,<br>
/// * Emails sent after a specific day and/or,<br>
/// * A list of strings to look for in the Subject and/or,<br>
/// * A list of strings to look for in the To
///  </blockquote>
Method SearchConditions() As %String
{
	Set (tFROM,tTO,tSUBJECT,tBEFORE,tSINCE) = ""
	
	 If (..MatchFrom'="") {
		Set tFROM = "FROM """ _ $P(..MatchFrom,";",1) _ """ "
		For i=2:1:$L(..MatchFrom,";") {
			Set tFROM = "OR " _ tFROM _ "FROM """ _ $P(..MatchFrom,";",i) _ """ "	
		}	
       
    }
    
    If (..MatchTo'="") {
		Set tTO = "TO """ _ $P(..MatchTo,";",1) _ """ "
		For i=2:1:$L(..MatchTo,";") {
			Set tTO = "OR " _ tTO _ "TO """ _ $P(..MatchTo,";",i) _ """ "	
		}	
       
    }
    
    If (..MatchSubject'="") {
		Set tSUBJECT = "SUBJECT """ _ $P(..MatchSubject,";",1) _ """ "
		For i=2:1:$L(..MatchSubject,";") {
			Set tSUBJECT = "OR " _ tSUBJECT _ "SUBJECT """ _ $P(..MatchSubject,";",i) _ """ "	
		}	
       
    }
    
    If (..MatchBefore'="") {
	   Set H=$ZDATEH(..MatchBefore,3)
	   Set MatchBefore=$p($ZDATE(H,7)," ",2)_"-"_$p($ZDATE(H,7)," ",1)_"-"_$p($ZDATE(H,7)," ",3)
	   Set tBEFORE = "BEFORE """ _ MatchBefore _  """ "
    }
    
    If (..MatchSince'="") {
	   Set H=$ZDATEH(..MatchSince,3)
	   Set MatchSince=$p($ZDATE(H,7)," ",2)_"-"_$p($ZDATE(H,7)," ",1)_"-"_$p($ZDATE(H,7)," ",3)
	   Set tSINCE = "SINCE """ _ MatchSince _  """ "
    }
    quit $zstrip(tBEFORE_tSINCE_tFROM_tTO_tSUBJECT,">W")
}

/// <P> Total of number of bytes for all messages found.</P>
Method TotalSize(tArray As %ArrayOfDataTypes) As %Integer
{
	Set index=""
	Set tSize=0
	For {
		Set index = tArray.Next(index)  Quit:""=index
		Set tSize = tSize + tArray.GetAt(index).GetAt("size")
	}
	Quit tSize
}

/// <P> Validate Match since and Match before date format.</P>
Method TestDates() As %Status
{
	#; test dates (Match since and Match before)
	If ..MatchSince'="" { 
		Set H=$ZDATEH(..MatchSince,3,,,,,,,"erropt") 
		If H="erropt" { set sc=$$$ERROR($$$GeneralError,"Match Since date is not in ODBC format") quit sc  }
	}
	If ..MatchBefore'="" {
		Set H=$ZDATEH(..MatchBefore,3,,,,,,,"erropt")
		If H="erropt" { set sc=$$$ERROR($$$GeneralError,"Match Before date is not in ODBC format") quit sc  }
	}
	quit 1
}

}

