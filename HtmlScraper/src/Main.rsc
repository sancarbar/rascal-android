module Main

import IO;
import lang::html::IO;
import Set;
//import util::ValueUI;

anno str node@id;
anno str node@href;

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
		case parent:"div"(ulist): if((parent@id ? "missing") == "packages-nav") {
			// Get anchors.
			visit(ulist) {
				// Get only links for android API packages.
				case alink:"a"(_): if((alink@href ? "") != "") {
					// Print anchors.
					urlSet += {alink@href};
				}
			}
		}
	}
	
	return urlSet;
}