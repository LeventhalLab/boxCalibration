% calibrateBoxes 
%
% Generates parameters for 3D reconstruction. All necessary variables are
% defined in the 'setParams' function. 
%
% "Instructions for Use" Step 5
%
% Instructions for Use:
%   1. Collect all calibration images in the same folder.
%   2. Using ImageJ, manually mark all checkerboard points for each 
%       calibration image. Save this image with the name 
%       “GridCalibration_YYYYMMDD_#.tif” where ‘YYYYMMDD’ is the date the 
%       calibration image corresponds to and ‘#’ is the image number for 
%       that date.
%   3. Use the measurement function in ImageJ (in the toolbar, select 
%       “Analyze” and then “Measure”). This will display a table containing 
%       coordinates for all points marked. Save this file with the name 
%       “GridCalibration_YYYYMMDD_#.csv”, where the date and image number 
%       are the same as the corresponding .tif file. 
%   4. From the boxCalibration MATLAB package, open the ‘setParams.m’ file. 
%       This file contains all required variables and their description. 
%       Edit variables as needed to fit your project’s specifications. 
%   5. In MATLAB, run the ‘calibrateBoxes’ script. Several prompts which 
%       require responses will appear in the MATLAB command window. 
%       The first prompt asks if you want to analyze all images in your folder. 
%       a. Typing ‘Y’ will end the prompts and all images for all dates 
%           will be analyzed. 
%       b. Typing ‘N’ will then prompt you to enter the dates that you want 
%           to analyze. These dates should be of the form YYYYMMDD. 
%           If multiple dates will be analyzed, separate each date with a 
%           comma (e.g., 20190101, 20190102). Note: If the same date is 
%           analyzed twice, all files will be overwritten. 
%       c. Two new directories will be created in your calibration images 
%           folder following the execution of this script: ‘markedImages’ 
%           contains .png files with the user defined checkerboard marks on 
%           the calibration image. The ‘boxCalibration’ folder contains the 
%           .mat box calibration parameters for each date.
%   6. In MATLAB, run the ‘checkBoxCalibration’ script. The same prompts 
%       present in the ‘calibrateBoxes’ script will appear. This will create 
%       a new folder, ‘plots’ in the calibration images folder. Each date 
%       will have a subfolder containing the images and several MATLAB .fig 
%       files, which should be viewed in order to verify that box calibration 
%       was completed accurately. Note: Differently colored dots in the 
%       calibConfirm_YYYYMMDD_#.png files represent the matched dots in the 
%       pointConfirm_YYYYMMDD_#.png files.
%

% boxCalibration package for MatLab
%
% By Daniel K Leventhal, 2019
% dleventh@med.umich.edu
% https://github.com/orgs/LeventhalLab/boxCalibration

% Extract and define necessary variables from setParams function
allParams=setParams;
load(allParams.camParamFile);
K = cameraParams.IntrinsicMatrix;

points_per_board = prod(allParams.boardSize-1);

numBoards = size(allParams.ROIs,1) - 1;

P = eye(4,3);

% Create output directories
markedDir = [allParams.calImageDir 'markedImages/'];
boxCalDir = [allParams.calImageDir 'boxCalibration/'];

if ~exist(markedDir, 'dir')
    mkdir(markedDir);
else
    fprintf('Marked image directory already exists!\nLocation: %s\n', markedDir);
end

if ~exist(boxCalDir, 'dir')
    mkdir(boxCalDir);
else
    fprintf('Box calibration directory already exists!\nLocation: %s\n', boxCalDir);
end

% Get a list of all calibration images and all .csv files (saved from
% ImageJ, containing all marked checkerboard points)
[imFiles_from_same_date, img_dateList] = groupByDate(allParams.imgList);
[csvFiles_from_same_date, csv_dateList] = groupByDate(allParams.csvList);

% Prompts to determine which videos to analyze
validResponse = 0;
while ~validResponse
    allDates = input('Do you want to analyze all dates? Y/N [Y]: ', 's');
    if strcmp(allDates,'Y') || isempty(allDates)
        validResponse = 1;
        numDates = length(csv_dateList);
    elseif strcmp(allDates,'N')
        validResponse = 1;
        wantDates = input('Enter the dates you want to analyze: ','s');
        if contains(wantDates,', ')
            splitDates = split(wantDates, ', ');
        else
            splitDates = split(wantDates, ',');
        end
        numDates=length(splitDates);
    else
        fprintf('\nPlease enter a valid response: Y for yes or N for no. Default is Yes.\n\n');    
    end
