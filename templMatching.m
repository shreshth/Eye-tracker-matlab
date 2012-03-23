function [corrScore, boundBox] = templMatching(vidFrame, eyeTemplate, corrThresh)

% *************************************************************************
% This file takes an input image, a template and a threshold (optional) for 
% the correlation coefficient (which ranges between 0 and 1). It outputs 
% the correlation score and the boundingBox corresponding to the location 
% of the maximum correlation
% *************************************************************************

% -------------------------------------------------------------------------
% Initialization phase
% -------------------------------------------------------------------------

if size(vidFrame,3) ~=1, grayFrame = rgb2gray(vidFrame);
else grayFrame = vidFrame; end

grayFrame = double(grayFrame);

if size(eyeTemplate,3) ~=1, grayTemplate = rgb2gray(eyeTemplate);
else grayTemplate = eyeTemplate; end

grayTemplate = double(grayTemplate);

[heightTemplate,widthTemplate] = size(grayTemplate);

% -------------------------------------------------------------------------
% Compute the correlation coefficient
% -------------------------------------------------------------------------

meanFrame    = conv2(grayFrame,ones(size(grayTemplate))./numel(grayTemplate),'same');
meanTemplate = mean(grayTemplate(:));

corrPartI    = conv2(grayFrame,rot90((grayTemplate-meanTemplate),2),'same')./numel(grayTemplate);
corrPartII   = meanFrame.*sum(grayTemplate(:)-meanTemplate);
stdFrame     = sqrt(conv2(grayFrame.^2,ones(size(grayTemplate))./numel(grayTemplate),'same')-meanFrame.^2);
stdTemplate  = std(grayTemplate(:));

corrScore    = (corrPartI-corrPartII)./(stdFrame.*stdTemplate);     % Score

% -------------------------------------------------------------------------
% Find the most likely region
% -------------------------------------------------------------------------

[maxVal,maxIdx] = max(corrScore(:));
[maxR, maxC]    = ind2sub([size(corrScore,1),size(corrScore,2)],maxIdx);

% -------------------------------------------------------------------------
% Thresholding
% -------------------------------------------------------------------------

if ~exist('corrThresh','var'), corrThresh = 0.75; end % If unspecified threshold

if (maxVal >= corrThresh)
    boundBox(1,:) = [max(1,maxC-round(widthTemplate/2)), max(1,maxR-round(heightTemplate/2)),...
                     widthTemplate,heightTemplate];
else
    boundBox      = [];
end