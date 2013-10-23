/**
Virtual Machine operand codes

Copyright: © 2013 Rhodeus Group
License: Subject to the terms of the Creative Commons license, as written in the included LICENSE.txt file.
Authors: Talha Zekeriya Durmuş
*/
module rhodeus.vm.opcodes;

enum OP : ushort{
	hlt,
	print, 
	jmp, jne, je,
	add, sub, mul, div, mod,
	isEquals, isNotEquals, isLower, isLowerEquals, isGreater, isGreaterEquals, isin, 
	define, var, varc, gvar, 
	pushAP,
	push, pushA, pushB, pushC, pushArray, writeDict,
	load, echo,

	finit, call, 
	inc, dec,

	and, or, 
	cmpload,
	addEqual, divEqual, modEqual, subEqual, mulEqual,

	dictInit, arrayInit, array, dict,
	getIndex, setIndex,

	endFunc, defaultparam, param, param2, param3, param4, param5, asso, paramcheck,


	getSub, setSub,
	setSlice, getSlice,

	subaccess,

	initLayer, endLayer,

	nop,
}