end

% Begin processing for selected dates
for iDate = 1 : numDates

    % Adjust variables for selected dates
    if strcmp(allDates,'Y') || isempty(allDates)
        curDate = csv_dateList{iDate};
    else
        curDate = splitDates{iDate};
    end

    fprintf('working on %s\n',curDate);

    % Begin processing for curDate

    for csvFiles_all=1:length(csvFiles_from_same_date)
        logical=contains(csvFiles_from_same_date{csvFiles_all},curDate);
        if logical(1)==1
            csv_date_idx=csvFiles_all;
            num_csvPerDate = length(csvFiles_from_same_date{csvFiles_all});
        end
    end

    % Find this date in the img_dateList
    img_date_idx = find(strcmp(img_dateList, curDate));

    numImgPerDate = length(imFiles_from_same_date{img_date_idx});
    img = cell(1, numImgPerDate);

    csvData = cell(1,num_csvPerDate);
    csvNumList = zeros(1,num_csvPerDate);

    % Read in csv data and undistort the points
    for i_csv = 1 : num_csvPerDate
        cur_csvName = csvFiles_from_same_date{csv_date_idx}{i_csv};
        C = textscan(cur_csvName,['GridCalibration_' curDate '_%d.csv']);
        csvNumList(i_csv) = C{1};
        csvData{i_csv} = readFIJI_csv([allParams.calImageDir cur_csvName]);
        % Undistort points in csv file
        csvData{i_csv}=undistortPoints(csvData{i_csv},cameraParams); 
    end

    % Load marked images (i.e., has .csv file)
    imgNumList = zeros(1,numImgPerDate);
    numImgLoaded = 0;
    if exist('img','var')
        clear img
    end
    for iImg = 1 : numImgPerDate
        curImgName = imFiles_from_same_date{img_date_idx}{iImg};
        C = textscan(curImgName,['GridCalibration_' curDate '_%d.png']);
        imageNumber = C{1};
        if any(csvNumList == imageNumber)
            % load this image
            numImgLoaded = numImgLoaded + 1;
            img{numImgLoaded} = imread([allParams.calImageDir curImgName]);
            imgNumList(numImgLoaded) = imageNumber;
        end
    end

    % Create boarder masks
    [directBorderMask, ~] = findDirectBorders(img, allParams.direct_hsvThresh, allParams.ROIs, ...
            'diffthresh', allParams.diffThresh, 'threshstepsize', allParams.threshStepSize, 'maxthresh', allParams.maxThresh, ...
            'maxdistfrommainblob', allParams.maxDistFromMainBlob, 'mincheckerboardarea', allParams.minDirectCheckerboardArea, ...
            'maxcheckerboardarea', allParams.maxDirectCheckerboardArea, 'sesize', allParams.SEsize, 'minsolidity', allParams.minSolidity);
    [mirrorBorderMask, ~] = findMirrorBorders(img, allParams.mirror_hsvThresh, allParams.ROIs, ...
            'diffthresh', allParams.diffThresh, 'threshstepsize', allParams.threshStepSize, 'maxthresh', allParams.maxThresh, ...
            'maxdistfrommainblob', allParams.maxDistFromMainBlob, 'mincheckerboardarea', allParams.minMirrorCheckerboardArea, ...
            'maxcheckerboardarea', allParams.maxMirrorCheckerboardArea, 'sesize', allParams.SEsize, 'minsolidity', allParams.minSolidity);

    % Undistort boarder masks
    for ii = 1 : length(directBorderMask)
        for jj = 1 : size(directBorderMask{ii},3)
            directBorderMask{ii}(:,:,jj) = undistortImage(squeeze(directBorderMask{ii}(:,:,jj)), cameraParams);
        end
    end
    for ii = 1 : length(mirrorBorderMask)
        for jj = 1 : size(mirrorBorderMask{ii},3)
            mirrorBorderMask{ii}(:,:,jj) = undistortImage(squeeze(mirrorBorderMask{ii}(:,:,jj)), cameraParams);
        end
    end

    % Create arrays to hold the marked checkerboard points
    directChecks = NaN(prod(allParams.boardSize-1),2,size(directBorderMask{1},3),numImgPerDate);
    mirrorChecks = NaN(prod(allParams.boardSize-1),2,size(mirrorBorderMask{1},3),numImgPerDate);

    % Assign points in csv to checkerboards
    for i_csv = 1 : num_csvPerDate

        % figure out what image index to use
        img_idx = find(imgNumList == csvNumList(i_csv));

        % fill out the directChecks and mirrorChecks arrays. Assume that
        % the image number is the correct index to use.

        [new_directChecks, new_mirrorChecks] = assign_csv_points_to_checkerboards(directBorderMask{img_idx}, ...
                                                mirrorBorderMask{img_idx}, ...
                                                allParams.ROIs, csvData{i_csv}, ...
                                                allParams.boardSize, ...
                                                allParams.mirrorOrientation);

        % update directChecks and mirrorChecks arrays
        for iBoard = 1 : size(new_directChecks,3)
            testPoints = squeeze(new_directChecks(:,:,iBoard));
            if ~all(isnan(testPoints(:)))
                % marked points were found for this board
                directChecks(:,:,iBoard,imgNumList(img_idx)) = testPoints;
            end

            testPoints = squeeze(new_mirrorChecks(:,:,iBoard));
            if ~all(isnan(testPoints(:)))
                % marked points were found for this board
                mirrorChecks(:,:,iBoard,imgNumList(img_idx)) = testPoints;
            end

        end

    end

    % Identify matching points for direct and mirror views
    allMatchedPoints = NaN(points_per_board * numImgPerDate, 2, 2, numBoards);
    for iImg = 1 : numImgPerDate
        for iBoard = 1 : numBoards
            curDirectChecks = squeeze(directChecks(:,:,iBoard,iImg));
            curMirrorChecks = squeeze(mirrorChecks(:,:,iBoard,iImg));

            if all(isnan(curDirectChecks(:))) || all(isnan(curMirrorChecks(:)))
                % don't have matching points for the direct and mirror view
                continue;
            end

            matchIdx = matchCheckerboardPoints(curDirectChecks, curMirrorChecks);

            matchStartIdx = (iImg-1) * points_per_board + 1;
            matchEndIdx = (iImg) * points_per_board;

            allMatchedPoints(matchStartIdx:matchEndIdx,:,1,iBoard) = curDirectChecks(matchIdx(:,1),:);
            allMatchedPoints(matchStartIdx:matchEndIdx,:,2,iBoard) = curMirrorChecks(matchIdx(:,2),:);

            directChecks(:,:,iBoard,iImg) = curDirectChecks(matchIdx(:,1),:);
            mirrorChecks(:,:,iBoard,iImg) = curMirrorChecks(matchIdx(:,2),:);


        end
    end

    imFileList = imFiles_from_same_date{img_date_idx};

    % Save marked images
    if allParams.saveMarkedImages
        for iImg = 1 : numImgPerDate

            % was there a previously marked image?
            curImgName = imFiles_from_same_date{img_date_idx}{iImg};
            oldImg = imread([allParams.calImageDir curImgName],'png');
            newImg = undistortImage(oldImg,cameraParams);

            for iBoard = 1 : numBoards

                curChecks = squeeze(directChecks(:,:,iBoard,iImg));
                for i_pt = 1 : size(curChecks,1)
                    if isnan(curChecks(i_pt,1)); continue; end
                    newImg = insertShape(newImg,'FilledCircle',...
                        [curChecks(i_pt,1),curChecks(i_pt,2),allParams.markRadius],...
                        'color',allParams.colorList{iBoard},'opacity',allParams.markOpacity);
                end

                curChecks = squeeze(mirrorChecks(:,:,iBoard,iImg));
                for i_pt = 1 : size(curChecks,1)
                    if isnan(curChecks(i_pt,1)); continue; end
                    newImg = insertShape(newImg,'FilledCircle',...
                        [curChecks(i_pt,1),curChecks(i_pt,2),allParams.markRadius],...
                        'color',allParams.colorList{iBoard},'opacity',allParams.markOpacity);
                end

            end

            newImgName = strrep(curImgName,'.png','_marked.png');
            imwrite(newImg,[markedDir newImgName],'png');

        end       
    end

    num_img = size(directChecks, 4);
    F = NaN(3,3,numBoards);
    E = NaN(3,3,numBoards);
    Pn = NaN(4,3,numBoards);
    scaleFactor = NaN(numBoards, num_img);

    % Create reconstruction variables for date
    for iBoard = 1 : size(allMatchedPoints, 4)
        mp_direct = squeeze(allMatchedPoints(:,:,1,iBoard));
        mp_mirror = squeeze(allMatchedPoints(:,:,2,iBoard));
        valid_mp_direct = mp_direct(~isnan(mp_direct));
        valid_mp_direct = reshape(valid_mp_direct,size(valid_mp_direct,1)/2,2);
        valid_mp_mirror = mp_mirror(~isnan(mp_mirror));
        valid_mp_mirror = reshape(valid_mp_mirror,size(valid_mp_mirror,1)/2,2);
        if isempty(valid_mp_direct) || isempty(valid_mp_mirror)
            % either didn't have marks for these images or the marks
            % weren't assigned to the correct boards/images
            fprintf('no matched points on board %d\n',iBoard);
            continue;
        end
        if size(valid_mp_direct,1) ~= size(valid_mp_mirror,1)
            fprintf('direct and mirror point arrays do not match for board %d\n',iBoard);
        end
        F(:,:,iBoard) = fundMatrix_mirror(valid_mp_direct, valid_mp_mirror);

        E(:,:,iBoard) = K * squeeze(F(:,:,iBoard)) * K';

        cur_E = squeeze(E(:,:,iBoard));
        [rot,t] = EssentialMatrixToCameraMatrix(cur_E);
        [cRot,cT,~] = SelectCorrectEssentialCameraMatrix_mirror(...
            rot,t,valid_mp_mirror',valid_mp_direct',K');
        Ptemp = [cRot,cT];
        Pn(:,:,iBoard) = Ptemp';

        % normalize matched points by K in preparation for calculating
        % world points
        for iImg = 1 : num_img
            mp_direct = squeeze(directChecks(:,:,iBoard,iImg));
            mp_mirror = squeeze(mirrorChecks(:,:,iBoard,iImg));

            if all(isnan(mp_direct(:))) || all(isnan(mp_mirror(:)))
                % either didn't have marks for these images or the marks
                % weren't assigned to the correct boards/images
                try
                fprintf('no matched points on board %d, image %s\n',iBoard,imFileList{iImg});
                catch
                    keyboard
                end
                continue;
            end

            direct_hom = [mp_direct, ones(size(mp_direct,1),1)];
            direct_norm = (K' \ direct_hom')';
            direct_norm = bsxfun(@rdivide,direct_norm(:,1:2),direct_norm(:,3));

            mirror_hom = [mp_mirror, ones(size(mp_mirror,1),1)];
            mirror_norm = (K' \ mirror_hom')';
            mirror_norm = bsxfun(@rdivide,mirror_norm(:,1:2),mirror_norm(:,3));

            cur_P = squeeze(Pn(:,:,iBoard));
            [wpts, ~]  = triangulate_DL(direct_norm, mirror_norm, P, cur_P);
            gs = calcGridSpacing(wpts,allParams.boardSize-1);
            scaleFactor(iBoard,iImg) = allParams.cb_spacing / mean(gs);

            all_wpts{iImg,iBoard}=wpts;
        end

    end

    % Plot world points figures (scatter plots)
    if allParams.makeWorldPts_fig

        plotDir = [allParams.calImageDir 'plots/'];
        if ~exist(plotDir, 'dir')
            mkdir(plotDir);
        end

        plotDateDir = [allParams.calImageDir 'plots/' curDate '/'];
        if ~exist(plotDateDir, 'dir')
            mkdir(plotDateDir);
        end

        for iImg=1:numImgPerDate
            if iImg ~= 1
                close(f);
            end
            figNum=num2str(iImg);
            f = figure('visible','off');
            hold on
            scatter3(all_wpts{iImg,1}(:,1),all_wpts{iImg,1}(:,2),all_wpts{iImg,1}(:,3));
            scatter3(all_wpts{iImg,2}(:,1),all_wpts{iImg,2}(:,2),all_wpts{iImg,2}(:,3));
            scatter3(all_wpts{iImg,3}(:,1),all_wpts{iImg,3}(:,2),all_wpts{iImg,3}(:,3));
            saveas(f,[plotDateDir 'WorldPts_' curDate '_' figNum],'fig');
            saveas(f,[plotDateDir 'WorldPts_' curDate '_' figNum],'png');
        end
    end

    % write box calibration information to disk
    calibrationFileName = [boxCalDir 'boxCalibration_' curDate '.mat'];
    save(calibrationFileName,'P','Pn','F','E','scaleFactor','directChecks','mirrorChecks','allMatchedPoints','cameraParams','curDate','imFileList');

end