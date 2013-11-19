module Main

import IO;
import lang::html::IO;
import Set;
import util::ValueUI;

anno str node@id;
anno str node@href;
anno str node@class;

// |http://developer.android.com/reference/packages.html|

public void main(loc packageSummaryUrl){
	println(getPackageUrls(packageSummaryUrl));		
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

public set[str] getPackageInformation(loc packInformationUrl) {
	node html = readHTMLFile(packInformationUrl);
	
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
	
	text(urlSet);
	
	return urlSet;
}
