clear all;
close all;
clc
addpath('Stochastic_Bosque/');

% 4 band periodicity + 4 band entropy + 3 other for VAD = 11
% can choose 9 = 4 BP + 2 BE + 3 VAD
nFeatures = 11;
nTrees = 10;

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
    
    classLabel{i} = strrep(dataFolders(i).name, 'Class_', '');
    
    files = dir([dataFolders(i).folder '/' dataFolders(i).name '/' '*.txt']);
    for j = 1:numel(files)
        
        temp = csvread([files(j).folder '/' files(j).name]);
        data = [data; temp(:,1:nFeatures)];
        labels = [labels; i*ones(size(temp,1),1)];
    end
end

random_forest = Stochastic_Bosque(data, labels, 'ntrees', nTrees);
zero_pad
headerCreate
