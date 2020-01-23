%-------------------------------------------------------------------------%
% This script extracts data points from EEG recordings saved in EEGLAB    %
% format. Extracted information includes: data points, number of trials,  %
% sample rate, seconds before and after trigger, time values, number of   %
% time points, name and path of file of origin as well as trigger         %
% latencies.                                                              %
%-------------------------------------------------------------------------%

%% Set up user land
if contains(computer,'PCWIN') == 1
    
    slashSys = '\';
    
else
    
    slashSys = '/';
    
end

pathName = strcat(uigetdir(cd,'Choose the folder that contains the datasets'),slashSys);

FilesList = dir([pathName,'*.set']);

   
if contains(FilesList(1).name,'ICA')
    
    str_del = 'ICA';
    dataType = 'Whole';
    saveFolder = 'DataWholeChan';
    
else 
    
    str_del = 'Selected';
    dataType = 'Epoched';
    saveFolder = 'DataChan';
    
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
                
    Labels = {EEG.chanlocs(:).labels};
    
    if strcmp(dataType,'Whole')
        
        % ADS: Separar por DIN1 y DIN2
        All_DIN1 = find(strcmp({EEG.event.code},'DIN1'));
        All_DIN2 = find(strcmp({EEG.event.code},'DIN2'));
        
        % ADS: Separar por pares e impares
        get_cidx= {EEG.event.mffkey_cidx};
        
        Placebo_Epochs = find(mod(str2double(get_cidx),2)==0);
        Odor_Epochs = find(mod(str2double(get_cidx),2)~= 0);
        
        [OdorOn] = intersect(All_DIN1,Odor_Epochs);
        [PlaceboOn] = intersect(All_DIN1,Placebo_Epochs);
        
        EventNumbers_Odor = OdorOn;
        EventNumbers_Placebo = PlaceboOn;
        Latencies_Odor = [EEG.event(OdorOn).latency];
        Latencies_Placebo = [EEG.event(PlaceboOn).latency];
        Events = EEG.event; % Hold all trigger info in case need later!
        
    elseif strcmp(dataType,'Epoched')
        
        EventNumbers_Odor = NaN;
        EventNumbers_Placebo = NaN;
        Latencies_Odor = NaN;
        Latencies_Placebo = NaN;
        Events = NaN;
        
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
    
    if contains(saveName,'.set')
        
        saveName = strrep(saveName, '.set', '.mat');
        
    else
        
        saveName = extractBefore(saveName,['_',str_del]);
        
        saveName = strcat(saveName,'.mat');
        
    end
    
    save(strcat(savePath, saveName), 'Labels', 'Data', 'Trials', 'Srate',...
        'TrialStart', 'TrialEnd', 'Times', 'Pnts', 'Filename', 'Origin',...
        'EventNumbers_Placebo', 'EventNumbers_Odor', 'Latencies_Placebo', ...
        'Latencies_Odor', 'Events', ...
        '-v7.3');

    clear EEG saveName Channel
    
    close all
    
    looped = looped + 1;
    
end

close all

if numel(FilesList) == looped
    
   fprintf('Done. Saved %d datasets in %s.', looped, savePath)
   
end