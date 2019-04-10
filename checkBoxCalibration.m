% checkBoxCalibration
%
% Checks if calibration points are appropriately triangulated.
%
% "Instructions for Use" Step 6
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

allParams = setParams;

colList = 'rgb';
boxCalDir = [allParams.calImageDir '/boxCalibration/'];
matList = dir([boxCalDir 'boxCalibration_*.mat']);
P = eye(4,3);

% Prompts to determine which videos to analyze
validResponse = 0;
while ~validResponse
    allDates = input('Do you want to analyze all dates? Y/N [Y]: ', 's');
    if strcmp(allDates,'Y') || isempty(allDates)
        validResponse = 1;
        oldMatList=matList;
        matList={};
        for iMat=1:length(oldMatList)
            matList{iMat}=oldMatList(iMat).name;
        end
    elseif strcmp(allDates,'N')
        validResponse = 1;
        wantDates = input('Enter the dates you want to analyze: ','s');
        if contains(wantDates,', ')
            splitDates = split(wantDates, ', ');
        else
            splitDates = split(wantDates, ',');
        end
        oldMatList=matList;
        matList={};
        for iMat=1:length(oldMatList)
             for iDate=1:length(splitDates)
                 if contains(oldMatList(iMat).name,splitDates(iDate))
                     matList{iDate}=oldMatList(iMat).name;
                 end
             end
        end
    else
        fprintf('\nPlease enter a valid response: Y for yes or N for no. Default is Yes.\n\n');    
    end
end

for iMat = 1 : length(matList)
    
    splitName=split(matList{iMat},{'_','.'});
    date=splitName{2};
    
    plotDir = [allParams.calImageDir 'plots/'];
    if ~exist(plotDir, 'dir')
        mkdir(plotDir);
    end

    plotDateDir = [allParams.calImageDir 'plots/' date '/'];
    if ~exist(plotDateDir, 'dir')
        mkdir(plotDateDir);
    end
    
    load([boxCalDir matList{iMat}]);
    K = cameraParams.IntrinsicMatrix;
    
    numBoards = size(directChecks,3);
    numImg = size(directChecks,4);
    
    close all
    % Plots all images (point confirmation plots). These plots will be used
    % to confirm that the circled point in the mirror view is the same as
    % the circled point in the direct view for all boards.
    for iImg = 1 : numImg
        figNum=num2str(iImg);
        img = imread([allParams.calImageDir imFileList{iImg}],'png');
        img = undistortImage(img,cameraParams);
        f=figure('visible','off');
        imshow(img);
        saveas(f,[plotDateDir 'pointConfirm_' date '_' figNum],'fig');
        close(f);
    end
    
    points3d = NaN(size(directChecks,1),3,size(directChecks,3),size(directChecks,4));
    scaled_points3d = NaN(size(points3d));
    mean_sf = mean(scaleFactor,2);   % single scale factor for each board, averaged across images
    
    for iBoard = 1 : numBoards
        
        for iImg = 1 : numImg
            
            figNum=num2str(iImg);
            curDirectChecks = squeeze(directChecks(:,:,iBoard,iImg));
            curMirrorChecks = squeeze(mirrorChecks(:,:,iBoard,iImg));
            
            % Plots points for the point confirmation plots.
            f=openfig([plotDateDir 'pointConfirm_' date '_' figNum],'invisible');
            hold all;
            scatter(curDirectChecks(1,1),curDirectChecks(1,2),'filled');
            scatter(curMirrorChecks(1,1),curMirrorChecks(1,2),'filled');
            saveas(f,[plotDateDir 'pointConfirm_' date '_' figNum],'fig');
            saveas(f,[plotDateDir 'pointConfirm_' date '_' figNum],'png');
            close(f);
            
            
            if any(isnan(curDirectChecks(:))) || any(isnan(curMirrorChecks(:)))
                continue;
            end
            
            curDirectChecks_norm = normalize_points(curDirectChecks,K);
            curMirrorChecks_norm = normalize_points(curMirrorChecks,K);
            
            curP = squeeze(Pn(:,:,iBoard));
            [points3d(:,:,iBoard,iImg),reprojectedPoints,errors] = triangulate_DL(curDirectChecks_norm, curMirrorChecks_norm, P, curP);
            scaled_points3d(:,:,iBoard,iImg) = points3d(:,:,iBoard,iImg) * mean_sf(iBoard);
            
            % Create figures for verifying configuration of calibration
            % cube
            if iBoard==1
                h_fig = figure('visible','off');
            else
                h_fig = openfig([plotDateDir 'calibConfirm_' date '_' figNum],'invisible');
            end
            
            hold all
            toPlot = squeeze(scaled_points3d(:,:,iBoard,iImg));
            scatter3(toPlot(:,1),toPlot(:,2),toPlot(:,3),colList(iBoard))
            scatter3(toPlot(1,1),toPlot(1,2),toPlot(1,3))
            
            xlabel('x')
            ylabel('y')
            zlabel('z')
            set(gca,'zdir','reverse','ydir','reverse')
            title(['boxCalibration ' date ', image ' figNum]);
            view(15,45)
            
            saveas(h_fig,[plotDateDir 'calibConfirm_' date '_' figNum],'fig');
            saveas(h_fig,[plotDateDir 'calibConfirm_' date '_' figNum],'png');
            close(h_fig);
            
        end
    end
end