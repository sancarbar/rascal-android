module SignatureParser

import ParseTree;
import IO;

extend lang::std::Layout;

keyword Keywords 
	= "interface"
	| "class"
	| "enum"
	| "implements"
	| "extends"
	| "private"
	| "static"
	| "public"
	| "abstract"
	| "protected"
	| "final"
	| "strict"
	| "private"
	| "synchronized"
	;

lexical Iden = [a-zA-Z/\\.\[\]0-9_?]+ !>> [a-zA-Z/\\.\[\]0-9_?] \ Keywords;

lexical Modifiers
	= "static"
	| "public"
	| "abstract"
	| "protected"
	| "final"
	| "strict"
	| "private"
	| "synchronized"
	;

lexical TypeCategory	
	= "class"
	| "interface"
	| "enum"
	| "@interface" //weeiiirrdd (http://developer.android.com/reference/java/lang/Deprecated.html)
	;
	
syntax TypeDef
	= \type: Modifiers+ TypeCategory Iden ExtendsClause? ImplementsClause?
	;
  
//will be of the form Object reference/linktoObject.html <E extends <>> || <K,V>?
syntax ExtendsClause 
	= extends: "extends" IdenLink+
	;

syntax ImplementsClause 
	= implements: "implements" IdenLink+
	;

syntax IdenLink
	= link: Iden Iden Generic?
	;
 
syntax Generic
	= "\<" Iden ExtendsClause "\>"
	| "\<" {Iden ","}* "\>"
	;

syntax ConstructDef
	= method: Modifiers+ ConstructType Iden"(" Params ")"
	| constantOrField: Modifiers+ ConstructType Iden
	| constructor: Modifiers+ Iden "(" Params ")"
	;

syntax ConstructType
	= constructType: Iden NestedGeneric?
	;

syntax NestedGeneric
	= "\<" {Generic2 ","}* "\>"
	;

syntax Generic2
	= simpleGeneric: Iden
	| extendsGeneric: Iden ExtendsClause2
	| superGeneric: Iden SuperClause2
	| nestedGeneric: Iden NestedGeneric
	;

syntax ExtendsClause2
	= extends: "extends" IdenLink2+
	;

syntax SuperClause2
	= super: "super" IdenLink2+
	;

syntax IdenLink2
	= link: Iden Iden? NestedGeneric? //TODO: probably remove ? after Iden, added because otherwise it won't parse 'ResponseHandler<? extends T>', but probably there should be a link after T
	;

syntax Params
	= params: {Param ","}*
	;

syntax Param
	= param: Iden NestedGeneric? Iden
	;

public node parseClassSignatureToAST(str classSignature) {
	println(classSignature);
	node ast = implode(#node, parse(#TypeDef, classSignature));
	return ast;
}

public node parseConstructSignatureToAST(str methodSignature) {
	println(methodSignature);
	node ast = implode(#node, parse(#ConstructDef, methodSignature));
    return ast;
}

//public T execute (HttpUriRequest request, ResponseHandler<? extends T> responseHandler, HttpContext context)
//public Collection<List<?>> getPathToNames ()
//public abstract int drainTo (Collection<? super E> c)
//public void putAll (Map<? extends K, ? extends V> m)
