rf_size = length(random_forest);
max = length(random_forest(1).nodeCutVar);
for i = 2:rf_size
    
    if max < length(random_forest(i).nodeCutVar)
        
        max = length(random_forest(i).nodeCutVar);
        
    end
    
end

for i = 1:rf_size
    random_forest(i).nodeCutVar = [random_forest(i).nodeCutVar;zeros(max - length(random_forest(i).nodeCutVar),1)];
    random_forest(i).nodeCutValue = [random_forest(i).nodeCutValue;zeros(max - length(random_forest(i).nodeCutValue),1)];
    random_forest(i).childnode = [random_forest(i).childnode;zeros(max - length(random_forest(i).childnode),1)];
    random_forest(i).nodelabel = [random_forest(i).nodelabel;zeros(max - length(random_forest(i).nodelabel),1)];
end

createCTree