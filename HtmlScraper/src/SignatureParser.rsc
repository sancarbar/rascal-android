module SignatureParser
import ParseTree;
import IO;
extend lang::std::Layout;

keyword Keywords 
	= "interface" | "class" | "enum"| "implements" | "extends" | "private" | "static" | "public" | "abstract" | "protected" | "final" | "strict" | "private"
	;

lexical Iden = [a-zA-Z/\\.\[\]()0-9_]+ !>> [a-zA-Z/\\.\[\]()0-9_] \ Keywords ;
lexical Modifiers = "static" | "public" | "abstract" | "protected" | "final" | "strict" | "private" ;

lexical TypeCategory	
	= "class"
	| "interface"
	| "enum"
	| "@interface" //weeiiirrdd (http://developer.android.com/reference/java/lang/Deprecated.html)
	; 
	
syntax TypeDef
  = \type: Modifiers+ TypeCategory Iden ExtendsClause? ImplementsClause?;
  
//will be of the form Object reference/linktoObject.html <E extends <>> || <K,V>?
syntax ExtendsClause 
  = extends: "extends" IdenLink+ ;
  
syntax ImplementsClause 
  = implements: "implements" IdenLink+ ;

syntax IdenLink
 = link: Iden Iden Constr?;
 
syntax Constr 
	= "\<" Iden ExtendsClause "\>"
	| "\<" {Iden ","}* "\>" ;
 
 syntax MethodDef
  = method: Modifiers+ ReturnType Iden "(" Params+ ")" 
  | constant: Modifiers+ ReturnType Iden //same as fields?
  | fields: Modifiers+ ReturnType Iden
  | constructor: Modifiers+ Iden "(" Params+ ")"
  ;
  
 syntax ReturnType
  = re: Iden;
 
 syntax Params
  = empty:
  | nonempty: Iden
  ;
  
public node parseClassToAST(str classsig){
	
	 node ast = implode(#node,parse(#TypeDef,classsig));
	 return ast;
}

public node parseClassToAST(loc classloc){
	
	 node ast = implode(#node,parse(#TypeDef,classloc));
	 return ast;
}

public node parseMethodToAST(str methodsig){

 	node ast = implode(#node,parse(#MethodDef,methodsig));
    return ast;
}
  