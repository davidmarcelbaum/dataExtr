%-------------------------------------------------------------------------%
% This script extracts data points from EEG recordings saved in EEGLAB    %
% format. Extracted information includes: data points, number of trials,  %
% sample rate, seconds before and after trigger, time values, number of   %
% time points, name and path of file of origin.                           %
%-------------------------------------------------------------------------%

%% Set up user land
if contains(computer,'PCWIN') == 1
    slashSys = '\';
else
    slashSys = '/';
end

pathName = strcat(uigetdir(cd,'Choose the folder that contains the datasets'),slashSys);

FilesList = dir([pathName,'*.set']);

if contains(FilesList(1).name,'Selected')
    
    str_del = 'Selected';
    dataType = 'Epoched';
    saveFolder = 'DataChan';
   
elseif contains(FilesList(1).name,'ICA')
    
    str_del = 'ICA';
    dataType = 'Whole';
    saveFolder = 'WholeChanData';
    
end

% Build save path for result saving at end
if ~exist(strcat(cd, slashSys, saveFolder),'dir')
    mkdir(strcat(cd, slashSys, saveFolder))
end
savePath = strcat(cd, slashSys, saveFolder, slashSys);

looped = 0;

%% Magical unicorn loop
for Filenum = 1:numel(FilesList) %Loop going from the 1st element in the folder, to the total elements

    %Initializes the variables EEG and ALLEEG that are needed later. For some reason,
    %the functions work better when EEGLAB initializes the variables itself, which is
    %why I added the last line.
    ALLCOM = {};
    ALLEEG = [];
    CURRENTSET = 0;
    EEG = [];
    [ALLCOM ALLEEG EEG CURRENTSET] = eeglab;
    
    %Function to load .set into EEGLAB
    EEG = pop_loadset('filename',FilesList(Filenum).name,'filepath',pathName);
    
    %Stores daataset in first (0) slot.
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    
    for i = 1:size(EEG.chanlocs,2)
        Labels{i,1} = EEG.chanlocs(i).labels;
    end
    
    Data = EEG.data; % Contains data points
    Trials = EEG.trials; % Number of trials
    Srate = EEG.srate; % Sample rate
    TrialStart = EEG.xmin; % seconds before trigger
    TrialEnd = EEG.xmax; % seconds after trigger
    Times = EEG.times; % time values of whole set
    Pnts = EEG.pnts; % Number of time points per trial
    Filename = FilesList(Filenum).name; % file name
    Origin = strcat(EEG.filepath, FilesList(Filenum).name); % where...
    % do the channels have been extracted from
    
    % Build name of file to save
    saveName = insertAfter(FilesList(Filenum).name,'sleep_',...
        [dataType,'ChanDat_']);
    
    saveName = extractBefore(saveName,['_',str_del]);
            
%     saveName = replace(saveName,'.set','.mat');

    saveName = strcat(saveName,'.mat');
    
%     save(strcat(savePath, saveName), 'Channel', '-v7.3');
    save(strcat(savePath, saveName), 'Labels', 'Data', 'Trials', 'Srate',...
        'TrialStart', 'TrialEnd', 'Times', 'Pnts', 'Filename', 'Origin',...
        '-v7.3');

    clear EEG saveName Channel
    
    looped = looped + 1;
end

close all

if numel(FilesList) == looped
   fprintf('Done. Computed %d datasets.', looped)
end