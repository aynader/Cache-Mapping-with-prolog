% convertBinToDec/2:
convertBinToDec(Bin,Dec):-
    string_to_list(Bin, [H|T]),
    length([H|T],L),
    L1 is L - 1,
    convertBinToDec1([H|T],Dec,L1).
convertBinToDec1([],0,_).
convertBinToDec1([H|T],Dec,Acc):-
    Number1 is H - 48, 
    Acc1 is Acc - 1,
    convertBinToDec1(T,Dec1,Acc1),
    pow(2,Acc,Z),
    Dec is Number1 * Z + Dec1.

% replaceIthItem/4:
replaceIthItem(Item,[_|T],0,[Item|T]).
replaceIthItem(Item,[H|T],Index,[H|Res]):-
    Index > -1 ,
    Index1 is Index - 1,
    replaceIthItem(Item,T,Index1,Res).

% splitEvery/3:
splitEvery(_ , [], []).
splitEvery(N, List, [H|T]):-
    append(H, T2, List),
    length(H,N),
    splitEvery(N,T2,T).

% logBase2/2:
logBase2(1,0).
logBase2(2,1).
logBase2(Number,Result):-
    Number  > 2,
    log(Number,Up),
    log(2,Down),
    Result is round( Up/Down).

%fillZeros/4:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fillZeros(String, NumberOfZeros, ResultFinal):-
    stringToList(String,List),
    zerosAdder(List,NumberOfZeros,Result),
    listToString(Result,ResultFinal).
zerosAdder(List,NumberOfZeros,Result):-
    append([0],List,Res),
    NewN is NumberOfZeros - 1,
    NewN > -1,
    zerosAdder(Res,NewN,Result).
zerosAdder(List,0,List).
% convert list of char values to integer values (1s and 0s only)
stringToList(StringAddress,ListAddress):-
    string_to_list(StringAddress,ListAddressChars),
    replace_all(ListAddressChars,49,1,StringAddressReplacing),
    replace_all(StringAddressReplacing,48,0,ListAddress).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list to... string
listToString(List,String):-
    atomic_list_concat(List,String).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Predicate to convert String(binary numbers only) to List.
replace_all([],_,_,[]).
replace_all([X|T],X,Y,[Y|T2]) :- replace_all(T,X,Y,T2).
replace_all([H|T],X,Y,[H|T2]) :- H \= X, replace_all(T,X,Y,T2).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%getNumBits/4:
getNumBits(_,fullyAssoc,_,0).
%getNumBits for Set Associative.
getNumBits(NumOfSets,setAssoc,Cache,BitsNum):-
        length(Cache,L),
        numBitsHelperAS(L,BitsNum).
numBitsHelperAS(L,BitsNum):-
    isPowerOfTwo(L).
%getNumBits for Direct Mapping, using a helper predicate to check if the size of the Cache is a power of 2 and if not increment a variable L1 till it reaches a power of 2.

getNumBits(_,directMap,Cache,BitsNum):-
        length(Cache,L),
        numBitsHelper(L,BitsNum).
numBitsHelper(L, BitsNum):-
        isPowerOfTwo(L),
        logBase2(L,BitsNum),!.
numBitsHelper(L,BitsNum):-
        L1 is L + 1,
        numBitsHelper(L1,BitsNum).


isPowerOfTwo(1).
isPowerOfTwo(N) :-
    N > 0,
    N2 is N // 2,
    N2 * 2 =:= N,
    isPowerOfTwo(N2).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%getData/9
getData(StringAddress,OldCache,_,NewCache,Data,HopsNum,Type,BitsNum,hit):-
getDataFromCache(StringAddress,OldCache,Data,HopsNum,Type,BitsNum),
NewCache = OldCache.
getData(StringAddress,OldCache,Mem,NewCache,Data,HopsNum,Type,BitsNum,miss):-
\+getDataFromCache(StringAddress,OldCache,Data,HopsNum,Type,BitsNum),
atom_number(StringAddress,Address),
convertAddress(Address,BitsNum,Tag,Idx,Type),
replaceInCache(Tag,Idx,Mem,OldCache,NewCache,Data,Type,BitsNum).

