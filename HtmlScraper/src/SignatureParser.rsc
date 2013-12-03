module SignatureParser
import ParseTree;
import IO;
import lang::java::\syntax::Java15;

//grammar for class signatures
layout Spaces = [\t\ \n]* !>> [\t\ \n]; 
lexical Iden = [a-zA-Z/\\.\[\]()0-9\<\>]+ !>> [a-zA-Z/\\.\[\]()0-9\<\>];
// public static class ClassName extends extender implements implementer link implementer2 link2

//should all be called class because it doesn't matter for the signature cases
syntax ClassDef
  = class: Modifiers+ "class" Iden ExtendsClause ImplementsClause
  | interface: Modifiers+ "interface" Iden ExtendsClause ImplementsClause
  | enum: Modifiers+ "enum" Iden ExtendsClause ImplementsClause
  ;
  
 //possible modifiers
lexical Modifiers
  = "static" 
  | "public" 
  | "abstract" 
  | "protected" 
  | "final"
  | "strict" 
  | "private" 
  ;

//will be of the form Object reference/linktoObject.html
syntax ExtendsClause 
  = empty:
  | extends: "extends" IdenLink+
  ;
  
syntax ImplementsClause 
  = empty:
  | implements: "implements" IdenLink+
  ;

syntax IdenLink
 = link: Iden Iden;
 
  //grammar for methods
  // modifiers return name (parameters)
 
 syntax MethodDef
  = method: Modifiers+ ReturnType Iden "(" Params+ ")" 
  | constant: Modifiers+ ReturnType Iden //same as fields?
  | fields: Modifiers+ ReturnType Iden
  | constructor: Modifiers+ Iden "(" Params+ ")"
  ;
  
 syntax ReturnType
  = re: Iden;
  
  //Param p or Param p, Param p2, Param p3 etc (comma!!)
  // (Param p,) should have a comma (also (Param p, param p2,)). ? does not work as might have :(
 syntax Params
  = empty:
  | nonempty: Iden
  ;
  
  /* testing class, under construction much!
// still need to find out how the implode works
// so a ADT can be build :) */
public node parseClassToAST(str classsig){
	
	 node ast = implode(#node,parse(#ClassDef,classsig));
	 return ast;
}

public node parseMethodToAST(str methodsig){

 	node ast = implode(#node,parse(#MethodDef,methodsig));
    return ast;
}
  