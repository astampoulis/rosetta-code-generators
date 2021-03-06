package com.regnosys.rosetta.generator.scala.object

import com.google.inject.Inject
import com.regnosys.rosetta.RosettaExtensions
import com.regnosys.rosetta.generator.object.ExpandedAttribute
import com.regnosys.rosetta.rosetta.RosettaClass
import com.regnosys.rosetta.rosetta.RosettaMetaType
import com.regnosys.rosetta.rosetta.simple.Data
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.Set

import static com.regnosys.rosetta.generator.scala.util.ScalaModelGeneratorUtil.*

import static extension com.regnosys.rosetta.generator.util.RosettaAttributeExtensions.*

class ScalaModelObjectGenerator {

	@Inject extension RosettaExtensions
	@Inject extension ScalaModelObjectBoilerPlate
	@Inject extension ScalaMetaFieldGenerator
	
	static final String CLASSES_FILENAME = 'Types.scala'
	static final String TRAITS_FILENAME = 'Traits.scala'
	static final String META_FILENAME = 'MetaTypes.scala'
	
	def Map<String, ? extends CharSequence> generate(Iterable<Data> rosettaClasses, Iterable<RosettaMetaType> metaTypes, String version) {
		val result = new HashMap		
		
		val superTypes = rosettaClasses
				.map[superType]
				.map[allSuperTypes].flatten
				.toSet
		
		val classes = rosettaClasses.sortBy[name].generateClasses(superTypes, version).replaceTabsWithSpaces
		result.put(CLASSES_FILENAME, classes)
		
		val traits = superTypes.sortBy[name].generateTraits(version).replaceTabsWithSpaces
		result.put(TRAITS_FILENAME, traits)
				
		val metaFields = generateMetaFields(metaTypes, version).replaceTabsWithSpaces
		result.put(META_FILENAME, metaFields)
		result;
	}
	
	private def generateClasses(List<Data> rosettaClasses, Set<Data> superTypes, String version) {
	'''
	«fileComment(version)»
	package org.isda.cdm
	
	import org.isda.cdm.metafields.{ ReferenceWithMeta, FieldWithMeta, MetaFields }
	
	«FOR c : rosettaClasses»
		«classComment(c.definition, c.allExpandedAttributes)»
		case class «c.name»(«generateAttributes(c)»)«IF c.superType === null && !superTypes.contains(c)» {«ENDIF»
			«IF c.superType !== null && superTypes.contains(c)»extends «c.name»Trait with «c.superType.name»Trait {
			«ELSEIF c.superType !== null»extends «c.superType.name»Trait {
			«ELSEIF superTypes.contains(c)»extends «c.name»Trait {«ENDIF»
		}

	«ENDFOR»
	'''
	}
	
	private def generateTraits(List<Data> rosettaClasses, String version) {
	'''
	«fileComment(version)»
	package org.isda.cdm
	
	import org.isda.cdm.metafields.{ ReferenceWithMeta, FieldWithMeta, MetaFields }
	
	«FOR c : rosettaClasses»
		«classComment(c.definition, c.expandedAttributes)»
		trait «c.name»Trait «IF c.superType !== null»extends «c.superType.name»Trait «ENDIF»{
			«generateTraitAttributes(c)»
		}

	«ENDFOR»
	'''
	}
	
	private def generateAttributes(Data c) {
		'''«FOR attribute : c.allExpandedAttributes SEPARATOR ',\n		'»«generateAttribute(c, attribute)»«ENDFOR»'''
	}
	
	private def generateAttribute(Data c, ExpandedAttribute attribute) {
		'''«attribute.toAttributeName»: «attribute.toType»'''
	}
	
	private def generateTraitAttributes(Data c) {
		'''
		«FOR attribute : c.expandedAttributes»
			«generateTraitAttribute(c, attribute)»
		«ENDFOR»
		'''
	}
	
	private def generateTraitAttribute(Data c, ExpandedAttribute attribute) {
		'''	val «attribute.toAttributeName»: «attribute.toType»'''
	}
	
	def dispatch Iterable<ExpandedAttribute> allExpandedAttributes(RosettaClass type) {
		type.allSuperTypes.expandedAttributes
	}
	
	def dispatch Iterable<ExpandedAttribute> allExpandedAttributes(Data type){
		type.allSuperTypes.map[it.expandedAttributes].flatten
	}
	
	def dispatch String definition(RosettaClass element) {
		element.definition
	}
	def dispatch String definition(Data element){
		element.definition
	}
}