%runProgram/8
runProgram([],OldCache,_,OldCache,[],[],_,_).
runProgram([Address|AdressList],OldCache,Mem,FinalCache,[Data|OutputDataList],[Status|StatusList],Type,NumOfSets):-
getNumBits(NumOfSets,Type,OldCache,BitsNum),
getData(Address,OldCache,Mem,NewCache,Data,_,Type,BitsNum,Status),
runProgram(AdressList,NewCache,Mem,FinalCache,OutputDataList,StatusList,
Type,NumOfSets).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% DIRECT MAPPING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%                 getDataFromCache/6                 %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
getDataFromCache(StringAddress,Cache,Data,HopsNum,directMap,BitsNum):-
    stringToList(StringAddress,ListAddress), %Get address as list
    indexGetter(ListAddress,BitsNum,ResultIndexList), %get index from the list as a list too
    listToString(ResultIndexList,ResultIndexString), %convert index list to a string 
    convertBinToDec(ResultIndexString,DecimalIndex),% convert the string of bin to dec
    getItemOnIndex(DecimalIndex,Cache,Item),  %get item[dec] in cache
    HopsNum is 0,
     %Tag check:
        tagGetter(ListAddress,BitsNum, ResultTagList), %get tag list
        listToString(ResultTagList,ResultTagString), % convert tag to string
        getTagFromItem(Item,Tag),
            atom_number(Tag, TagNum),
            atom_number(ResultTagString, RTagNum),
        TagNum == RTagNum,
        %%check for validity:
        getValidityFromItem(Item,ValidBit),
        ValidBit == 1,
    getDataFromItem(Item,Data). %returns data from the item at specified index

% predicate to get the index from the address as (List address -> list index).
indexGetter(ListAddress,BitsNum,ResultIndexList):-
    length(ListAddress,Length),
    Pos is Length - BitsNum,
    indexExtractor(ListAddress, Pos, ResultIndexList).

indexExtractor([_|T],Pos, ListAddress):-
    Pos2 is Pos - 1,
    indexExtractor(T,Pos2,ListAddress).
indexExtractor(ListAddress,0,ListAddress).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Predicate to get tag.
tagGetter(ListAddress,BitsNum,ResultTagList):-
    length(ListAddress,L),
    Pos is L - BitsNum,
    tagExtractor(ListAddress,Pos,ResultTagList).

tagExtractor(_,0,[]).
tagExtractor([],_,[]).
tagExtractor([H|T1],N,[H|T2]) :-
    N > 0,
    M is N-1,
    tagExtractor(T1,M,T2).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% predicate to get an item at specific index in the cache.
getItemOnIndex(DecimalIndex,[_|T],Item):-
    NewIndex is DecimalIndex - 1,
    DecimalIndex > 0,
    getItemOnIndex(NewIndex, T, Item).
getItemOnIndex(0,[H|_],H).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% predicates to get data,Tag,ValidBit from Item:
getDataFromItem(item(_,data(Data),_,_),Data).
getTagFromItem(item(tag(Tag),_,_,_),Tag).
getValidityFromItem(item(_,_,ValidBit,_),ValidBit).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%        convertAddress/5        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
convertAddress(Bin,BitsNum,Tag,Idx,directMap):- %works if bin starts with 1 i.e 1XXXXX need to fillzeros
    atom_string(Bin, SBin),
    stringToList(SBin,ListBin),
    ListBin = [H|_],
    H == 1,
    tagGetter(ListBin,BitsNum,ResultTagList),
    indexGetter(ListBin,BitsNum,ResultIndexList),
    listToString(ResultTagList, STag),
    listToString(ResultIndexList,SIndex),
    atom_number(STag, Tag),
    atom_number(SIndex, Idx),
    !.
    
