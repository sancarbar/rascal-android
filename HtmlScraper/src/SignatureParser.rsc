module SignatureParser
import ParseTree;
import IO;
//import lang::java::\syntax::Java15;
extend lang::std::Layout;

keyword Keywords 
	= "interface" | "class" | "enum"| "implements" | "extends" | "private" | "static" | "public" | "abstract" | "protected" | "final" | "strict" | "private"
	;

//grammar for class signatures
//layout Spaces = [\t\ \n\r]* !>> [\t\ \n\r]; 
lexical Iden = [a-zA-Z/\\.\[\]()0-9]+ !>> [a-zA-Z/\\.\[\]()0-9] \ Keywords ;
lexical Modifiers = "static" | "public" | "abstract" | "protected" | "final" | "strict" | "private" ;
// public static class ClassName extends extender implements implementer link implementer2 link2 \<T\>

//should all be called class because it doesn't matter for the signature cases
lexical TypeCategory	
	= "class"
	| "interface"
	| "enum"
	; 
syntax TypeDef
  = \type: Modifiers+ TypeCategory Iden ExtendsClause? ImplementsClause?
  ;
  
//will be of the form Object reference/linktoObject.html <>?
syntax ExtendsClause 
  = extends: "extends" IdenLink+
  ;
  
syntax ImplementsClause 
  = implements: "implements" IdenLink+
  ;

syntax IdenLink
 = link: Iden Iden Constr?;
 
 syntax Constr = "\<" Iden ExtendsClause? "\>";
 	
  
  //grammar for methods
  // modifiers return name (parameters)
  // c1 = public class BasicHandler extends Obj Obj/ref implements Respo Respo/ref \<T\>
 // c2 tester 2 = public class BasicHandler extends Obj Obj/ref implements Respo Respo/ref
 // c4 = public static final enum Bitmap.Config extends  E E/Ref \< Iets extends Object Object/Ref \< Iets \> \>
  
 
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
// so a ADT can be build :) 
*/
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
  