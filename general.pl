% convertBinToDec/2:
convertBinToDec(Bin,Dec):-
    string_to_list(Bin, [H|T]),
    length([H|T],L),
    L1 is L - 1,
    convertBinToDec1([H|T],Dec,L1).
convertBinToDec1([],0,_).
convertBinToDec1([H|T],Dec,Acc):-
    Number1 is H - 48, % <---------------------- Mohamed
    Acc1 is Acc - 1,
    convertBinToDec1(T,Dec1,Acc1),
    pow(2,Acc,Z),
    Dec is Number1 * Z + Dec1.

% replaceIthItem/4:
replaceIthItem(Item,[_|T],0,[Item|T]).
replaceIthItem(_,List,_,List).
replaceIthItem(Item,[H|T],I,[H|Res]):-
    I > -1 ,
    I1 is I - 1,
    replaceIthItem(Item,T,I1,Res).

% splitEvery/3:
splitEvery(_ , [], []).
splitEvery(N, List, [H|T]):-
    append(H, T2, List),
    length(H,N),
    splitEvery(N,T2,T).    
   
% logBase2/2:
logBase2(Num,Res):-
    logBase2Helper(Num,0,Res).
logBase2Helper(Num,Acc,Res):-
    pow(2,Acc,Z),
    Num = Z,
    Res is Acc.
logBase2Helper(Num,Acc,Res):-
    pow(2,Acc,Z),
    num \= Z,
    Acc1 is Acc + 1,
    logBase2Helper(Num,Acc1,Res).

%getNumBits/4:

item(Tag,Data,ValidBit,Order).
tag(StringTag).
data(MemData).
validBit(1).

%getNumBits for Fully Associative, easy peasy.
getNumBits(_,fullyAssoc,_,0).
%getNumBits for Set Associative.
getNumBits(NumOfSets,setAssoc,Cache,BitsNum).
%getNumBits for Direct Mapping, using a helper predicate to check if the size of the Cache is a power of 2 and if not increment a variable L1 till it reaches a power of 2.
getNumBits(_,directMap,Cache,BitsNum):-
        length(Cache,L),
        numBitsHelper(L,BitsNum).
numBitsHelper(L, BitsNum):-
        isPowerOfTwo(L),
        logBase2(L,BitsNum).
numBitsHelper(L,BitsNum):-
        L1 is L + 1,
        numBitsHelper(L1,BitsNum).

%%%% Redo this predicate%%%%
isPowerOfTwo(Num) :-              %<------------------------------------------
        Num is Num /\ (Num * -1). %<------------------------------------------
%%%%!!!!!!!!!!!!!!!!!!!%%%%

%fillZeros/4:
fillZeros(String,N,R):-
    createZeros('',N,Res),
    string_concat(Res,String,R).
createZeros(Result,0,Result).
createZeros(String,Counter,Res):-
    Counter > 0,
    string_concat(String, "0", Res),
    Counter1 is Counter - 1,
    createZeros(Res,Counter1,Res).




