%% Parameters
%  ------------------------------------------------------------------------

filepath = ['D:\Google Drive\Sleep_Study_Germany\BehavioralMeasures\', ...
    'TextDateien_Tasks'];

filesOI = 'Memory Abfrage';

objects = {...
    'apfel1', ...
    'auto1', ...
    'blume1', ...
    'eis1', ...
    'elefant1', ...
    'fisch1', ...
    'hammer1', ...
    'kerze1', ...
    'klammer1', ...
    'pferd1', ...
    'pinguin1', ...
    'reifen1', ...
    'schlaeger1', ...
    'schale1', ...
    'schlange1', ...
    'schmetterling1', ...
    'seehund1', ...
    'stuhl1', ...
    'tomate1', ...
    'tor1', ...
    'vogel1', ...
    'pilze2', ...
    'auto2', ...
    'ball2', ...
    'banane2', ...
    'birne2', ...
    'blume2', ...
    'eisbaer2', ...
    'glas2', ...
    'haus2', ...
    'kamel2', ...
    'kiwi2', ...
    'nilpferd2', ...
    'pinsel2', ...
    'raupe2', ...
    'schildkroete2', ...
    'seestern2', ...
    'teller2', ...
    'tiger2', ...
    'uhr2', ...
    'vogela2', ...
    'zange2'};

nonCharFile = [cd, filesep, 'weird_whitespace.mat'];



%% Prepare userland
%  ------------------------------------------------------------------------

files = dir(filepath);

% Retain only file types of interest
files = files(contains({files.name}, filesOI));

load(nonCharFile)


% Table preparation
% -----------------

% We will build a table where row is current subject in current night and 
% colums are for each stimulation type the answer quality as well as 
% reaction time.
col_var_resp    = strcat(objects, '_Correct');
col_var_reac    = strcat(objects, '_RT');

tmp_cell        = cell(length(files), numel(col_var_resp));
out_resp        = cell2table(tmp_cell, ...
                    'VariableNames', col_var_resp, ...
                    'RowNames', {files.name});

tmp_cell        = cell(length(files), numel(col_var_resp));
out_reac        = cell2table(tmp_cell, ...
                    'VariableNames', col_var_reac, ...
                    'RowNames', {files.name});





%% Fruitloops
%  ------------------------------------------------------------------------
for i_fl = 1:length(files)
    
    % We generate a huge cell array that will allow us to extract data of
    % interest: Reaction times and Correct/Wrong answers for each question
    % and which stimulus had been presented. Basically each line is a word.
    % We will store these outcomes in a table for easy retrieval of
    % information.
    
	fid             = fopen([filepath, filesep, files(i_fl).name], 'r');
    scanned_text    = textscan(fid, '%s', 'delimiter', '\n');
    fclose(fid);
    scanned_text    = scanned_text{1,1};
    
    % Clean the character vectors from undesired characters
    scanned_text    = strrep(scanned_text, newline, '');
    scanned_text    = strrep(scanned_text, char(9), '');
    scanned_text    = strrep(scanned_text, weird_char, '');
    scanned_text    = strrep(scanned_text, ' ', '');
    
    
    str_extr  = char(extractBetween(files(i_fl).name, 'Abfrage ', '.txt'));
    
    subject   = extractBetween(str_extr, '-', '-');
    night     = str2double(str_extr(end));
    
    % Up to subject 30, subjects were stimulated with task-associated odor
    % during first night.
    if str2double(subject) <= 30 && night == 1
        cue = 'D';
    elseif str2double(subject) <= 30 && night == 2
        cue = 'M';
    elseif str2double(subject) > 30 && night == 1
        cue = 'M';
    elseif str2double(subject) > 30 && night == 2
        cue = 'D';
    end
    
    % Change row name in table
    row_var = strcat('S', subject, '_Cue', cue);
    out_reac.Properties.RowNames(i_fl) = row_var;
    out_resp.Properties.RowNames(i_fl) = row_var;
    
    
    
    % Each trial is located between "Start" end "End" of frames. Inside we
    % will have:
    % - Stimuli/'object' which is the card presented
    % - CueStimulus.ACC which is 0 or 1 if answer was wrong or correct,
    %   respectively
    % - CueStimulus.RT which is the response time
    % - LogFrame Start or LogFrame End which are start and end of question
    
    str_quest_start     = 'LogFrameStart';
    str_quest_stop      = 'LogFrameEnd';
    str_quest_resp      = 'CueStimulus.ACC:';
    str_quest_reac      = 'CueStimulus.RT:';
    str_quest_type      = 'StimulusFile:Stimuli/';
    
    idx_quest_start = find(contains(scanned_text, str_quest_start));
    
    if numel(idx_quest_start) < 16
        % 16: Last trial is only end game screen but is necessary below
        error('Number of trials incorrect')
    end
    
    idx_quest_resp  = find(contains(scanned_text, str_quest_resp));
    idx_quest_reac  = find(contains(scanned_text, str_quest_reac));
    idx_quest_type  = find(contains(scanned_text, str_quest_type));
    
    
    %% Going through questions
    for i_qst = 1:numel(idx_quest_start)-1
       
        quest_range = idx_quest_start(i_qst):idx_quest_start(i_qst+1);
        
        
        % Extract trial information
        % -------------------------
        
        quest_resp  = scanned_text(idx_quest_resp(...
            ismember(idx_quest_resp, quest_range)));
        quest_resp  = str2double(extractAfter(quest_resp, str_quest_resp));
        quest_reac  = scanned_text(idx_quest_reac(...
            ismember(idx_quest_reac, quest_range)));
        quest_reac  = str2double(extractAfter(quest_reac, str_quest_reac));
        quest_type  = scanned_text(idx_quest_type(...
            ismember(idx_quest_type, quest_range)));
        quest_type  = extractBetween(quest_type, str_quest_type, '.bmp');
        
        
        % Store trial information in output table
        % ---------------------------------------
        
        idx_col_resp = find(contains(col_var_resp, quest_type));
        idx_col_reac = find(contains(col_var_reac, quest_type));
        
        out_resp{i_fl, idx_col_resp} = {quest_resp};
        out_reac{i_fl, idx_col_reac} = {quest_reac};
        
    end
    
end


% Save table in excel
str_save = strcat(filesOI, '.xlsx');
writetable(out_resp, str_save, 'Sheet', 1)
