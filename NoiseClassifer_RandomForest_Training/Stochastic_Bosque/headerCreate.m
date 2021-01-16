filename = ['TrainDataNC_',...
    datestr(datetime,'yyyy_mm_dd_HH_MM'),...
    '.h'];

fileID = fopen(['Random_Forest_Model/' filename], 'wt');

fprintf(fileID,'/* Training Data for Random Forest */\n');

fprintf(fileID, 'const int nTrees=%d;\n\n', rf_size);
fprintf(fileID, 'const int nClasses=%d;\n\n',...
    numel(unique(labels)));

classLabelString = '{"Quiet"';
for i = 1:classIndex(end)    
    classLabelString = [classLabelString, ', "', classLabel{i}, '"'];    
end
classLabelString = [classLabelString '}'];

% fprintf(fileID, 'const char *classLabels[] = %s;\n\n', classLabelString); 
fprintf(fileID, 'const char *noiseClassLabels[] = %s;\n\n', classLabelString);

fprintf(fileID, 'static int nodeCutVar[%d][%d] = {\n\n',...
    rf_size, size(NCVar,1));
for j = 1:rf_size
    fprintf(fileID, '\t{');
    fprintf(fileID,'%d,',NCVar(:,j));
    fprintf(fileID, '},');
    fprintf(fileID, '\n');
end
fprintf(fileID, '};\n\n');

fprintf(fileID, 'static float nodeCutValue[%d][%d] = {\n\n',...
    rf_size, size(NCVal,1));
for j = 1:rf_size
    fprintf(fileID, '\t{');
    fprintf(fileID,'%f,',single(NCVal(:,j)));
    fprintf(fileID, '},');
    fprintf(fileID, '\n');
end
fprintf(fileID, '\n};\n\n');

fprintf(fileID, 'static int childnode[%d][%d] = {\n\n',...
    rf_size, size(CN,1));
for j = 1:rf_size
    fprintf(fileID, '\t{');
    fprintf(fileID,'%d,',CN(:,j));
    fprintf(fileID, '},');
    fprintf(fileID, '\n');
end
fprintf(fileID, '};\n\n');

fprintf(fileID, 'static int nodelabel[%d][%d] = {\n\n',...
    rf_size, size(NL,1));
for j = 1:rf_size
    fprintf(fileID, '\t{');
    fprintf(fileID,'%d,',NL(:,j));
    fprintf(fileID, '},');
    fprintf(fileID, '\n');
end
fprintf(fileID, '};\n\n');