convertAddress(Bin,BitsNum,Tag,Idx,directMap):- % if bin starts with 0 this predicate is used.
    atom_string(Bin, SBin),
    withZerosStringGetter(SBin,BitsNum,WithZeros),
    stringToList(WithZeros,ListBin),
    tagGetter(ListBin,BitsNum,ResultTagList),
    indexGetter(ListBin,BitsNum,ResultIndexList),
    listToString(ResultTagList, STag),
    listToString(ResultIndexList,SIndex),
    atom_number(STag, Tag),
    atom_number(SIndex, Idx).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%this predicate returns a string with the appropiate number of zeros.
withZerosStringGetter(SBin,BitsNum,WithZeros):-  
    
    stringToList(SBin,ListBin),
    length(ListBin,Length),
    Length =< (2**BitsNum),
    L1 is 2**BitsNum - (Length - BitsNum),
    fillZeros(SBin,L1,WithZeros).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   SET ASSOCC   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
length1([],0).
length1([_|Tail],N) :- length1(Tail,Prev),N is Prev+1.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
removehead([_|Tail], Tail).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

indexGetterSA(Address,SetsNum,ResultIndex):-
	
	stringToList(Address,Laddress),
	logBase2(SetsNum,IdxBits),
	Laddress = [H|T],
	length1(Laddress,Len),
	Len > IdxBits,
	removehead([H|T],X),
	Len1 is Len -1,
	indexGetterSA2(X,Len1,IdxBits,ResultIndex).


indexGetterSA2(Address,_,_,Address).
indexGetterSA2(X,Length,IdxBits,Address):-
    X = [_|T],
    Length1 is Length-1,
	Length > IdxBits,
	
	indexGetterSA2(T,Length1,IdxBits,Address).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tagGetterSA(ListAddress,IdxBit,Tag):-
    length(ListAddress,Len),
    Len1 is Len - IdxBit,
    tagGetterSA2(ListAddress,len1,Tag).

tagGetterSA2(_,0,[]).
tagGetterSA2([],_,[]).
tagGetterSA2([H|T1],Length,[H|T2]) :-
    Length > 0,
    Mlength1 is Length-1,
    tagGetterSA2(T1,Mlength1,T2).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
convertAddressSA(Bin,SetsNum,Tag,Idx,setAssoc):-
	atom_string(Bin,StrBin),
	stringToList(StrBin,ListBin),
	logBase2(SetsNum,IdxBit),
	tagGetterSA(ListBin,IdxBit,Tag),
	indexGetterSA(StrBin,SetsNum,Index),
	listToString(Tag, StrTag),
        listToString(Index,StrIndex),
        atom_number(StrTag, NTag),
        atom_number(StrIndex, Idx).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    Replacing   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% replaceInCache/8  -- Direct mapping
replaceInCache(Tag,Idx,Mem,OldCache,NewCache,ItemData,
directMap,BitsNum):-
    string_length(Tag, TagLength),
    N1 is 6 - BitsNum - TagLength,
    fillZeros(Tag,N1,NewTag),
    string_length(Idx,IdxLength),
    N2 is BitsNum - IdxLength,
    fillZeros(Idx,N2,NewIdx),
    string_concat(NewTag, NewIdx, AdressBin),
    convertBinToDec(AdressBin,Adress),
    nth0(Adress,Mem,Data),
    ItemData = Data,
    convertBinToDec(NewIdx,IdxDec),
    atom_string(NewTag,T),
    replaceIthItem(item(tag(T),data(ItemData),1,0),OldCache,IdxDec,NewCache).

% replaceInCache/8  -- Fully
increment([],[]).
increment([item(Tag,Data,ValidBit,Order)|L], [item(Tag,Data,ValidBit,Order1)|L2]):-
    ValidBit \= 0,
    Order1 is Order + 1,
    increment(L,L2).
increment([item(Tag,Data,ValidBit,Order)|L], [item(Tag,Data,ValidBit,Order1)|L2]):-
    ValidBit = 0,
    Order1 is Order,
    increment(L,L2).

findZeros([],0).    
findZeros([item(_,_,0,_)|T],X):-
    findZeros(T,X1),
    X is X1 + 1.
findZeros([item(_,_,1,_)|T],X):-
    findZeros(T,X1),
    X is X1 + 0.
