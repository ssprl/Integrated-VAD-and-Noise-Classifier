clear all;
close all;
clc
addpath('Stochastic_Bosque/');

nBands = 4;
nTrees = 20;

dataFolders = dir('Data/Class*');

if isempty(dataFolders)
    disp('No data in Data Folder');
    return;    
end

classIndex = 1:numel(dataFolders);
classLabel = cell(1, classIndex(end));
data = [];
labels = [];

for i = 1:classIndex(end)
    
    classLabel{i} = strrep(dataFolders(i).name, 'Class_', '')
    
    files = dir([dataFolders(i).folder '/' dataFolders(i).name '/' '*.txt']);
    for j = 1:numel(files)
        files(j).name;
        temp = csvread([files(j).folder '/' files(j).name]);
        data = [data; temp(:,1:2*nBands)];
        labels = [labels; i*ones(size(temp,1),1)];
    end
end

random_forest = Stochastic_Bosque(data, labels, 'ntrees', nTrees);
zero_pad
headerCreate
