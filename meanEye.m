function avgEye = meanEye(imgEyes)

% *************************************************************************
% SUMMARY   : Function to compute the mean eye of a given set of input 
%             eyes
%
% USAGE     : avgEye = meanEye(imgEyes)
%
% ARGUMENTS :
%
% imgTest   - All the Eyes in the database.
% 
% OUTPUTS   :
%
% avgEye   - Avg. eye obtained by the use of eyes from the entire
%             database
% 
% *************************************************************************

sumEyes   = zeros(size(imgEyes(1).img));
cntEyes   = 0;

for fIt = 1:size(imgEyes,2)
    sumEyes  = sumEyes + double(imgEyes(fIt).img);
    cntEyes  = cntEyes + 1;
end

avgEye = uint8(sumEyes./cntEyes);