findFirstInvalid(List,Index):-
    nth0(Index,List,item(_,_,0,_)),
    !.
findElementIndex4(List,Index,Max):-
    nth0(Index,List,item(_,_,_,Max)).

replaceInCache(Tag,_,Mem,OldCache,NewCache,ItemData,fullyAssoc,
_):-
    increment(OldCache,OldCache1),
    findZeros(OldCache1,X),
    X \= 0,
    findFirstInvalid(OldCache1,Index),
    convertBinToDec(Tag,TagDec),
    nth0(TagDec,Mem,Data),
    ItemData = Data,
    string_length(Tag, TagLength),
    NumberOfZeros = 6 - TagLength,
    fillZeros(Tag,NumberOfZeros,NewTag),
    atom_string(NewTag,T),
    replaceIthItem(item(tag(T),data(Data),1,0),OldCache1,Index,NewCache),
    !.
replaceInCache(Tag,_,Mem,OldCache,NewCache,ItemData,fullyAssoc,
_):-
    increment(OldCache,OldCache1),
    findZeros(OldCache1,X),
    X = 0,
    length(OldCache,OldCacheLength),
    findElementIndex4(OldCache1,Index,OldCacheLength),
    convertBinToDec(Tag,TagDec),
    nth0(TagDec,Mem,Data),
    ItemData = Data,
    string_length(Tag, TagLength),
    NumberOfZeros = 6 - TagLength,
    fillZeros(Tag,NumberOfZeros,NewTag),
    atom_string(NewTag,T),
    replaceIthItem(item(tag(T),data(Data),1,0),OldCache1,Index,NewCache),
    !.

% replaceInCache/8 -- Set Assoc.
findWhereToReplace(L,Index):-
    sort(4, @>=, L, Sorted),
    nth0(0,Sorted,Item),
    nth0(Index,L,Item).
   

replaceInCache(Tag,Idx,Mem,OldCache,NewCache,ItemData,setAssoc,SetsNum):-
    string_concat(Tag, Idx, AdressBin),
    convertBinToDec(AdressBin,Adress),
    nth0(Adress,Mem,Data),
 	ItemData = Data,
    splitEvery(SetsNum,OldCache,OldCache1),
    convertBinToDec(Idx,IdxBin),
    nth0(IdxBin,OldCache1,OldCache2),
    findZeros(OldCache2,X),
    X = 0,
    increment(OldCache2,OldCacheIncr),
    logBase2(SetsNum,NumBits),
    string_length(Tag, TagLength),
    NumberOfZeros is 6 - NumBits - TagLength,
    fillZeros(Tag, NumberOfZeros, NewTag),
    atom_string(NewTag,T),
    findWhereToReplace(OldCacheIncr,Index),
    replaceIthItem(item(T,Data,1,0),OldCacheIncr,Index,OldCache3),
    replaceIthItem(OldCache3,OldCache1,IdxBin,OldCache4),
    flatten(OldCache4,NewCache),
    !.

replaceInCache(Tag,Idx,Mem,OldCache,NewCache,ItemData,
setAssoc,SetsNum):-
    string_concat(Tag, Idx, AdressBin),
    convertBinToDec(AdressBin,Adress),
    nth0(Adress,Mem,Data),
 	ItemData = Data,
    splitEvery(SetsNum,OldCache,OldCache1),
    convertBinToDec(Idx,IdxBin),
    nth0(IdxBin,OldCache1,OldCache2),
    findZeros(OldCache2,X),
    X \= 0,
    increment(OldCache2,OldCacheIncr),
    logBase2(SetsNum,NumBits),
    string_length(Tag, TagLength),
    NumberOfZeros is 6 - NumBits - TagLength,
    fillZeros(Tag, NumberOfZeros, NewTag),
    atom_string(NewTag,T),
    
    findFirstInvalid(OldCacheIncr,Index),
    replaceIthItem(item(tag(T),data(Data),1,0),OldCacheIncr,Index,OldCache3),
    replaceIthItem(OldCache3,OldCache1,IdxBin,OldCache4),
    flatten(OldCache4,NewCache),
    !.

