

NCVar = [];
NCVal = [];
CN = [];
NL = [];

for i = 1:length(random_forest)
    NCVar = [NCVar, random_forest(i).nodeCutVar];
    NCVal = [NCVal, random_forest(i).nodeCutValue];
    CN = [CN, random_forest(i).childnode];
    NL = [NL, random_forest(i).nodelabel];
end

%csvwrite('../VAD/NCVar.txt',NCVar');
%csvwrite('../VAD/NCVal.txt',NCVal');
%csvwrite('../VAD/CN.txt',CN');
%csvwrite('../VAD/NL.txt',NL');
