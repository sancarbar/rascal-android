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
	for (package_info <- getPackages(packageSummaryUrl)) {
	
		//println(package_info);
		map[str,set[map[str,str]]] information = getPackageInformation(|http://developer.android.com<package_info["url"]>|);
		
		iprintln(information);	
		
	}		
}

public set[map[str,str]] getPackages(loc packageSummaryUrl) {
	// Read html file as Node.
	node html = readHTMLFile(packageSummaryUrl);
	
	set[map[str,str]] packageSet = {};
	
	// Get parent div with list of anchors.
	visit(html) {
		case parent:"div"(ulist): if((parent@id ? "") == "packages-nav") {
			// Get anchors.
			visit(ulist) {
				case alink:"a"(a_content): if((alink@href ? "") != "") {
					// Get Names
					visit(a_content) {
						case atext:"text"(text_content): { 
							map[str,str] package_info = (
								"package":text_content,
								"url":alink@href
							);
							// Add anchor to set.
							packageSet += {package_info};
						}
					}		
				}
			}
		}
	}
	
	return packageSet;
}

public map[str, set[map[str, str]]] getPackageInformation(loc packageInformationUrl) {
	node html = readHTMLFile(packageInformationUrl);
	
	set[str] urlSet = {};
	set[map[str,str]] classSet = {};
	set[map[str,str]] interfaceSet = {};
	set[map[str,str]] exceptionSet = {};
	set[map[str,str]] enumsSet = {};
	set[map[str,str]] errorSet = {};
	
	visit(html) {
		// Get content div.
		case parent_div_elem:"div"(div_content): if((parent_div_elem@id ? "") == "jd-content") {
		
			str entry_type = "";
		
			visit (div_content) {
				case h2_elem:"h2"(h2_content): {
					visit(h2_content) {
						case text_elem:"text"(text_content): entry_type = text_content;
					}
				};
				case table_elem:"table"(table_trs): if((table_elem@class ? "") == "jd-sumtable-expando") {
					
					
					// Get anchors.
					visit(table_trs) {
						case trlink:"td"(field_content): if ((trlink@class ? "") == "jd-linkcol") {
							visit(field_content) {
								case alink:"a"(a_content): if((alink@href ? "") != "") {
									// Get Names
									visit(a_content) {
										case atext:"text"(text_content): { 
											map[str,str] package_info = (
												"name":text_content,
												"url":alink@href
											);
											// Group by class type.
											switch (entry_type)
											{
												case "Classes": classSet += {package_info};
												case "Interfaces": interfaceSet += {package_info};
												case "Exceptions": exceptionSet += {package_info};
												case "Enums": enumsSet += {package_info};
												case "Errors": errorSet += {package_info};
											}
										}
									}
								}
							}
						}
					}
				}
			}	
		}	
	}
	
	map[str,set[map[str,str]]] packageDescription = (
		"classes": classSet,
		"interfaces": interfaceSet,
		"exceptions": exceptionSet,
		"enums": enumsSet,
		"errors": errorSet
	);
	
	return packageDescription;
}

/*
public void getMethods(loc classInformationUrl) {
	node html = readHTMLFile(classInformationUrl);
	
	visit(html) {
		case parent:"div"(content_div): if((parent@id ? "") == "jd-content") {
			println(parent);
		}
	}	
}
*/