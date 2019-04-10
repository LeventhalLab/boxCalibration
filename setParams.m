function allParams = setParams
%setParams Used to set parameters for project.
%
% "Instructions for Use" Step 4
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

    % Calibration images directory (images should be .png): 
    allParams.calImageDir = '~/Desktop/';
    % Camera parameters file directory (should be .mat file):
    allParams.camParamFile = '~/Desktop/';

    % Plotting Parameters:
    allParams.saveMarkedImages = true;
    allParams.markRadius = 5;
    allParams.colorList = {'red','green','blue'};
    allParams.markOpacity = 1;

    % Plot Creation:
    allParams.makeWorldPts_fig = true;
    
    % Parameters for detecting borders around checkerboards:
    allParams.threshStepSize = 0.01;
    allParams.diffThresh = 0.1;
    allParams.maxThresh = 0.2;

    allParams.minDirectCheckerboardArea = 5000;
    allParams.maxDirectCheckerboardArea = 25000;

    allParams.minMirrorCheckerboardArea = 5000;
    allParams.maxMirrorCheckerboardArea = 20000;

    allParams.maxDistFromMainBlob = 200;  
    allParams.minSolidity = 0.8;
    allParams.SEsize = 3;

    % Size of the checkerboard
    allParams.boardSize = [4 5];
    allParams.cb_spacing = 4; % Real world grid spacing, in mm

    % Regions of interest containing the checkerboards
    allParams.ROIs = [700,270,650,705;
            750,1,600,325;
            1,400,350,500;
            1700,400,340,500];

    % Orientation of mirrors
    allParams.mirrorOrientation = {'top','left','right'};
    
    % Color thresholds for checkerboards (HSV)
    allParams.direct_hsvThresh = [0,0.1,0.9,1,0.9,1; % red
                        0.33,0.1,0.9,1,0.9,1; % green
                        0.66,0.1,0.9,1,0.9,1]; % blue

    allParams.mirror_hsvThresh = [0,0.1,0.85,1,0.85,1; % red
                        0.30,0.05,0.85,1,0.85,1; % green
                        0.60,0.1,0.85,1,0.85,1]; % blue

    % List of images and csvs in directory; this should not need to be changed
    allParams.imgList = dir([allParams.calImageDir 'GridCalibration_*.png']);
    allParams.csvList = dir([allParams.calImageDir 'GridCalibration_*.csv']);
    
end
