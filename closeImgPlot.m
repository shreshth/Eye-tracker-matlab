function closeImgPlot(noCols, plotNo, plotImg)

% *************************************************************************
% SUMMARY   : Function to display images in a subplot with tight spacing
%
% USAGE     : closeImgPlot(noCols, plotNo, plotImg)
%
% ARGUMENTS :
% 
% noCols    - Number of columns to be used in the subplot
% plotNo    - The number of the plot used in the subplot
% plotImg   - The image data to be plotted
%
% *************************************************************************

rowNo = mod(plotNo-1,noCols);      % Number of rows in subplot
colNo = floor((plotNo-1)/noCols);  % Number of columns in subplot

subplot('position',[rowNo*(1/noCols),(noCols-colNo-1)*...
                    (1/noCols),1/noCols-.001,1/noCols-0.001]); 

imagesc(plotImg);
axis off; 
