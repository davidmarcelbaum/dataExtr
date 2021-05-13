if contains(computer,'PCWIN')   
    slashSys = '\';   
else  
    slashSys = '/';
end

% path to datasets containing channel data
pathData = [uigetdir(cd,...
    'Locate folder of CHANNEL datasets'),...
    slashSys];
addpath(pathData)
FilesList = dir([pathData,'*.mat']);

savePath = strcat(pathData,'Reshaped',slashSys);

if ~exist(savePath,'dir')
    mkdir(savePath)
end

for Load2Mem = 1:numel(FilesList)
    
    tmp_data = load([pathData FilesList(Load2Mem).name]);
    
    c_fields = fields(tmp_data.Channel);
    
    for i = 1:numel(c_fields)
        
        if strcmp(c_fields(i),'data')
            break
        end
        
        tmp_data.(char(c_fields(i))) = tmp_data.Channel.(char(c_fields(i)));
        
    end
    
    tmp_data = rmfield(tmp_data,'Channel');
    
    save(strcat([savePath FilesList(Load2Mem).name]),...
        'tmp_data', '-V7.3');
        
end