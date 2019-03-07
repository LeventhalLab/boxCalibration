% script to check if calibration points are appropriately triangulated

allParams = setParams;

% cd(calImageDir);

colList = 'rgb';
matList = dir('SR_boxCalibration_*.mat');
P = eye(4,3);
% close all

for iMat = 1 : length(matList)
    
    load(matList(iMat).name);
    K = cameraParams.IntrinsicMatrix;
    
    numBoards = size(directChecks,3);
    numImg = size(directChecks,4);
    
    close all
    for iImg = 1 : numImg
        img = imread(imFileList{iImg},'png');
        img = undistortImage(img,cameraParams);
        figure(iImg + numImg);
        imshow(img);
        hold on
    end
    
    points3d = NaN(size(directChecks,1),3,size(directChecks,3),size(directChecks,4));
    scaled_points3d = NaN(size(points3d));
    mean_sf = mean(scaleFactor,2);   % single scale factor for each board, averaged across images
    
    for iBoard = 1 : numBoards
        
        for iImg = 1 : numImg
            
            curDirectChecks = squeeze(directChecks(:,:,iBoard,iImg));
            curMirrorChecks = squeeze(mirrorChecks(:,:,iBoard,iImg));
            
            figure(iImg + numImg)
            scatter(curDirectChecks(1,1),curDirectChecks(1,2));
            scatter(curMirrorChecks(1,1),curMirrorChecks(1,2));
            
            if any(isnan(curDirectChecks(:))) || any(isnan(curMirrorChecks(:)))
                continue;
            end
            
            curDirectChecks_norm = normalize_points(curDirectChecks,K);
            curMirrorChecks_norm = normalize_points(curMirrorChecks,K);
            
            curP = squeeze(Pn(:,:,iBoard));
            [points3d(:,:,iBoard,iImg),reprojectedPoints,errors] = triangulate_DL(curDirectChecks_norm, curMirrorChecks_norm, P, curP);
            scaled_points3d(:,:,iBoard,iImg) = points3d(:,:,iBoard,iImg) * mean_sf(iBoard);
            
            h_fig(iImg) = figure(iImg);
            set(h_fig(iImg),'position',[100+(iImg-1)*450,100,400,400])
            hold on
            toPlot = squeeze(scaled_points3d(:,:,iBoard,iImg));
            scatter3(toPlot(:,1),toPlot(:,2),toPlot(:,3),colList(iBoard))
            scatter3(toPlot(1,1),toPlot(1,2),toPlot(1,3))
            
            xlabel('x')
            ylabel('y')
            zlabel('z')
            set(gca,'zdir','reverse','ydir','reverse')
            figName = sprintf('%s, image %d',matList(iMat).name,iImg);
            set(gcf,'name',figName)
            view(15,45)
        end
    end
    keyboard
    close all
end