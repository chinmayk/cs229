function [ score ] = opt_function( predicted, expected, option )
%UNTITLED2 Summary of this function goes here
%  option-0: accuracy
%  option-1: a_precision
%  option-2: lnorm
%  option-3: rms
%  option-4: l2norm
result = 0;

if (option == 0)
    result = 1-sum(predicted==expected)/max(size(expected));
end
if (option == 1)
    result = 1-sum((predicted==expected).*(predicted>0))/sum(predicted>0);
end
if (option==2)
    result = mean(abs(predicted-expected));
end
if (option==3)
    result = sqrt(mean((predicted-expected).*(predicted-expected)));
end
if (option==4)
    result = sum((predicted-expected).*(predicted-expected));
end
if (option==5)
    %recall
    result = sum((predicted==expected).*(predicted>0))/sum(expected>0);
end
score = result;
end

