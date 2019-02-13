component extends="mura.cfobject" {

		function onGlobalRequestStart(m){
			
			if(request.muraSessionManagement && !m.currentUser().isLoggedIn()){

				var siteid=getBean('contentServer').bindToDomain();
				var letmein=false;

				if(findNoCase('domain\',CGI.REMOTE_USER) gt 0){
					var SamAccountname=ucase(replacenocase(CGI.REMOTE_USER, 'domain\', ""));

					cfldap(action="query",
						server="",
						name="LDAPResults",
						start="",
						filter="(&(objectclass=user)(SamAccountName=#SamAccountname#))",
						username="",
						password="",
						attributes = "cn,o,l,st,sn,c,mail,telephonenumber, givenname, streetaddress, postalcode, SamAccountname, physicalDeliveryOfficeName, department, title");

						if(LDAPResults.recordcount){
							arguments.m.event('siteid',siteid);

							//check to see if the user has previous login into the system
							var userBean=$.getBean('user').loadBy(username=SamAccountname);

							if(!userBean.exists()
									|| 	(
										LDAPResults.givenName != userBean.get('fname')
										|| LDAPResults.sn != userBean.get('lname')
										|| userData.SamAccountname != userBean.get('remoteid')
									)
								){

								if(!userBean.exists()){
									userBean.setPassword(createUUID());
								}

								userBean.set({
										fname=userData.givienName,
										lname=userData.sn,
										username=userData.SamAccountname,
										email=userData.mail,
										remoteid=userData.SamAccountname
								}).save();
							}


							$.getBean("userUtility").loginByUserID(userBean.getUserID(),siteid);

							//set siteArray
							if(session.mura.isLoggedIn){
								session.siteArray=[];
								settingsManager = $.getBean("settingsManager");
								for( site in settingsManager.getSites()) {
									if(application.permUtility.getModulePerm("00000000000000000000000000000000000",site)){
										arrayAppend(session.siteArray,site);
									}
								}
							}

							SESSION.INETSEC.UID = LDAPResults.SamAccountname;
						} else if(!letmein){
							location(url="http://www.regalmed.com", addtoken=false);
						} else {
							SESSION.INETSEC.UID = CGI.REMOTE_USER;
						}
				} else if(!letmein) {
					location(url="http://www.regalmed.com", addtoken=false);
				} else {
					SESSION.INETSEC.UID = CGI.REMOTE_USER;
				}

				if(letmein){
					SESSION.INETSEC.UID = CGI.REMOTE_USER;
				}

			}

		}

}
