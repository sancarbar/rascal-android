module Main

import IO;
import lang::html::IO;
import Set;
import util::ValueUI;
import Location;
import String;

anno str node@id;
anno str node@href;
anno str node@class;

// |http://developer.android.com/reference/packages.html|

public void main(loc packageSummaryUrl) {
	for (url <- getPackageUrls(packageSummaryUrl)) {
		set[str] information = getPackageInformation(|http://developer.android.com<url>|);
		
		iprintln(information);	
		
	}		
}

public set[str] getPackageUrls(loc packageSummaryUrl) {
	// Read html file as Node.
	node html = readHTMLFile(packageSummaryUrl);
	
	set[str] urlSet = {};
	
	// Get parent div with list of anchors.
	visit(html) {
		case parent:"div"(ulist): if((parent@id ? "") == "packages-nav") {
			// Get anchors.
			visit(ulist) {
				case alink:"a"(_): if((alink@href ? "") != "") {
					// Add anchor to set.
					urlSet += {alink@href};
				}
			}
		}
	}
	
	return urlSet;
}

public set[str] getPackageInformation(loc packageInformationUrl) {
	node html = readHTMLFile(packageInformationUrl);
	
	set[str] urlSet = {};
	
	visit(html) {
		case parent:"table"(table_trs): if((parent@class ? "") == "jd-sumtable-expando") {
			// Get anchors.
			visit(table_trs) {
				case trlink:"td"(field_content): if ((trlink@class ? "") == "jd-linkcol") {
					visit(field_content) {
						case alink:"a"(_): if((alink@href ? "") != "") {
							// Add anchor to set.
							urlSet += {alink@href};
						}
					}
				}
			}
		}
	}
	
	return urlSet;
}


/*
public set[str] getClassesUrls(str packageURL)
{
	//add reference to the base url
	packageUrlTotal = |http://developer.android.com|; 
	packageUrlTotal += packageURL;
	node packageFile = readHTMLFile(packageUrlTotal);
	
	set[str] classUrlSet = {};
	
	visit(packageFile){
	 case parent:"div"(table): if((parent@id ? "missing") == "jd-content")
	 {
	 	visit(table){

				case alink:"a"(_): if((alink@href ? "") != "") {

					classUrlSet += {alink@href};
				}
	 	};
	 }
	};

	return classUrlSet;
	//contains pause() and resume() at some links, contains an license.html
}
*/