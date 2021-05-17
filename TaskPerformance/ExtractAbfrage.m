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

idx_nonFile = find(contains({files.name}, 'Comments on this version'));
files(idx_nonFile) = [];

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
    
    str_quest_start     = 'LogFrameStart'; % Last one is end game screen
    str_quest_stop      = 'LogFrameEnd';
    str_quest_resp      = 'CueStimulus.ACC:';
    str_quest_reac      = 'CueStimulus.RT:';
    str_quest_type      = 'StimulusFile:Stimuli/';
    str_last_run        = 'Recalllist:1'; % Beginning of new run
    
    idx_quest_start = find(contains(scanned_text, str_quest_start));
    
    if numel(idx_quest_start) < 16
        % 16: Last trial is only end game screen but is necessary below
        error('Number of trials incorrect')
    end
    
    idx_quest_resp      = find(contains(scanned_text, str_quest_resp));
    idx_quest_reac      = find(contains(scanned_text, str_quest_reac));
    idx_quest_type      = find(contains(scanned_text, str_quest_type));
    idx_last_run        = find(strcmp(scanned_text, str_last_run));
    
    
    % Reject all runs before last one
    % -------------------------------
    % This is a bit more complex since the line Recalllist:1 comes after
    % the card that has been asked for
    start_extraction = 0;
    
    
    %% Going through questions
    for i_qst = 1:numel(idx_quest_start)-1
       
        quest_range = idx_quest_start(i_qst):idx_quest_start(i_qst+1);
        
        if ismember(idx_last_run(end), quest_range)
            % This will be the first card pair of the last run from which
            % point on we take into the account the outcomes
            start_extraction = 1;
        end
        
        if start_extraction == 0
            continue
        end
        
        
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



%% Save table in excel format
%  ------------------------------------------------------------------------

str_save = strcat(filesOI, '.xlsx');
writetable(out_resp, str_save, 'Sheet', 1)



%% Manual analysis (constantly changing)
%  ------------------------------------------------------------------------
t_out.Responses.(char(erase(filesOI, ' '))) = out_resp;
t_out.ReactionT.(char(erase(filesOI, ' '))) = out_reac;


MemLearn = table2array(t_out.Responses.MemoryLernen);
MemAbfra = table2array(t_out.Responses.MemoryAbfrage);

if any(size(MemLearn) ~= size(MemAbfra))
    error('Mismatch in tables')
else
    MemGain = cell(size(MemAbfra));
end

% ---------------------------------- /!\ ----------------------------------
% We seem to have a problem in numbers of card pairs learned: 17 card paris
% vs only (correctly) 15 pairs asked during recall
% - seehund1 (column 17)
% - eisbaer2 (column 28)
are_empty = cellfun(@isempty, MemLearn, 'UniformOutput', false);
for iRow = 1:size(are_empty, 1)
    cards_played(iRow) = size(are_empty, 2) - sum([are_empty{iRow, :}]);
end

% The problem has been solved by taking into account only card pairs coming
% after the last "Recalllist:1" line. The two card pairs were dummy
% questions in order to show the participant how the game works.
% -------------------------------------------------------------------------


% In the arrays, 1 singifies the card has been correctly located, 0 that it
% has not. Here, we will defines as:
% - Missmiss cards that have not been correctly located either before sleep
%   (Lernen) nor after sleep (Abfrage)
% - Hithit cards that have been correctly located during Lernen and Abfrage
% - Gain cards that have not been located during Lernen but after sleep
%   during Abfrage
% - Loss cards that had been located before sleep during Lernen but not
%   afterwards during Abfrage

idx_CueD = find(contains(...
    t_out.Responses.MemoryLernen.Properties.RowNames, 'CueD'));
idx_CueM = find(contains(...
    t_out.Responses.MemoryLernen.Properties.RowNames, 'CueM'));

for iSubj = 1:size(MemLearn, 1)
        
        subjLearn = MemLearn(iSubj, :);
        subjAbfra = MemAbfra(iSubj, :);
        
        for iCard = 1:numel(subjLearn)
           
            if ( isempty(subjLearn{iCard}) && ...
                    ~isempty(subjAbfra{iCard}) ) || ...
                    ( ~isempty(subjLearn{iCard}) && ...
                    isempty(subjAbfra{iCard}) )
                error('Card pair is different between Lernen and Abfrage')
            end
            
            if isempty(subjAbfra{iCard})
                continue
            else
                
                if subjLearn{iCard} == 0 && subjAbfra{iCard} == 0
                    MemGain(iSubj, iCard) = {'Missmiss'};
                elseif subjLearn{iCard} == 1 && subjAbfra{iCard} == 1
                    MemGain(iSubj, iCard) = {'Hithit'};
                elseif subjLearn{iCard} == 0 && subjAbfra{iCard} == 1
                    MemGain(iSubj, iCard) = {'Gain'};
                elseif subjLearn{iCard} == 1 && subjAbfra{iCard} == 0
                    MemGain(iSubj, iCard) = {'Loss'};
                end
                
            end
            
        end
end
are_empty = cellfun(@isempty, MemGain, 'UniformOutput', false);
for iRow = 1:size(are_empty, 1)
    cards_played(iRow) = size(are_empty, 2) - sum([are_empty{iRow, :}]);
end


% Extract percentage of gains, losses, ...
% -------------------------------------------------------------------------

iD = 0;
iM = 0;
for iSubj = 1:size(MemGain, 1)
    
    if ismember(iSubj, idx_CueD)
        iD = iD + 1;
        
        Cards.CueD(iD).Hithit = ...
            sum(strcmp(MemGain(iSubj, :), 'Hithit')) / ...
            15;
        Cards.CueD(iD).Missmiss = ...
            sum(strcmp(MemGain(iSubj, :), 'Missmiss')) / ...
            15;
        Cards.CueD(iD).Gain = ...
            sum(strcmp(MemGain(iSubj, :), 'Gain')) / ...
            15;
        Cards.CueD(iD).Loss = ...
            sum(strcmp(MemGain(iSubj, :), 'Loss')) / ...
            15;
        
    elseif ismember(iSubj, idx_CueM)
        iM = iM + 1;
        
        Cards.CueM(iM).Hithit = ...
            sum(strcmp(MemGain(iSubj, :), 'Hithit')) / ...
            15;
        Cards.CueM(iM).Missmiss = ...
            sum(strcmp(MemGain(iSubj, :), 'Missmiss')) / ...
            15;
        Cards.CueM(iM).Gain = ...
            sum(strcmp(MemGain(iSubj, :), 'Gain')) / ...
            15;
        Cards.CueM(iM).Loss = ...
            sum(strcmp(MemGain(iSubj, :), 'Loss')) / ...
            15;
        
    end
    
end

