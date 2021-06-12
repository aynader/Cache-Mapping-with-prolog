%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%                 getDataFromCache/6                 %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

getDataFromCache(StringAddress,Cache,Data,HopsNum,directMap,BitsNum):-
    stringToList(StringAddress,ListAddress), %Get address as list
    indexGetter(ListAddress,BitsNum,ResultIndexList), %get index from the list as a list too
    listToString(ResultIndexList,ResultIndexString), %convert index list to a string 
    convertBinToDec(ResultIndexString,DecimalIndex),% convert the string of bin to dec
    getItemOnIndex(DecimalIndex,Cache,Item),  %get item[dec] in cache
    HopsNum is DecimalIndex - 1, % correct?????????

        %Tag check: necessary???
        tagGetter(ListAddress,BitsNum, ResultTagList), %get tag list
        listToString(ResultTagList,ResultTagString), % convert tag to string
        getTagFromItem(Item,Tag),
            atom_number(Tag, TagNum),
            atom_number(ResultTagString, RTagNum),
        TagNum == RTagNum,
        %%check for validity??
        getValidityFromItem(Item,ValidBit),
        ValidBit == 1,
       % getValidityFromItem(item(_,_,1,_),ValidBit).

    getDataFromItem(Item,Data). %returns data from the item at specified index

% predicate to get the index from the address as (List address -> list index).
indexGetter(ListAddress,BitsNum,ResultIndexList):-
    length(ListAddress,Length),
    Pos is Length - BitsNum,
    indexExtractor(ListAddress, Pos, ResultIndexList).

indexExtractor([H|T],Pos, ListAddress):-
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

% Predicate to convert String(binary numbers only) to List.
replace_all([],_,_,[]).
replace_all([X|T],X,Y,[Y|T2]) :- replace_all(T,X,Y,T2).
replace_all([H|T],X,Y,[H|T2]) :- H \= X, replace_all(T,X,Y,T2).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
item(Tag,Data,ValidBit,Order).
% predicate to get an item at specific index in the cache.
getItemOnIndex(DecimalIndex,[_|T],Item):-
    NewIndex is DecimalIndex - 1,
    DecimalIndex > 0,
    getItemOnIndex(NewIndex, T, Item).
getItemOnIndex(0,[H|T],H).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% predicates to get data,Tag,ValidBit from Item:
getDataFromItem(item(_,data(Data),_,_),Data).
getTagFromItem(item(tag(Tag),_,_,_),Tag).
getValidityFromItem(item(_,_,ValidBit,_),ValidBit).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% predicate to convert binary to decimal
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%        convertAddress/5        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

convertAddress(Bin,BitsNum,Tag,Idx,directMap):- %works if bin starts with 1 i.e 1XXXXX need to fillzeros
    atom_string(Bin, SBin),
    stringToList(SBin,ListBin),
    ListBin = [H|T],
    H == 1,
    tagGetter(ListBin,BitsNum,ResultTagList),
    indexGetter(ListBin,BitsNum,ResultIndexList),
    listToString(ResultTagList, STag),
    listToString(ResultIndexList,SIndex),
    atom_number(STag, Tag),
    atom_number(SIndex, Idx).
    
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


withZerosStringGetter(SBin,BitsNum,WithZeros):-  %this predicate returns a string with the appropiate number of zeros.
    
    stringToList(SBin,ListBin),
    length(ListBin,Length),
    Length =< (2**BitsNum),
    L1 is 2**BitsNum - (Length - BitsNum),
    fillZeros(SBin,L1,WithZeros).




%Helper
fillZeros(String, NumberOfZeros, ResultFinal):-
    stringToList(String,List),
    zerosAdder(List,NumberOfZeros,Result),
    listToString(Result,ResultFinal).
%Helper of helper
zerosAdder(List,NumberOfZeros,Result):-
    append([0],List,Res),
    NewN is NumberOfZeros - 1,
    NewN > -1,
    zerosAdder(Res,NewN,Result).
zerosAdder(List,0,List).







%%%%%%%%%%%%%%%%%%%testing%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    replaceIthItem(item(NewTag,ItemData,1,0),OldCache,IdxDec,NewCache).


replaceIthItem(Item,[_|T],0,[Item|T]).
replaceIthItem(Item,[H|T],Index,[H|Res]):-
    Index > -1 ,
    Index1 is Index - 1,
    replaceIthItem(Item,T,Index1,Res).




getData(StringAddress,OldCache,Mem,NewCache,Data,HopsNum,Type,BitsNum,hit):-
getDataFromCache(StringAddress,OldCache,Data,HopsNum,Type,BitsNum),
NewCache = OldCache.

getData(StringAddress,OldCache,Mem,NewCache,Data,HopsNum,Type,BitsNum,miss):-
\+getDataFromCache(StringAddress,OldCache,Data,HopsNum,Type,BitsNum),
atom_number(StringAddress,Address),
convertAddress(Address,BitsNum,Tag,Idx,Type),
replaceInCache(Tag,Idx,Mem,OldCache,NewCache,Data,Type,BitsNum).


runProgram([],OldCache,_,OldCache,[],[],Type,_).
runProgram([Address|AdressList],OldCache,Mem,FinalCache,
[Data|OutputDataList],[Status|StatusList],Type,NumOfSets):-
getNumBits(NumOfSets,Type,OldCache,BitsNum),
getData(Address,OldCache,Mem,NewCache,Data,HopsNum,Type,BitsNum,Status),
runProgram(AdressList,NewCache,Mem,FinalCache,OutputDataList,StatusList,
Type,NumOfSets).



