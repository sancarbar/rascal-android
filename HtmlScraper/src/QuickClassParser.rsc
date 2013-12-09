module QuickClassParser

/*Quick test for class Signature parsers on http://developer.android.com/reference/classes.html
This list also includes interfaces, enums etc etc*/

import IO;
import lang::html::IO;
import Set;
import List;
import util::ValueUI;
import String;
import Template;
import ParseTree;
import SignatureParser;
import util::Benchmark;
import Main;

anno str node@id;
anno str node@href;
anno str node@class;

/*
class.html is a lineair file. The classes can be counted
startAtClass: if an error is found in a class(or connection problem) the parsing can go on from that class.
This prevents from having to run it completely everytime :)
*/
public void smain(int startAtClassNo)
{
	node ast = readHTMLFile(|http://developer.android.com/reference/classes.html|);
	int count = 1;
	visit(ast){
		case td:"td"(td_content):if((td@class ? "") == "jd-linkcol"){
			visit(td_content){
				case alink:"a"(content):{
					println("classNo: <count>");
					if(count >= startAtClassNo){ //skip if we have already seen it
						println("CLASS + <|http://developer.android.com/<alink@href>|>");
						//parseClassSignatureToAST(extractClassSig(readHTMLFile(|http://developer.android.com/<alink@href>|)));
						extractMethodSigs(extractMethodSig(readHTMLFile(|http://developer.android.com/<alink@href>|)));
					}
					count += 1;
				}
			}
		} 
	}
	println("parsed <count> classes )"); //YEAH now we know how many classes there are :D!
} //api levels inner classes
public str extractClassSig(node html) {
	str class_sig = "";
	visit(html) {
		case divC:"div"(div_class_sig): if((divC@id ? "") == "jd-header") {
			visit(div_class_sig) {
				case text:"text"(text_content) :{ class_sig += text_content + " "; } 
				case alink:"a"(a_content) :if((alink@href ? "") != "") {
					class_sig += alink@href + " ";
				}
			}
		}
	}	 
	return trim(class_sig);
}


public void extractMethodSigs(list[list[node]] methods)
{
	//println(methods);
	//println("hier");
	for(m <- methods){
		println("METHOD");
		//println("hier");
		//println(m);
		str b = getConstructSignature(m);
		println(b); 
		parseConstructSignatureToAST(b);
	}
	

}

public list[list[node]] extractMethodSig(node html){ 

	list[list[node]] methods = [];
	visit(html){
	case div:"div"(divMethod): if(/jd-details / := (div@class ? "")) {
			int constructApiLevel = 0;
			visit(divMethod) {
				case header:"h4"(h4Content): if ((header@class ? "" ) == "jd-details-title") {
					methods += [h4Content];
				}
			}
		}
	}
	
	//text(methods);
	return methods;
}
