module Main

import IO;
import lang::html::IO;
//import util::ValueUI;

anno str node@id;
anno str node@href;

public void main(){
	// Read html file as Node.
	node html = readHTMLFile(|http://developer.android.com/reference/packages.html|);
	
	// Get parent div with list of anchors.
	visit(html) {
		case parent:"div"(ulist): if((parent@id ? "missing") == "packages-nav") {
			// Get anchors.
			visit(ulist) {
				// Get only links for android API packages.
				case alink:"a"(_): if(/\/reference\/android\// := (alink@href ? "")) {
					// Print anchors.
					println(alink@href);
				}
			}
		}
	}	
}