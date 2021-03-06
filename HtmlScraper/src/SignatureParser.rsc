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

lexical Iden = [a-zA-Z\\.\[\]0-9_?]+ !>> [a-zA-Z\\.\[\]0-9_?] \ Keywords;

lexical Link = [/] [a-zA-Z/\\.\[\]0-9_?]+ !>> [a-zA-Z/\\.\[\]0-9_?] \ Keywords;

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
	| "@interface" // see http://developer.android.com/reference/java/lang/Deprecated.html
	;

syntax ClassDef
	= class: Modifiers+ TypeCategory Iden ExtendsClause? ImplementsClause?
	;

syntax ConstructDef
	= method: Modifiers+ Type Iden "(" Arguments ")"
	| constantOrField: Modifiers+ Type Iden
	| constructor: Modifiers+ Iden "(" Arguments ")"
	;

syntax ExtendsClause
	= extends: "extends" Type
	;

syntax ImplementsClause
	= implements: "implements" Type+
	;

syntax SuperClause
	= super: "super" Type
	;

syntax NestedGeneric
	= "\<" {Generic ","}* "\>"
	;

syntax Generic
	= simpleGeneric: Type
	| extendsGeneric: Type ExtendsClause
	| superGeneric: Type SuperClause
	;

syntax Type
	= withoutLink: Iden NestedGeneric?
	| withLink: Iden Link NestedGeneric?
	;

syntax Arguments
	= arguments: {Argument ","}*
	;

syntax Argument
	= Type Iden
	;

public node parseConstructSignatureToAST() {
 	node ast = implode(#node, parse(#ClassDef, |project://HtmlScraper/src/test.txt|));
    return ast;
}

/*
  Class signatures for testing:
   public class PopupMenu extends  Object /reference/java/lang/Object.html implements MenuBuilder.Callback MenuPresenter.Callback
   public abstract class AbsListView extends  AdapterView /reference/android/widget/AdapterView.html <T extends  Adapter /reference/android/widget/Adapter.html > implements  TextWatcher /reference/android/text/TextWatcher.html   ViewTreeObserver.OnGlobalLayoutListener /reference/android/view/ViewTreeObserver.OnGlobalLayoutListener.html   ViewTreeObserver.OnTouchModeChangeListener /reference/android/view/ViewTreeObserver.OnTouchModeChangeListener.html   Filter.FilterListener /reference/android/widget/Filter.FilterListener.html
  
  Method signatures for testing:
   public static AtomicReferenceFieldUpdater /reference/java/util/concurrent/atomic/AtomicReferenceFieldUpdater.html <U, W> newUpdater (Class /reference/java/lang/Class.html <U> tclass, Class /reference/java/lang/Class.html <W> vclass, String /reference/java/lang/String.html  fieldName)
   public T execute (HttpUriRequest /reference/org/apache/http/client/methods/HttpUriRequest.html  request, ResponseHandler /reference/org/apache/http/client/ResponseHandler.html <? extends T> responseHandler, HttpContext /reference/org/apache/http/protocol/HttpContext.html  context)
   public Set /reference/java/util/Set.html <String /reference/java/lang/String.html > getExtendedKeyUsage ()
   public Collection /reference/java/util/Collection.html <List /reference/java/util/List.html <?>> getPathToNames ()
   public abstract int drainTo (Collection /reference/java/util/Collection.html <? super E> c)
   public void putAll (Map /reference/java/util/Map.html <? extends K, ? extends V> map)
   public static SortedMap /reference/java/util/SortedMap.html <K, V> unmodifiableSortedMap (SortedMap /reference/java/util/SortedMap.html <K, ? extends V> map)
   public Map /reference/java/util/Map.html <String /reference/java/lang/String.html , List /reference/java/util/List.html <String /reference/java/lang/String.html >> getHeaderFields ()
*/
