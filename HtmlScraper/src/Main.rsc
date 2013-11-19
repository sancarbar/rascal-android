module Main

import IO;
import lang::html::IO;
import List;

anno str node@id;

public void main(){
	html = readHTMLFile(|http://developer.android.com/reference/android/package-summary.html|);
	visit(html) {
     case "body"(bodyNode):{ 
     	for(element <- bodyNode){
     		visit(html) {
     		case element:"div"(d): {  
     			if(element@id == "body-content"){
     					println("element:  <element>");
     					visit(element) {
     					case element:"div"(e2): {
     						for(a <- e2) println("a <a>");
     						}
     					};
     				}
	     		}
     		};
     	}
     }   
   };
}