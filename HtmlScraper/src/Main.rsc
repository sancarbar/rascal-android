module Main

import IO;
import lang::html::IO;
import Set;
import Location;
//import String;
//import Node;
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